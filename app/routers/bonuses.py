from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user, require_admin_or_owner
from app.models.user import User
from app.schemas.bonus import (
    BonusBalanceRead,
    BonusExpireOldRequest,
    BonusExpireOldResponse,
    BonusManualRequest,
    BonusSpendRequest,
    BonusSpendResponse,
    BonusTransactionRead,
)
from app.services.bonuses import (
    BonusNotFoundError,
    BonusService,
    BonusServiceError,
    BonusValidationError,
    InsufficientBonusBalanceError,
)

router = APIRouter(prefix="/bonuses", tags=["bonuses"])


def bonus_service(db: Session = Depends(get_db)) -> BonusService:
    """Provide a request-scoped bonus service."""
    return BonusService(db)


def raise_http_error(error: BonusServiceError) -> None:
    if isinstance(error, BonusNotFoundError):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(error))
    if isinstance(error, (BonusValidationError, InsufficientBonusBalanceError)):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(error))
    raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Bonus service error")


@router.get("/balance", response_model=BonusBalanceRead)
def get_bonus_balance(
    restaurant_id: int = Query(...),
    current_user: User = Depends(get_current_user),
    service: BonusService = Depends(bonus_service),
) -> BonusBalanceRead:
    try:
        return service.get_balance(current_user.id, restaurant_id)
    except BonusServiceError as error:
        raise_http_error(error)


@router.get("/history", response_model=list[BonusTransactionRead])
def get_bonus_history(
    restaurant_id: int | None = None,
    skip: int = 0,
    limit: int = 100,
    current_user: User = Depends(get_current_user),
    service: BonusService = Depends(bonus_service),
) -> list[BonusTransactionRead]:
    return service.list_history(current_user.id, restaurant_id=restaurant_id, skip=skip, limit=limit)


@router.post("/spend", response_model=BonusSpendResponse)
def spend_bonuses(
    payload: BonusSpendRequest,
    current_user: User = Depends(get_current_user),
    service: BonusService = Depends(bonus_service),
) -> BonusSpendResponse:
    try:
        account, transactions = service.spend(
            user_id=current_user.id,
            restaurant_id=payload.restaurant_id,
            amount=payload.amount,
            branch_id=payload.branch_id,
            order_id=payload.order_id,
        )
        return BonusSpendResponse(account=account, transactions=transactions)
    except BonusServiceError as error:
        raise_http_error(error)


@router.post("/manual", response_model=BonusTransactionRead, dependencies=[Depends(require_admin_or_owner)])
def create_manual_bonus(
    payload: BonusManualRequest,
    service: BonusService = Depends(bonus_service),
) -> BonusTransactionRead:
    try:
        return service.manual_credit(
            user_id=payload.user_id,
            restaurant_id=payload.restaurant_id,
            amount=payload.amount,
            branch_id=payload.branch_id,
            order_id=payload.order_id,
            expires_at=payload.expires_at,
        )
    except BonusServiceError as error:
        raise_http_error(error)


@router.post("/expire-old", response_model=BonusExpireOldResponse, dependencies=[Depends(require_admin_or_owner)])
def expire_old_bonuses(
    payload: BonusExpireOldRequest,
    service: BonusService = Depends(bonus_service),
) -> BonusExpireOldResponse:
    try:
        expired_amount, transactions = service.expire_old(
            user_id=payload.user_id,
            restaurant_id=payload.restaurant_id,
        )
        return BonusExpireOldResponse(
            expired_amount=expired_amount,
            transactions_created=len(transactions),
        )
    except BonusServiceError as error:
        raise_http_error(error)
