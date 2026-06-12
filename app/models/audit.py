import enum
from datetime import datetime
from typing import Any

from sqlalchemy import DateTime, Enum, ForeignKey, Index, JSON, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class AuditAction(str, enum.Enum):
    user_registered = "user_registered"
    order_created = "order_created"
    order_completed = "order_completed"
    order_created_from_qr = "order_created_from_qr"
    bonus_earned = "bonus_earned"
    bonus_spent = "bonus_spent"
    bonus_earned_from_qr = "bonus_earned_from_qr"
    bonus_spent_from_qr = "bonus_spent_from_qr"
    campaign_created = "campaign_created"


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    action: Mapped[AuditAction] = mapped_column(Enum(AuditAction, name="audit_action"), index=True, nullable=False)
    actor_user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    entity_type: Mapped[str | None] = mapped_column(String(100), nullable=True)
    entity_id: Mapped[int | None] = mapped_column(nullable=True)
    details: Mapped[dict[str, Any] | None] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    actor: Mapped["User | None"] = relationship(back_populates="audit_logs")


Index("ix_audit_logs_entity", AuditLog.entity_type, AuditLog.entity_id)
