from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class RestaurantBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    description: str | None = None
    logo_url: str | None = Field(default=None, max_length=2048)
    bonus_percent: Decimal = Field(default=0, ge=0, le=100)
    bonus_expiration_days: int = Field(default=0, ge=0)


class RestaurantCreate(RestaurantBase):
    pass


class RestaurantUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = None
    logo_url: str | None = Field(default=None, max_length=2048)
    bonus_percent: Decimal | None = Field(default=None, ge=0, le=100)
    bonus_expiration_days: int | None = Field(default=None, ge=0)


class RestaurantRead(RestaurantBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
