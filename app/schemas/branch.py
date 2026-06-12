from datetime import time
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class BranchBase(BaseModel):
    restaurant_id: int
    name: str = Field(..., min_length=2, max_length=255)
    address: str = Field(..., min_length=2, max_length=500)
    phone: str | None = Field(default=None, max_length=32)
    latitude: Decimal | None = Field(default=None, ge=-90, le=90)
    longitude: Decimal | None = Field(default=None, ge=-180, le=180)
    opening_time: time | None = None
    closing_time: time | None = None
    is_active: bool = True


class BranchCreate(BranchBase):
    pass


class BranchUpdate(BaseModel):
    restaurant_id: int | None = None
    name: str | None = Field(default=None, min_length=2, max_length=255)
    address: str | None = Field(default=None, min_length=2, max_length=500)
    phone: str | None = Field(default=None, max_length=32)
    latitude: Decimal | None = Field(default=None, ge=-90, le=90)
    longitude: Decimal | None = Field(default=None, ge=-180, le=180)
    opening_time: time | None = None
    closing_time: time | None = None
    is_active: bool | None = None


class BranchRead(BranchBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
