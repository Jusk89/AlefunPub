import uuid

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.user import User, UserRole
from app.schemas.user import UserCreate
from app.services.activity import get_or_create_activity
from app.services.audit import AuditService
from app.services.security import hash_password
from app.models.audit import AuditAction


def get_user_by_id(db: Session, user_id: int) -> User | None:
    """Fetch a user by primary key."""
    return db.get(User, user_id)


def get_user_by_email(db: Session, email: str) -> User | None:
    """Fetch a user by normalized email address."""
    statement = select(User).where(User.email == email.lower())
    return db.scalar(statement)


def get_user_by_phone(db: Session, phone: str) -> User | None:
    """Fetch a user by phone number."""
    statement = select(User).where(User.phone == phone)
    return db.scalar(statement)


def create_user(db: Session, payload: UserCreate) -> User:
    """Create a client user with a hashed password and permanent QR code."""
    user = User(
        full_name=payload.full_name,
        phone=payload.phone,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        qr_code=str(uuid.uuid4()),
        role=UserRole.client,
        birth_date=payload.birth_date,
    )
    db.add(user)
    db.flush()
    get_or_create_activity(db, user.id)
    AuditService(db).write_log(
        AuditAction.user_registered,
        actor_user_id=user.id,
        entity_type="user",
        entity_id=user.id,
    )
    db.commit()
    db.refresh(user)
    return user
