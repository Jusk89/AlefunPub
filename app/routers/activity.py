from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin_or_owner
from app.schemas.activity import InactiveInvitationResponse
from app.services.activity import ActivityService

router = APIRouter(prefix="/activity", tags=["activity"])


@router.post(
    "/send-inactive-invitations",
    response_model=InactiveInvitationResponse,
    dependencies=[Depends(require_admin_or_owner)],
)
def send_inactive_invitations(db: Session = Depends(get_db)) -> InactiveInvitationResponse:
    users_notified = ActivityService(db).send_inactive_invitations()
    return InactiveInvitationResponse(users_notified=users_notified)
