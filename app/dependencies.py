from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from sqlalchemy.orm import Session

from app.config import settings
from app.database import get_db
from app.models.user import User, UserRole
from app.services.users import get_user_by_id

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/token")


def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> User:
    """Resolve the bearer token into the authenticated user for protected routes."""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )

    try:
        payload = jwt.decode(
            token,
            settings.jwt_secret_key,
            algorithms=[settings.jwt_algorithm],
        )
        subject = payload.get("sub")
        if subject is None:
            raise credentials_exception
        user_id = int(subject)
    except (JWTError, ValueError):
        raise credentials_exception

    user = get_user_by_id(db, user_id)
    if user is None:
        raise credentials_exception
    if not user.is_active:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User account is inactive",
        )

    return user


def require_roles(current_user: User, allowed_roles: set[UserRole]) -> User:
    """Validate that the current user has one of the allowed application roles."""
    if current_user.role not in allowed_roles:
        allowed = ", ".join(role.value for role in sorted(allowed_roles, key=lambda role: role.value))
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"One of these roles is required: {allowed}",
        )
    return current_user


def require_staff_user(current_user: User = Depends(get_current_user)) -> User:
    """Allow back-office users that can manage operational data."""
    return require_roles(current_user, {UserRole.owner, UserRole.admin, UserRole.cashier})


def require_cashier_or_admin(current_user: User = Depends(get_current_user)) -> User:
    """Allow users who can operate cashier-facing QR and payment flows."""
    return require_roles(current_user, {UserRole.owner, UserRole.admin, UserRole.cashier})


def require_admin_or_owner(current_user: User = Depends(get_current_user)) -> User:
    """Allow management users for menu, campaign, and staff administration."""
    return require_roles(current_user, {UserRole.owner, UserRole.admin})


def require_owner(current_user: User = Depends(get_current_user)) -> User:
    """Allow only the owner role."""
    return require_roles(current_user, {UserRole.owner})
