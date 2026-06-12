from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import event, inspect, select
from sqlalchemy.orm import Session, Session as SessionBase

from app.models.audit import AuditAction
from app.models.bonus import BonusAccount, BonusTransaction, BonusTransactionType
from app.models.branch import Branch
from app.models.order import Order, OrderStatus
from app.models.restaurant import Restaurant
from app.models.user import User
from app.services.audit import AuditService
from app.services.money import money

CREDIT_TYPES = (BonusTransactionType.earn, BonusTransactionType.manual)
_ORDER_BONUS_EVENTS_REGISTERED = False


def is_completed_status(status: OrderStatus | str) -> bool:
    """Return true when an order status value represents completion."""
    return status == OrderStatus.completed or status == OrderStatus.completed.value


class BonusServiceError(Exception):
    pass


class BonusNotFoundError(BonusServiceError):
    pass


class InsufficientBonusBalanceError(BonusServiceError):
    pass


class BonusValidationError(BonusServiceError):
    pass


class BonusService:
    """Business service for earning, spending, expiring, and auditing bonuses."""

    def __init__(self, db: Session, auto_commit: bool = True) -> None:
        self.db = db
        self.auto_commit = auto_commit

    def get_balance(self, user_id: int, restaurant_id: int) -> BonusAccount:
        """Return the user's restaurant-specific balance after expiring stale credits."""
        self._require_user(user_id)
        self._require_restaurant(restaurant_id)
        self.expire_old(user_id=user_id, restaurant_id=restaurant_id, commit=False)
        account = self._get_or_create_account(user_id, restaurant_id)
        self._finish()
        return account

    def list_history(
        self,
        user_id: int,
        restaurant_id: int | None = None,
        skip: int = 0,
        limit: int = 100,
    ) -> list[BonusTransaction]:
        """Return newest-first bonus transaction history for one user."""
        statement = (
            select(BonusTransaction)
            .where(BonusTransaction.user_id == user_id)
            .order_by(BonusTransaction.created_at.desc(), BonusTransaction.id.desc())
            .offset(skip)
            .limit(limit)
        )
        if restaurant_id is not None:
            statement = statement.where(BonusTransaction.restaurant_id == restaurant_id)
        return list(self.db.scalars(statement).all())

    def spend(
        self,
        user_id: int,
        restaurant_id: int,
        amount: Decimal,
        branch_id: int | None = None,
        order_id: int | None = None,
    ) -> tuple[BonusAccount, list[BonusTransaction]]:
        """Spend a requested amount using the same FIFO ledger used by QR orders."""
        amount = self._money(amount)
        if amount <= 0:
            raise BonusValidationError("Bonus spend amount must be greater than zero")

        self._require_user(user_id)
        self._require_restaurant(restaurant_id)
        if branch_id is not None:
            self._require_branch(branch_id, restaurant_id)
        order = self._get_order_for_spending(order_id, user_id, restaurant_id, branch_id)
        if order is not None and branch_id is None:
            branch_id = order.branch_id

        self.expire_old(user_id=user_id, restaurant_id=restaurant_id, commit=False)
        account = self._get_or_create_account(user_id, restaurant_id)
        if account.balance < amount:
            raise InsufficientBonusBalanceError("Not enough bonuses available")

        if order is not None:
            remaining_order_amount = self._money(order.total_amount - order.bonus_spent)
            if amount > remaining_order_amount:
                raise BonusValidationError("Bonus spend amount exceeds remaining order amount")
            order.bonus_spent = self._money(order.bonus_spent + amount)
            order.final_amount = self._money(order.total_amount - order.bonus_spent)

        transactions = self._consume_fifo_credits(user_id, restaurant_id, amount, branch_id, order_id)
        account.balance = self._money(account.balance - amount)
        account.total_spent = self._money(account.total_spent + amount)
        AuditService(self.db).write_log(
            AuditAction.bonus_spent,
            actor_user_id=user_id,
            entity_type="bonus_transaction",
            entity_id=None,
            details={"restaurant_id": restaurant_id, "amount": str(amount), "order_id": order_id},
        )

        self._finish()
        return account, transactions

    def manual_credit(
        self,
        user_id: int,
        restaurant_id: int,
        amount: Decimal,
        branch_id: int | None = None,
        order_id: int | None = None,
        expires_at: datetime | None = None,
    ) -> BonusTransaction:
        """Credit bonuses manually for staff corrections or promotions."""
        amount = self._money(amount)
        if amount <= 0:
            raise BonusValidationError("Manual bonus amount must be greater than zero")

        self._require_user(user_id)
        restaurant = self._require_restaurant(restaurant_id)
        if branch_id is not None:
            self._require_branch(branch_id, restaurant_id)
        order = self._get_order_for_reference(order_id, user_id, restaurant_id, branch_id)
        if order is not None and branch_id is None:
            branch_id = order.branch_id

        expires_at = expires_at or self._default_expires_at(restaurant)
        account = self._get_or_create_account(user_id, restaurant_id)
        account.balance = self._money(account.balance + amount)
        account.total_earned = self._money(account.total_earned + amount)

        transaction = BonusTransaction(
            user_id=user_id,
            restaurant_id=restaurant_id,
            branch_id=branch_id,
            order_id=order_id,
            type=BonusTransactionType.manual,
            amount=amount,
            remaining_amount=amount,
            expires_at=expires_at,
        )
        self.db.add(transaction)
        AuditService(self.db).write_log(
            AuditAction.bonus_earned,
            actor_user_id=user_id,
            entity_type="bonus_transaction",
            entity_id=None,
            details={"restaurant_id": restaurant_id, "amount": str(amount), "manual": True},
        )
        self._finish()
        return transaction

    def expire_old(
        self,
        user_id: int | None = None,
        restaurant_id: int | None = None,
        commit: bool | None = None,
    ) -> tuple[Decimal, list[BonusTransaction]]:
        """Expire credits that have passed their expiration date."""
        now = datetime.now(timezone.utc)
        statement = select(BonusTransaction).where(
            BonusTransaction.type.in_(CREDIT_TYPES),
            BonusTransaction.remaining_amount > 0,
            BonusTransaction.expires_at.is_not(None),
            BonusTransaction.expires_at <= now,
        )
        if user_id is not None:
            statement = statement.where(BonusTransaction.user_id == user_id)
        if restaurant_id is not None:
            statement = statement.where(BonusTransaction.restaurant_id == restaurant_id)

        expired_amount = Decimal("0.00")
        expire_transactions: list[BonusTransaction] = []

        for source in self.db.scalars(statement).all():
            amount = self._money(source.remaining_amount)
            if amount <= 0:
                continue

            source.remaining_amount = Decimal("0.00")
            account = self._get_or_create_account(source.user_id, source.restaurant_id)
            account.balance = self._money(max(Decimal("0.00"), account.balance - amount))

            expire_transaction = BonusTransaction(
                user_id=source.user_id,
                restaurant_id=source.restaurant_id,
                branch_id=source.branch_id,
                order_id=source.order_id,
                type=BonusTransactionType.expire,
                amount=amount,
                remaining_amount=Decimal("0.00"),
                expires_at=None,
                source_transaction_id=source.id,
            )
            self.db.add(expire_transaction)
            expire_transactions.append(expire_transaction)
            expired_amount = self._money(expired_amount + amount)

        self._finish(commit=commit)
        return expired_amount, expire_transactions

    def award_for_completed_order(
        self,
        order: Order,
        commit: bool | None = None,
    ) -> BonusTransaction | None:
        """Award bonuses once when an order reaches the completed state."""
        if not is_completed_status(order.status):
            raise BonusValidationError("Order must be completed before bonuses can be earned")
        if order.id is None:
            self.db.flush()

        existing = self.db.scalar(
            select(BonusTransaction).where(
                BonusTransaction.order_id == order.id,
                BonusTransaction.type == BonusTransactionType.earn,
            )
        )
        if existing is not None:
            return existing

        restaurant = self._require_restaurant(order.restaurant_id)
        bonus_earned = self._money(order.total_amount * restaurant.bonus_percent / Decimal("100"))
        order.bonus_earned = bonus_earned
        if bonus_earned <= 0:
            self._finish(commit=commit)
            return None

        account = self._get_or_create_account(order.user_id, order.restaurant_id)
        account.balance = self._money(account.balance + bonus_earned)
        account.total_earned = self._money(account.total_earned + bonus_earned)

        transaction = BonusTransaction(
            user_id=order.user_id,
            restaurant_id=order.restaurant_id,
            branch_id=order.branch_id,
            order_id=order.id,
            type=BonusTransactionType.earn,
            amount=bonus_earned,
            remaining_amount=bonus_earned,
            expires_at=self._default_expires_at(restaurant),
        )
        self.db.add(transaction)
        AuditService(self.db).write_log(
            AuditAction.bonus_earned,
            actor_user_id=order.user_id,
            entity_type="order",
            entity_id=order.id,
            details={"restaurant_id": order.restaurant_id, "amount": str(bonus_earned)},
        )
        self._finish(commit=commit)
        return transaction

    def _consume_fifo_credits(
        self,
        user_id: int,
        restaurant_id: int,
        amount: Decimal,
        branch_id: int | None,
        order_id: int | None,
    ) -> list[BonusTransaction]:
        """Consume available earn/manual credits by earliest expiration, then oldest credit."""
        remaining_to_spend = amount
        spend_transactions: list[BonusTransaction] = []
        credits = self.db.scalars(
            select(BonusTransaction)
            .where(
                BonusTransaction.user_id == user_id,
                BonusTransaction.restaurant_id == restaurant_id,
                BonusTransaction.type.in_(CREDIT_TYPES),
                BonusTransaction.remaining_amount > 0,
            )
            .order_by(
                BonusTransaction.expires_at.asc().nulls_last(),
                BonusTransaction.created_at.asc(),
                BonusTransaction.id.asc(),
            )
        ).all()

        for source in credits:
            if remaining_to_spend <= 0:
                break

            spend_amount = min(self._money(source.remaining_amount), remaining_to_spend)
            source.remaining_amount = self._money(source.remaining_amount - spend_amount)
            remaining_to_spend = self._money(remaining_to_spend - spend_amount)

            spend_transaction = BonusTransaction(
                user_id=user_id,
                restaurant_id=restaurant_id,
                branch_id=branch_id,
                order_id=order_id,
                type=BonusTransactionType.spend,
                amount=spend_amount,
                remaining_amount=Decimal("0.00"),
                expires_at=None,
                source_transaction_id=source.id,
            )
            self.db.add(spend_transaction)
            spend_transactions.append(spend_transaction)

        if remaining_to_spend > 0:
            raise InsufficientBonusBalanceError("Not enough unexpired bonuses available")

        return spend_transactions

    def _get_or_create_account(self, user_id: int, restaurant_id: int) -> BonusAccount:
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
        return account

    def _require_user(self, user_id: int) -> User:
        user = self.db.get(User, user_id)
        if user is None:
            raise BonusNotFoundError("User not found")
        return user

    def _require_restaurant(self, restaurant_id: int) -> Restaurant:
        restaurant = self.db.get(Restaurant, restaurant_id)
        if restaurant is None:
            raise BonusNotFoundError("Restaurant not found")
        return restaurant

    def _require_branch(self, branch_id: int, restaurant_id: int) -> Branch:
        branch = self.db.get(Branch, branch_id)
        if branch is None:
            raise BonusNotFoundError("Branch not found")
        if branch.restaurant_id != restaurant_id:
            raise BonusValidationError("Branch does not belong to this restaurant")
        return branch

    def _get_order_for_reference(
        self,
        order_id: int | None,
        user_id: int,
        restaurant_id: int,
        branch_id: int | None,
    ) -> Order | None:
        if order_id is None:
            return None

        order = self.db.get(Order, order_id)
        if order is None:
            raise BonusNotFoundError("Order not found")
        if order.user_id != user_id or order.restaurant_id != restaurant_id:
            raise BonusValidationError("Order does not belong to this user and restaurant")
        if branch_id is not None and order.branch_id != branch_id:
            raise BonusValidationError("Order does not belong to this branch")
        return order

    def _get_order_for_spending(
        self,
        order_id: int | None,
        user_id: int,
        restaurant_id: int,
        branch_id: int | None,
    ) -> Order | None:
        order = self._get_order_for_reference(order_id, user_id, restaurant_id, branch_id)
        if order is not None and is_completed_status(order.status):
            raise BonusValidationError("Bonuses cannot be spent on an already completed order")
        return order

    def _default_expires_at(self, restaurant: Restaurant) -> datetime | None:
        if restaurant.bonus_expiration_days <= 0:
            return None
        return datetime.now(timezone.utc) + timedelta(days=restaurant.bonus_expiration_days)

    def _finish(self, commit: bool | None = None) -> None:
        should_commit = self.auto_commit if commit is None else commit
        if should_commit:
            self.db.commit()
        elif not getattr(self.db, "_flushing", False):
            self.db.flush()

    @staticmethod
    def _money(value: Decimal) -> Decimal:
        return money(value)


