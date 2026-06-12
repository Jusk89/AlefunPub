from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.user import User
from app.schemas.notification import PushTokenRead, PushTokenRegister
from app.services.notifications import register_push_token

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/push-token", response_model=PushTokenRead, status_code=status.HTTP_201_CREATED)
def register_device_token(
    payload: PushTokenRegister,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> PushTokenRead:
    return register_push_token(db, current_user.id, payload.token, payload.platform)
