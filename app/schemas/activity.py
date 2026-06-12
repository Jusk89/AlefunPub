from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict


class UserActivityRead(BaseModel):
    id: int
    user_id: int
    last_visit_at: datetime | None
    total_spent: Decimal
    total_orders: int
    last_notification_sent_at: datetime | None

    model_config = ConfigDict(from_attributes=True)


class InactiveInvitationResponse(BaseModel):
    users_notified: int
