from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import UserRole
from app.schemas.text import normalize_unicode_text


class UserBase(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: str = Field(..., min_length=5, max_length=32)
    email: EmailStr
    birth_date: date | None = None

    _normalize_text = field_validator("full_name", mode="before")(normalize_unicode_text)


class UserCreate(UserBase):
    password: str = Field(..., min_length=8, max_length=128)


class UserRead(UserBase):
    id: int
    qr_code: str | None
    role: UserRole
    is_active: bool
    last_login_at: datetime | None
    created_by_user_id: int | None
    branch_id: int | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
