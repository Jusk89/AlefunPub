from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, require_admin_or_owner
from app.models.audit import AuditAction
from app.models.campaign import Campaign
from app.models.user import User, UserRole
from app.schemas.campaign import CampaignCreate, CampaignRead, CampaignUpdate
from app.services.audit import AuditService
from app.services.crud import delete_record, get_record_or_404, update_record

router = APIRouter(prefix="/campaigns", tags=["campaigns"])


def get_campaign_or_404(db: Session, campaign_id: int) -> Campaign:
    return get_record_or_404(db, Campaign, campaign_id, "Campaign not found")


@router.get("", response_model=list[CampaignRead])
def list_campaigns(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Campaign]:
    statement = select(Campaign).order_by(Campaign.created_at.desc()).offset(skip).limit(limit)
    if current_user.role not in {UserRole.owner, UserRole.admin}:
        statement = statement.where(Campaign.is_active.is_(True))
    return list(db.scalars(statement))


@router.post("", response_model=CampaignRead, status_code=status.HTTP_201_CREATED)
def create_campaign(
    payload: CampaignCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> Campaign:
    campaign = Campaign(**payload.model_dump(), created_by_user_id=current_user.id)
    db.add(campaign)
    db.flush()
    AuditService(db).write_log(
        AuditAction.campaign_created,
        actor_user_id=current_user.id,
        entity_type="campaign",
        entity_id=campaign.id,
        details={"target_group": campaign.target_group.value},
    )
    db.commit()
    db.refresh(campaign)
    return campaign


@router.get("/{campaign_id}", response_model=CampaignRead)
def get_campaign(
    campaign_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Campaign:
    campaign = get_campaign_or_404(db, campaign_id)
    if current_user.role not in {UserRole.owner, UserRole.admin} and not campaign.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Campaign not found")
    return campaign


@router.patch("/{campaign_id}", response_model=CampaignRead)
def update_campaign(
    campaign_id: int,
    payload: CampaignUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> Campaign:
    campaign = get_campaign_or_404(db, campaign_id)
    campaign = update_record(db, campaign, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.campaign_updated,
        actor_user_id=current_user.id,
        entity_type="campaign",
        entity_id=campaign.id,
    )
    db.refresh(campaign)
    return campaign


@router.delete("/{campaign_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_campaign(
    campaign_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> Response:
    campaign = get_campaign_or_404(db, campaign_id)
    campaign_id_for_log = campaign.id
    delete_record(db, campaign)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.campaign_deleted,
        actor_user_id=current_user.id,
        entity_type="campaign",
        entity_id=campaign_id_for_log,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
