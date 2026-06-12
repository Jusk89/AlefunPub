import enum
from datetime import datetime
from decimal import Decimal

from sqlalchemy import DateTime, Enum, ForeignKey, Index, Numeric, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class BonusTransactionType(str, enum.Enum):
    earn = "earn"
    spend = "spend"
    expire = "expire"
    manual = "manual"


class BonusAccount(Base):
    __tablename__ = "bonus_accounts"
    __table_args__ = (UniqueConstraint("user_id", "restaurant_id", name="uq_bonus_accounts_user_restaurant"),)

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    restaurant_id: Mapped[int] = mapped_column(ForeignKey("restaurants.id", ondelete="CASCADE"), index=True)
    balance: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, server_default="0", nullable=False)
    total_earned: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, server_default="0", nullable=False)
    total_spent: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, server_default="0", nullable=False)

    user: Mapped["User"] = relationship(back_populates="bonus_accounts")
    restaurant: Mapped["Restaurant"] = relationship(back_populates="bonus_accounts")


class BonusTransaction(Base):
    __tablename__ = "bonus_transactions"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    restaurant_id: Mapped[int] = mapped_column(ForeignKey("restaurants.id", ondelete="CASCADE"), index=True)
    branch_id: Mapped[int | None] = mapped_column(ForeignKey("branches.id", ondelete="SET NULL"), index=True)
    order_id: Mapped[int | None] = mapped_column(ForeignKey("orders.id", ondelete="SET NULL"), index=True)
    type: Mapped[BonusTransactionType] = mapped_column(
        Enum(BonusTransactionType, name="bonus_transaction_type"),
        nullable=False,
    )
    amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), nullable=False)
    remaining_amount: Mapped[Decimal] = mapped_column(Numeric(12, 2), default=0, server_default="0", nullable=False)
    expires_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    source_transaction_id: Mapped[int | None] = mapped_column(
        ForeignKey("bonus_transactions.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )

    user: Mapped["User"] = relationship(back_populates="bonus_transactions")
    restaurant: Mapped["Restaurant"] = relationship(back_populates="bonus_transactions")
    branch: Mapped["Branch"] = relationship(back_populates="bonus_transactions")
    order: Mapped["Order"] = relationship(back_populates="bonus_transactions")
    source_transaction: Mapped["BonusTransaction | None"] = relationship(
        remote_side="BonusTransaction.id",
        back_populates="child_transactions",
    )
    child_transactions: Mapped[list["BonusTransaction"]] = relationship(back_populates="source_transaction")


Index(
    "ix_bonus_transactions_fifo_lookup",
    BonusTransaction.user_id,
    BonusTransaction.restaurant_id,
    BonusTransaction.type,
    BonusTransaction.expires_at,
    BonusTransaction.created_at,
)
Index("ix_bonus_transactions_order_type", BonusTransaction.order_id, BonusTransaction.type)
