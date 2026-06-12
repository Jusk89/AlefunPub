import enum
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Numeric, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class DeliveryStatus(str, enum.Enum):
    waiting = "waiting"
    assigned = "assigned"
    on_the_way = "on_the_way"
    delivered = "delivered"
    cancelled = "cancelled"


class DeliveryOrder(Base):
    __tablename__ = "delivery_orders"
    __table_args__ = (UniqueConstraint("order_id", name="uq_delivery_orders_order_id"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    order_id: Mapped[int] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), index=True)
    address_id: Mapped[int] = mapped_column(ForeignKey("addresses.id", ondelete="RESTRICT"), index=True)
    courier_id: Mapped[int | None] = mapped_column(ForeignKey("users.id", ondelete="SET NULL"), index=True)
    delivery_fee: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, server_default="0", nullable=False)
    delivery_status: Mapped[DeliveryStatus] = mapped_column(
        Enum(DeliveryStatus, name="delivery_status"),
        default=DeliveryStatus.waiting,
        server_default=DeliveryStatus.waiting.value,
        nullable=False,
    )
    estimated_delivery_time: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    order: Mapped["Order"] = relationship(back_populates="delivery_order")
    address: Mapped["Address"] = relationship(back_populates="delivery_orders")
    courier: Mapped["User | None"] = relationship(back_populates="delivery_orders")
