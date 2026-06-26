from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import exists, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, require_owner
from app.models.gift import Gift, GiftRedemption
from app.models.user import User
from app.schemas.gift import GiftCreate, GiftRead, GiftUpdate, GiftUseResponse
from app.services.crud import get_record_or_404, update_record

router = APIRouter(prefix="/gifts", tags=["gifts"])


def get_gift_or_404(db: Session, gift_id: int) -> Gift:
    return get_record_or_404(db, Gift, gift_id, "Gift not found")


@router.get("", response_model=list[GiftRead])
def list_gifts(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
) -> list[Gift]:
    statement = select(Gift).order_by(Gift.created_at.desc()).offset(skip).limit(limit)
    return list(db.scalars(statement))


@router.post("", response_model=GiftRead, status_code=status.HTTP_201_CREATED)
def create_gift(
    payload: GiftCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
) -> Gift:
    gift = Gift(**payload.model_dump(), created_by_user_id=current_user.id)
    db.add(gift)
    db.commit()
    db.refresh(gift)
    return gift


@router.get("/my", response_model=list[GiftRead])
def list_my_unused_gifts(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Gift]:
    used_by_current_user = (
        select(GiftRedemption.id)
        .where(
            GiftRedemption.gift_id == Gift.id,
            GiftRedemption.user_id == current_user.id,
        )
        .exists()
    )
    statement = (
        select(Gift)
        .where(Gift.is_active.is_(True))
        .where(~used_by_current_user)
        .order_by(Gift.created_at.desc())
    )
    return list(db.scalars(statement))


@router.post("/{gift_id}/use", response_model=GiftUseResponse)
def use_gift(
    gift_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> GiftUseResponse:
    gift = get_gift_or_404(db, gift_id)
    if not gift.is_active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Gift not found")

    already_used = db.scalar(
        select(
            exists().where(
                GiftRedemption.gift_id == gift_id,
                GiftRedemption.user_id == current_user.id,
            )
        )
    )
    if not already_used:
        db.add(GiftRedemption(gift_id=gift_id, user_id=current_user.id))
        db.commit()
    return GiftUseResponse(gift_id=gift_id, used=True)


@router.get("/{gift_id}", response_model=GiftRead)
def get_gift(
    gift_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
) -> Gift:
    return get_gift_or_404(db, gift_id)


@router.patch("/{gift_id}", response_model=GiftRead)
def update_gift(
    gift_id: int,
    payload: GiftUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
) -> Gift:
    gift = get_gift_or_404(db, gift_id)
    return update_record(db, gift, payload)


@router.delete("/{gift_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_gift(
    gift_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_owner),
) -> Response:
    gift = get_gift_or_404(db, gift_id)
    db.delete(gift)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
