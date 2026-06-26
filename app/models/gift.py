from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Gift(Base):
    __tablename__ = "gifts"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    title: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    image_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True, server_default="true", nullable=False)
    created_by_user_id: Mapped[int | None] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL"),
        index=True,
        nullable=True,
    )
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    created_by: Mapped["User | None"] = relationship(foreign_keys=[created_by_user_id])
    redemptions: Mapped[list["GiftRedemption"]] = relationship(
        back_populates="gift",
        cascade="all, delete-orphan",
    )


class GiftRedemption(Base):
    __tablename__ = "gift_redemptions"
    __table_args__ = (
        UniqueConstraint("gift_id", "user_id", name="uq_gift_redemptions_gift_user"),
        Index("ix_gift_redemptions_user_used", "user_id", "used_at"),
    )

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    gift_id: Mapped[int] = mapped_column(ForeignKey("gifts.id", ondelete="CASCADE"), index=True, nullable=False)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)
    used_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    gift: Mapped["Gift"] = relationship(back_populates="redemptions")
    user: Mapped["User"] = relationship(back_populates="gift_redemptions")
