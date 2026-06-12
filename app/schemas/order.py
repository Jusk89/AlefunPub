from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field

from app.models.order import OrderStatus, OrderType, PaymentMethod, PaymentStatus


class OrderItemRead(BaseModel):
    id: int
    order_id: int
    menu_item_id: int
    name_snapshot: str
    price_snapshot: Decimal
    quantity: int
    total_price: Decimal

    model_config = ConfigDict(from_attributes=True)


class OrderRead(BaseModel):
    id: int
    user_id: int
    restaurant_id: int
    branch_id: int
    order_type: OrderType
    status: OrderStatus
    total_amount: Decimal
    bonus_earned: Decimal
    bonus_spent: Decimal
    final_amount: Decimal
    payment_method: PaymentMethod
    payment_status: PaymentStatus
    created_at: datetime
    items: list[OrderItemRead] = Field(default_factory=list)

    model_config = ConfigDict(from_attributes=True)
