from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import get_current_user
from app.models.address import Address
from app.models.user import User
from app.schemas.address import AddressCreate, AddressRead, AddressUpdate
from app.services.crud import delete_record, update_record

router = APIRouter(prefix="/addresses", tags=["addresses"])


def get_own_address_or_404(db: Session, user_id: int, address_id: int) -> Address:
    address = db.scalar(select(Address).where(Address.id == address_id, Address.user_id == user_id))
    if address is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Address not found")
    return address


def clear_default_addresses(db: Session, user_id: int) -> None:
    addresses = db.scalars(select(Address).where(Address.user_id == user_id, Address.is_default.is_(True))).all()
    for address in addresses:
        address.is_default = False


@router.get("", response_model=list[AddressRead])
def list_addresses(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> list[Address]:
    return list(db.scalars(select(Address).where(Address.user_id == current_user.id)).all())


@router.post("", response_model=AddressRead, status_code=status.HTTP_201_CREATED)
def create_address(
    payload: AddressCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Address:
    if payload.is_default:
        clear_default_addresses(db, current_user.id)

    address = Address(user_id=current_user.id, **payload.model_dump())
    db.add(address)
    db.commit()
    db.refresh(address)
    return address


@router.get("/{address_id}", response_model=AddressRead)
def get_address(
    address_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Address:
    return get_own_address_or_404(db, current_user.id, address_id)


@router.patch("/{address_id}", response_model=AddressRead)
def update_address(
    address_id: int,
    payload: AddressUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Address:
    address = get_own_address_or_404(db, current_user.id, address_id)
    if payload.is_default:
        clear_default_addresses(db, current_user.id)
    return update_record(db, address, payload)


@router.delete("/{address_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_address(
    address_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    address = get_own_address_or_404(db, current_user.id, address_id)
    delete_record(db, address)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
