from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field


class PushTokenRegister(BaseModel):
    token: str = Field(..., min_length=10, max_length=512)
    platform: str | None = Field(default=None, max_length=50)


class PushTokenRead(BaseModel):
    id: int
    user_id: int
    token: str
    platform: str | None
    is_active: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
