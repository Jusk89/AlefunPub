from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.schemas.text import normalize_unicode_text


class MenuCategoryBase(BaseModel):
    name: str = Field(..., min_length=2, max_length=255)
    sort_order: int = 0
    is_active: bool = True

    _normalize_text = field_validator("name", mode="before")(normalize_unicode_text)


class MenuCategoryCreate(MenuCategoryBase):
    pass


class MenuCategoryUpdate(BaseModel):
    name: str | None = Field(default=None, min_length=2, max_length=255)
    sort_order: int | None = None
    is_active: bool | None = None

    _normalize_text = field_validator("name", mode="before")(normalize_unicode_text)


class MenuCategoryRead(MenuCategoryBase):
    id: int

    model_config = ConfigDict(from_attributes=True)


class MenuItemBase(BaseModel):
    category_id: int
    name: str = Field(..., min_length=2, max_length=255)
    description: str | None = None
    price: Decimal = Field(..., ge=0)
    image_url: str | None = Field(default=None, max_length=2048)
    is_available: bool = True

    _normalize_text = field_validator("name", "description", mode="before")(normalize_unicode_text)


class MenuItemCreate(MenuItemBase):
    pass


class MenuItemUpdate(BaseModel):
    category_id: int | None = None
    name: str | None = Field(default=None, min_length=2, max_length=255)
    description: str | None = None
    price: Decimal | None = Field(default=None, ge=0)
    image_url: str | None = Field(default=None, max_length=2048)
    is_available: bool | None = None

    _normalize_text = field_validator("name", "description", mode="before")(normalize_unicode_text)


class MenuItemRead(MenuItemBase):
    id: int

    model_config = ConfigDict(from_attributes=True)
