from datetime import datetime, timedelta, timezone
from decimal import Decimal

from sqlalchemy import event, inspect, or_, select
from sqlalchemy.orm import Session, Session as SessionBase

from app.models.activity import UserActivity
from app.models.audit import AuditAction
from app.models.notification import PushToken
from app.models.order import Order
from app.models.user import User, UserRole
from app.services.audit import AuditService
from app.services.bonuses import is_completed_status
from app.services.notifications import NotificationService

_ORDER_ACTIVITY_EVENTS_REGISTERED = False


def get_or_create_activity(db: Session, user_id: int) -> UserActivity:
    """Return the user's activity aggregate, creating it when missing."""
    activity = db.scalar(select(UserActivity).where(UserActivity.user_id == user_id))
    if activity is not None:
        return activity

    activity = UserActivity(
        user_id=user_id,
        total_spent=Decimal("0.00"),
        total_orders=0,
    )
    db.add(activity)
    return activity


def record_visit(db: Session, user_id: int) -> UserActivity:
    """Mark a user as recently active after login or QR order."""
    activity = get_or_create_activity(db, user_id)
    activity.last_visit_at = datetime.now(timezone.utc)
    db.commit()
    db.refresh(activity)
    return activity


class ActivityService:
    """Customer activity workflows such as inactive-client outreach."""

    def __init__(self, db: Session, notification_service: NotificationService | None = None) -> None:
        self.db = db
        self.notification_service = notification_service or NotificationService()

    def send_inactive_invitations(self) -> int:
        """Send placeholder push invitations to clients inactive for at least 30 days."""
        cutoff = datetime.now(timezone.utc) - timedelta(days=30)
        statement = (
            select(User, UserActivity, PushToken)
            .join(UserActivity, UserActivity.user_id == User.id)
            .join(PushToken, PushToken.user_id == User.id)
            .where(
                User.role == UserRole.client,
                PushToken.is_active.is_(True),
                or_(UserActivity.last_visit_at.is_(None), UserActivity.last_visit_at <= cutoff),
            )
        )

        notified_user_ids: set[int] = set()
        now = datetime.now(timezone.utc)
        for user, activity, push_token in self.db.execute(statement).all():
            self.notification_service.send_push(
                token=push_token.token,
                title="We miss you",
                body="Come back and enjoy your favorite restaurant rewards.",
                data={"type": "inactive_invitation"},
            )
            activity.last_notification_sent_at = now
            notified_user_ids.add(user.id)

        self.db.commit()
        return len(notified_user_ids)


def register_order_activity_events() -> None:
    """Register SQLAlchemy hooks for order audit and activity aggregates."""
    global _ORDER_ACTIVITY_EVENTS_REGISTERED
    if _ORDER_ACTIVITY_EVENTS_REGISTERED:
        return

    @event.listens_for(SessionBase, "before_flush")
    def collect_order_activity_events(session: Session, flush_context, instances) -> None:  # type: ignore[no-untyped-def]
        if session.info.get("_processing_order_activity_events") or session.info.get("_skip_order_activity_events"):
            return

        created_orders: list[Order] = session.info.setdefault("_created_orders_for_activity", [])
        completed_orders: list[Order] = session.info.setdefault("_completed_orders_for_activity", [])

        for order in list(session.new):
            if isinstance(order, Order):
                created_orders.append(order)
                if is_completed_status(order.status):
                    completed_orders.append(order)

        for order in list(session.dirty):
            if not isinstance(order, Order) or not is_completed_status(order.status):
                continue
            status_history = inspect(order).attrs.status.history
            became_completed = status_history.has_changes() and not any(
                is_completed_status(status) for status in status_history.deleted
            )
            if became_completed:
                completed_orders.append(order)

    @event.listens_for(SessionBase, "after_flush_postexec")
    def write_order_activity_events(session: Session, flush_context) -> None:  # type: ignore[no-untyped-def]
        created_orders: list[Order] = session.info.pop("_created_orders_for_activity", [])
        completed_orders: list[Order] = session.info.pop("_completed_orders_for_activity", [])
        if session.info.get("_processing_order_activity_events"):
            return

        session.info["_processing_order_activity_events"] = True
        try:
            audit_service = AuditService(session)
            for order in created_orders:
                audit_service.write_log(
                    AuditAction.order_created,
                    actor_user_id=order.user_id,
                    entity_type="order",
                    entity_id=order.id,
                    details={"restaurant_id": order.restaurant_id, "branch_id": order.branch_id},
                )

            for order in completed_orders:
                activity = get_or_create_activity(session, order.user_id)
                activity.total_orders += 1
                activity.total_spent += order.final_amount
                audit_service.write_log(
                    AuditAction.order_completed,
                    actor_user_id=order.user_id,
                    entity_type="order",
                    entity_id=order.id,
                    details={"final_amount": str(order.final_amount)},
                )
        finally:
            session.info["_processing_order_activity_events"] = False

    _ORDER_ACTIVITY_EVENTS_REGISTERED = True
