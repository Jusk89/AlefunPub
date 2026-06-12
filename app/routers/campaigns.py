from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_staff_user
from app.models.audit import AuditAction
from app.models.campaign import Campaign
from app.models.user import User
from app.schemas.campaign import CampaignCreate, CampaignRead, CampaignUpdate
from app.services.audit import AuditService
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/campaigns", tags=["campaigns"])


def get_campaign_or_404(db: Session, campaign_id: int) -> Campaign:
    return get_record_or_404(db, Campaign, campaign_id, "Campaign not found")


@router.get("", response_model=list[CampaignRead], dependencies=[Depends(require_staff_user)])
def list_campaigns(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> list[Campaign]:
    return list_records(db, Campaign, skip=skip, limit=limit)


@router.post("", response_model=CampaignRead, status_code=status.HTTP_201_CREATED)
def create_campaign(
    payload: CampaignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff_user),
) -> Campaign:
    campaign = create_record(db, Campaign, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.campaign_created,
        actor_user_id=current_user.id,
        entity_type="campaign",
        entity_id=campaign.id,
        details={"target_group": campaign.target_group.value},
    )
    return campaign


@router.get("/{campaign_id}", response_model=CampaignRead, dependencies=[Depends(require_staff_user)])
def get_campaign(campaign_id: int, db: Session = Depends(get_db)) -> Campaign:
    return get_campaign_or_404(db, campaign_id)


@router.patch("/{campaign_id}", response_model=CampaignRead)
def update_campaign(
    campaign_id: int,
    payload: CampaignUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff_user),
) -> Campaign:
    campaign = get_campaign_or_404(db, campaign_id)
    return update_record(db, campaign, payload)


@router.delete("/{campaign_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_campaign(
    campaign_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_staff_user),
) -> Response:
    campaign = get_campaign_or_404(db, campaign_id)
    delete_record(db, campaign)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
