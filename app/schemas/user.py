from datetime import date, datetime

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models.user import UserRole


class UserBase(BaseModel):
    full_name: str = Field(..., min_length=2, max_length=255)
    phone: str = Field(..., min_length=5, max_length=32)
    email: EmailStr
    birth_date: date | None = None


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
