from datetime import datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from app.models.user import UserRole
from app.schemas.text import normalize_unicode_text


class StaffCreate(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: str = Field(..., min_length=5, max_length=32)
    email: EmailStr
    password: str = Field(..., min_length=8, max_length=128)
    role: UserRole
    branch_id: int | None = None

    _normalize_text = field_validator("full_name", mode="before")(normalize_unicode_text)


class StaffUpdate(BaseModel):
    full_name: str | None = Field(default=None, min_length=2, max_length=255)
    phone: str | None = Field(default=None, min_length=5, max_length=32)
    email: EmailStr | None = None
    password: str | None = Field(default=None, min_length=8, max_length=128)
    role: UserRole | None = None
    branch_id: int | None = None

    _normalize_text = field_validator("full_name", mode="before")(normalize_unicode_text)


class StaffRead(BaseModel):
    id: int
    full_name: str
    phone: str
    email: EmailStr
    role: UserRole
    branch_id: int | None
    is_active: bool
    last_login_at: datetime | None
    created_by_user_id: int | None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
