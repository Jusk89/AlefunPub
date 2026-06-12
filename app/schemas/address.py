from datetime import datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class AddressBase(BaseModel):
    label: str | None = Field(default=None, max_length=100)
    address_line: str = Field(..., min_length=2, max_length=500)
    city: str = Field(..., min_length=2, max_length=255)
    apartment: str | None = Field(default=None, max_length=50)
    entrance: str | None = Field(default=None, max_length=50)
    floor: str | None = Field(default=None, max_length=50)
    latitude: Decimal | None = Field(default=None, ge=-90, le=90)
    longitude: Decimal | None = Field(default=None, ge=-180, le=180)
    is_default: bool = False


class AddressCreate(AddressBase):
    pass


class AddressUpdate(BaseModel):
    label: str | None = Field(default=None, max_length=100)
    address_line: str | None = Field(default=None, min_length=2, max_length=500)
    city: str | None = Field(default=None, min_length=2, max_length=255)
    apartment: str | None = Field(default=None, max_length=50)
    entrance: str | None = Field(default=None, max_length=50)
    floor: str | None = Field(default=None, max_length=50)
    latitude: Decimal | None = Field(default=None, ge=-90, le=90)
    longitude: Decimal | None = Field(default=None, ge=-180, le=180)
    is_default: bool | None = None


class AddressRead(AddressBase):
    id: int
    user_id: int
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
