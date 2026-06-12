from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field


class MenuCategoryBase(BaseModel):
    restaurant_id: int
    name: str = Field(..., min_length=2, max_length=255)
    sort_order: int = 0
    is_active: bool = True


class MenuCategoryCreate(MenuCategoryBase):
    pass


class MenuCategoryUpdate(BaseModel):
    restaurant_id: int | None = None
    name: str | None = Field(default=None, min_length=2, max_length=255)
    sort_order: int | None = None
    is_active: bool | None = None


class MenuCategoryRead(MenuCategoryBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class MenuItemBase(BaseModel):
    restaurant_id: int
    category_id: int
    name: str = Field(..., min_length=2, max_length=255)
    description: str | None = None
    price: Decimal = Field(..., ge=0)
    image_url: str | None = Field(default=None, max_length=2048)
    is_available: bool = True


class MenuItemCreate(MenuItemBase):
    pass


class MenuItemUpdate(BaseModel):
    restaurant_id: int | None = None
    category_id: int | None = None
    name: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = None
    price: Decimal | None = Field(default=None, ge=0)
    image_url: str | None = Field(default=None, max_length=2048)
    is_available: bool | None = None


class MenuItemRead(MenuItemBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
