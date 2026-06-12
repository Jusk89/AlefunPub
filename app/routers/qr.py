from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_cashier_or_admin
from app.schemas.qr import QrLookupRequest, QrLookupResponse, QrOrderCreate, QrOrderResponse
from app.services.qr import QrFlowError, QrNotFoundError, QrService

router = APIRouter(tags=["qr loyalty"])


def handle_qr_error(error: QrFlowError) -> None:
    if isinstance(error, QrNotFoundError):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(error))
    raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(error))


@router.post("/qr/lookup", response_model=QrLookupResponse, dependencies=[Depends(require_cashier_or_admin)])
def lookup_client_by_qr(payload: QrLookupRequest, db: Session = Depends(get_db)) -> QrLookupResponse:
    try:
        client, current_bonus_balance = QrService(db).lookup_client(payload.qr_code)
        return QrLookupResponse(
            id=client.id,
            full_name=client.full_name,
            phone=client.phone,
            current_bonus_balance=current_bonus_balance,
        )
    except QrFlowError as error:
        handle_qr_error(error)


@router.post("/orders/from-qr", response_model=QrOrderResponse, dependencies=[Depends(require_cashier_or_admin)])
def create_order_from_qr(payload: QrOrderCreate, db: Session = Depends(get_db)) -> QrOrderResponse:
    try:
        order, client, account = QrService(db).create_order_from_qr(
            qr_code=payload.qr_code,
            branch_id=payload.branch_id,
            total_amount=payload.total_amount,
            payment_method=payload.payment_method,
            use_bonuses=payload.use_bonuses,
        )
        return QrOrderResponse(
            order_id=order.id,
            client_full_name=client.full_name,
            total_amount=order.total_amount,
            bonus_spent=order.bonus_spent,
            bonus_earned=order.bonus_earned,
            final_amount=order.final_amount,
            new_bonus_balance=account.balance,
        )
    except QrFlowError as error:
        handle_qr_error(error)
