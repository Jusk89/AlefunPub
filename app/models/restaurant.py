from decimal import Decimal

from sqlalchemy import Integer, Numeric, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.database import Base


class Restaurant(Base):
    __tablename__ = "restaurants"

    id: Mapped[int] = mapped_column(primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(255), nullable=False)
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    logo_url: Mapped[str | None] = mapped_column(String(2048), nullable=True)
    bonus_percent: Mapped[Decimal] = mapped_column(Numeric(5, 2), default=5, server_default="5", nullable=False)
    bonus_expiration_days: Mapped[int] = mapped_column(Integer, default=0, server_default="0", nullable=False)

    branches: Mapped[list["Branch"]] = relationship(
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    orders: Mapped[list["Order"]] = relationship(back_populates="restaurant")
    bonus_accounts: Mapped[list["BonusAccount"]] = relationship(
        back_populates="restaurant",
        cascade="all, delete-orphan",
    )
    bonus_transactions: Mapped[list["BonusTransaction"]] = relationship(back_populates="restaurant")