def register_order_bonus_events() -> None:
    """Register SQLAlchemy hooks that award bonuses for completed orders."""
    global _ORDER_BONUS_EVENTS_REGISTERED
    if _ORDER_BONUS_EVENTS_REGISTERED:
        return

    @event.listens_for(SessionBase, "before_flush")
    def collect_completed_orders(session: Session, flush_context, instances) -> None:  # type: ignore[no-untyped-def]
        if session.info.get("_processing_bonus_events") or session.info.get("_skip_order_bonus_events"):
            return

        completed_orders: list[Order] = session.info.setdefault("_completed_orders_for_bonus", [])
        for order in list(session.new) + list(session.dirty):
            if not isinstance(order, Order) or not is_completed_status(order.status):
                continue

            state = inspect(order)
            status_history = state.attrs.status.history
            is_new_completed_order = order in session.new
            became_completed = status_history.has_changes() and not any(
                is_completed_status(status) for status in status_history.deleted
            )
            if is_new_completed_order or became_completed:
                completed_orders.append(order)

    @event.listens_for(SessionBase, "after_flush_postexec")
    def award_completed_order_bonuses(session: Session, flush_context) -> None:  # type: ignore[no-untyped-def]
        completed_orders: list[Order] = session.info.pop("_completed_orders_for_bonus", [])
        if not completed_orders or session.info.get("_processing_bonus_events"):
            return

        session.info["_processing_bonus_events"] = True
        try:
            service = BonusService(session, auto_commit=False)
            for order in completed_orders:
                if order.id is not None:
                    service.award_for_completed_order(order, commit=False)
        finally:
            session.info["_processing_bonus_events"] = False

    _ORDER_BONUS_EVENTS_REGISTERED = True
