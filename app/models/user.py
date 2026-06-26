import enum
import uuid
from datetime import date, datetime

from sqlalchemy import Boolean, Date, DateTime, Enum, ForeignKey, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class UserRole(str, enum.Enum):
    client = "client"
    admin = "admin"
    cashier = "cashier"
    courier = "courier"
    owner = "owner"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    full_name: Mapped[str] = mapped_column(String(255), nullable=False)
    phone: Mapped[str] = mapped_column(String(32), unique=True, index=True, nullable=False)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    branch_id: Mapped[int | None] = mapped_column(ForeignKey("branches.id", ondelete="SET NULL"), index=True, nullable=True)
    qr_code: Mapped[str | None] = mapped_column(
        String(36),
        unique=True,
        index=True,
        default=lambda: str(uuid.uuid4()),
        nullable=True,
    )
    role: Mapped[UserRole] = mapped_column(
        Enum(UserRole, name="user_role"),
        default=UserRole.client,
        server_default=UserRole.client.value,
        nullable=False,
    )
    birth_date: Mapped[date | None] = mapped_column(Date, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true", nullable=False)
    last_login_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    created_by_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        nullable=False,
    )
    branch: Mapped["Branch | None"] = relationship(foreign_keys=[branch_id])
    created_by: Mapped["User | None"] = relationship(remote_side=[id], foreign_keys=[created_by_user_id])
    orders: Mapped[list["Order"]] = relationship(back_populates="user")
    bonus_accounts: Mapped[list["BonusAccount"]] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
    )
    bonus_transactions: Mapped[list["BonusTransaction"]] = relationship(back_populates="user")
    push_tokens: Mapped[list["PushToken"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    activity: Mapped["UserActivity | None"] = relationship(
        back_populates="user",
        cascade="all, delete-orphan",
        uselist=False,
    )
    addresses: Mapped[list["Address"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    gift_redemptions: Mapped[list["GiftRedemption"]] = relationship(back_populates="user", cascade="all, delete-orphan")
    delivery_orders: Mapped[list["DeliveryOrder"]] = relationship(back_populates="courier")
    audit_logs: Mapped[list["AuditLog"]] = relationship(back_populates="actor")
