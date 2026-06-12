from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.bonus import BonusTransactionType


class BonusBalanceRead(BaseModel):
    user_id: int
    restaurant_id: int
    balance: Decimal
    total_earned: Decimal
    total_spent: Decimal

    model_config = ConfigDict(from_attributes=True)


class BonusTransactionRead(BaseModel):
    id: int
    user_id: int
    restaurant_id: int
    branch_id: int | None
    order_id: int | None
    type: BonusTransactionType
    amount: Decimal
    remaining_amount: Decimal
    expires_at: datetime | None
    source_transaction_id: int | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class BonusSpendRequest(BaseModel):
    restaurant_id: int
    amount: Decimal = Field(..., gt=0)
    branch_id: int | None = None
    order_id: int | None = None


class BonusSpendResponse(BaseModel):
    account: BonusBalanceRead
    transactions: list[BonusTransactionRead]


class BonusManualRequest(BaseModel):
    user_id: int
    restaurant_id: int
    amount: Decimal = Field(..., gt=0)
    branch_id: int | None = None
    order_id: int | None = None
    expires_at: datetime | None = None


class BonusExpireOldRequest(BaseModel):
    restaurant_id: int | None = None
    user_id: int | None = None


class BonusExpireOldResponse(BaseModel):
    expired_amount: Decimal
    transactions_created: int


