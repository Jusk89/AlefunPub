from sqlalchemy.orm import Session

from app.models.user import User
from app.services.security import verify_password
from app.services.users import get_user_by_email, get_user_by_phone


def authenticate_user(db: Session, identifier: str, password: str) -> User | None:
    """Authenticate a user by email or phone and plaintext password."""
    user = get_user_by_email(db, identifier) or get_user_by_phone(db, identifier)
    if user is None:
        return None
    if not verify_password(password, user.password_hash):
        return None
    return user
