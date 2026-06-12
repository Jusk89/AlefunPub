from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models.activity import UserActivity
from app.models.audit import AuditAction
from app.models.bonus import BonusAccount, BonusTransaction, BonusTransactionType
from app.models.branch import Branch
from app.models.order import Order, OrderStatus, OrderType, PaymentStatus
from app.models.restaurant import Restaurant
from app.models.user import User, UserRole
from app.services.audit import AuditService
from app.services.money import money

EARNABLE_TYPES = (BonusTransactionType.earn, BonusTransactionType.manual)


class QrFlowError(Exception):
    pass


class QrNotFoundError(QrFlowError):
    pass


class QrPermissionError(QrFlowError):
    pass


class QrService:
    """Cashier-facing permanent QR loyalty workflow service."""

    def __init__(self, db: Session) -> None:
        self.db = db

    def lookup_client(self, qr_code: str) -> tuple[User, Decimal]:
        """Find a client by QR code and return their total bonus balance."""
        client = self._get_client_by_qr(qr_code)
        total_balance = self.db.scalar(select(func.coalesce(func.sum(BonusAccount.balance), 0)).where(BonusAccount.user_id == client.id))
        return client, self._money(total_balance)

    def create_order_from_qr(
        self,
        qr_code: str,
        branch_id: int,
        total_amount: Decimal,
        payment_method,
        use_bonuses: bool,
    ) -> tuple[Order, User, BonusAccount]:
        """Create a completed in-restaurant order from a scanned client QR code."""
        total_amount = self._money(total_amount)
        client = self._get_client_by_qr(qr_code)
        branch = self._require_branch(branch_id)
        restaurant = branch.restaurant
        if restaurant is None:
            restaurant = self.db.get(Restaurant, branch.restaurant_id)
        if restaurant is None:
            raise QrNotFoundError("Restaurant not found")

        self._expire_old(client.id, restaurant.id)
        account = self._get_or_create_bonus_account(client.id, restaurant.id)
        available_bonus_balance = self._available_bonus_balance(client.id, restaurant.id)
        account.balance = available_bonus_balance

        bonus_spent = Decimal("0.00")
        bonus_earned = Decimal("0.00")
        final_amount = total_amount

        if use_bonuses:
            # QR spending uses all available bonuses up to the order amount.
            # FIFO is based on credits that expire first, then oldest credits.
            bonus_spent = min(available_bonus_balance, total_amount)
            final_amount = self._money(total_amount - bonus_spent)
        else:
            # QR earning is calculated server-side; clients never send earned points.
            bonus_earned = self._money(total_amount * restaurant.bonus_percent / Decimal("100"))

        order = Order(
            user_id=client.id,
            restaurant_id=restaurant.id,
            branch_id=branch.id,
            order_type=OrderType.in_restaurant,
            status=OrderStatus.completed,
            total_amount=total_amount,
            bonus_earned=bonus_earned,
            bonus_spent=bonus_spent,
            final_amount=final_amount,
            payment_method=payment_method,
            payment_status=PaymentStatus.paid,
        )

        self.db.info["_skip_order_bonus_events"] = True
        self.db.info["_skip_order_activity_events"] = True
        try:
            self.db.add(order)
            self.db.flush()

            if use_bonuses and bonus_spent > 0:
                self._spend_fifo(
                    account=account,
                    user_id=client.id,
                    restaurant_id=restaurant.id,
                    branch_id=branch.id,
                    order_id=order.id,
                    amount=bonus_spent,
                )
                AuditService(self.db).write_log(
                    AuditAction.bonus_spent_from_qr,
                    actor_user_id=client.id,
                    entity_type="order",
                    entity_id=order.id,
                    details={"amount": str(bonus_spent), "restaurant_id": restaurant.id},
                )
            elif not use_bonuses and bonus_earned > 0:
                self._earn_bonus(
                    account=account,
                    user_id=client.id,
                    restaurant=restaurant,
                    branch_id=branch.id,
                    order_id=order.id,
                    amount=bonus_earned,
                )
                AuditService(self.db).write_log(
                    AuditAction.bonus_earned_from_qr,
                    actor_user_id=client.id,
                    entity_type="order",
                    entity_id=order.id,
                    details={"amount": str(bonus_earned), "restaurant_id": restaurant.id},
                )

            self._update_activity(client.id, final_amount)
            AuditService(self.db).write_log(
                AuditAction.order_created_from_qr,
                actor_user_id=client.id,
                entity_type="order",
                entity_id=order.id,
                details={
                    "branch_id": branch.id,
                    "restaurant_id": restaurant.id,
                    "total_amount": str(total_amount),
                    "final_amount": str(final_amount),
                    "use_bonuses": use_bonuses,
                },
            )
            self.db.commit()
        except Exception:
            self.db.rollback()
            raise
        finally:
            self.db.info.pop("_skip_order_bonus_events", None)
            self.db.info.pop("_skip_order_activity_events", None)

        self.db.refresh(order)
        self.db.refresh(account)
        return order, client, account

    def _get_client_by_qr(self, qr_code: str) -> User:
        client = self.db.scalar(
            select(User).where(
                User.qr_code == qr_code,
                User.role == UserRole.client,
            )
        )
        if client is None:
            raise QrNotFoundError("Client not found")
        return client

    def _require_branch(self, branch_id: int) -> Branch:
        branch = self.db.get(Branch, branch_id)
        if branch is None:
            raise QrNotFoundError("Branch not found")
        return branch

    def _get_or_create_bonus_account(self, user_id: int, restaurant_id: int) -> BonusAccount:
        account = self.db.scalar(
            select(BonusAccount).where(
                BonusAccount.user_id == user_id,
                BonusAccount.restaurant_id == restaurant_id,
            )
        )
        if account is not None:
            return account

        account = BonusAccount(
            user_id=user_id,
            restaurant_id=restaurant_id,
            balance=Decimal("0.00"),
            total_earned=Decimal("0.00"),
            total_spent=Decimal("0.00"),
        )
        self.db.add(account)
        self.db.flush()
        return account

    def _available_bonus_balance(self, user_id: int, restaurant_id: int) -> Decimal:
        """Calculate spendable balance from unexpired FIFO credit rows."""
        available = self.db.scalar(
            select(func.coalesce(func.sum(BonusTransaction.remaining_amount), 0)).where(
                BonusTransaction.user_id == user_id,
                BonusTransaction.restaurant_id == restaurant_id,
                BonusTransaction.type.in_(EARNABLE_TYPES),
                BonusTransaction.remaining_amount > 0,
            )
        )
        return self._money(available)

    def _earn_bonus(
        self,
        account: BonusAccount,
        user_id: int,
        restaurant: Restaurant,
        branch_id: int,
        order_id: int,
        amount: Decimal,
    ) -> None:
        """Create a QR earn transaction and update account aggregates."""
        expires_at = None
        if restaurant.bonus_expiration_days > 0:
            expires_at = datetime.now(timezone.utc) + timedelta(days=restaurant.bonus_expiration_days)

        transaction = BonusTransaction(
            user_id=user_id,
            restaurant_id=restaurant.id,
            branch_id=branch_id,
            order_id=order_id,
            type=BonusTransactionType.earn,
            amount=amount,
            remaining_amount=amount,
            expires_at=expires_at,
        )
        self.db.add(transaction)
        account.balance = self._money(account.balance + amount)
        account.total_earned = self._money(account.total_earned + amount)

    def _spend_fifo(
        self,
        account: BonusAccount,
        user_id: int,
        restaurant_id: int,
        branch_id: int,
        order_id: int,
        amount: Decimal,
    ) -> None:
        """Spend QR bonuses from earliest-expiring credits first."""
        remaining_to_spend = amount
        credits = self.db.scalars(
            select(BonusTransaction)
            .where(
                BonusTransaction.user_id == user_id,
                BonusTransaction.restaurant_id == restaurant_id,
                BonusTransaction.type.in_(EARNABLE_TYPES),
                BonusTransaction.remaining_amount > 0,
            )
            .order_by(
                BonusTransaction.expires_at.asc().nulls_last(),
                BonusTransaction.created_at.asc(),
                BonusTransaction.id.asc(),
            )
        ).all()

        for credit in credits:
            if remaining_to_spend <= 0:
                break

            spent_from_credit = min(self._money(credit.remaining_amount), remaining_to_spend)
            credit.remaining_amount = self._money(credit.remaining_amount - spent_from_credit)
            remaining_to_spend = self._money(remaining_to_spend - spent_from_credit)

            self.db.add(
                BonusTransaction(
                    user_id=user_id,
                    restaurant_id=restaurant_id,
                    branch_id=branch_id,
                    order_id=order_id,
                    type=BonusTransactionType.spend,
                    amount=spent_from_credit,
                    remaining_amount=Decimal("0.00"),
                    expires_at=None,
                    source_transaction_id=credit.id,
                )
            )

        account.balance = self._money(account.balance - amount)
        account.total_spent = self._money(account.total_spent + amount)

    def _expire_old(self, user_id: int, restaurant_id: int) -> None:
        """Expire stale credits before calculating QR spendable balance."""
        now = datetime.now(timezone.utc)
        expired_credits = self.db.scalars(
            select(BonusTransaction).where(
                BonusTransaction.user_id == user_id,
                BonusTransaction.restaurant_id == restaurant_id,
                BonusTransaction.type.in_(EARNABLE_TYPES),
                BonusTransaction.remaining_amount > 0,
                BonusTransaction.expires_at.is_not(None),
                BonusTransaction.expires_at <= now,
            )
        ).all()

        if not expired_credits:
            return

        account = self._get_or_create_bonus_account(user_id, restaurant_id)
        for credit in expired_credits:
            amount = self._money(credit.remaining_amount)
            credit.remaining_amount = Decimal("0.00")
            account.balance = self._money(max(Decimal("0.00"), account.balance - amount))
            self.db.add(
                BonusTransaction(
                    user_id=user_id,
                    restaurant_id=restaurant_id,
                    branch_id=credit.branch_id,
                    order_id=credit.order_id,
                    type=BonusTransactionType.expire,
                    amount=amount,
                    remaining_amount=Decimal("0.00"),
                    expires_at=None,
                    source_transaction_id=credit.id,
                )
            )

    def _update_activity(self, user_id: int, final_amount: Decimal) -> None:
        """Update aggregate customer activity after a successful QR order."""
        activity = self.db.scalar(select(UserActivity).where(UserActivity.user_id == user_id))
        if activity is None:
            activity = UserActivity(
                user_id=user_id,
                total_spent=Decimal("0.00"),
                total_orders=0,
            )
            self.db.add(activity)

        activity.last_visit_at = datetime.now(timezone.utc)
        activity.total_orders += 1
        activity.total_spent = self._money(activity.total_spent + final_amount)

    @staticmethod
    def _money(value: Decimal) -> Decimal:
        return money(value)
