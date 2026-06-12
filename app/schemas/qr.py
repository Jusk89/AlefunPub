from decimal import Decimal

from pydantic import BaseModel, Field

from app.models.order import PaymentMethod


class QrLookupRequest(BaseModel):
    qr_code: str = Field(..., min_length=10, max_length=36)


class QrLookupResponse(BaseModel):
    id: int
    full_name: str
    phone: str
    current_bonus_balance: Decimal


class QrOrderCreate(BaseModel):
    qr_code: str = Field(..., min_length=10, max_length=36)
    branch_id: int
    total_amount: Decimal = Field(..., gt=0)
    payment_method: PaymentMethod
    use_bonuses: bool


class QrOrderResponse(BaseModel):
    order_id: int
    client_full_name: str
    total_amount: Decimal
    bonus_spent: Decimal
    bonus_earned: Decimal
    final_amount: Decimal
    new_bonus_balance: Decimal
