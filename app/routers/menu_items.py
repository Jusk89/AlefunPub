from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.menu import MenuCategory, MenuItem
from app.models.restaurant import Restaurant
from app.schemas.menu import MenuItemCreate, MenuItemRead, MenuItemUpdate
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/menu-items", tags=["menu items"])


def get_menu_item_or_404(db: Session, menu_item_id: int) -> MenuItem:
    return get_record_or_404(db, MenuItem, menu_item_id, "Menu item not found")


def ensure_category_matches_restaurant(db: Session, category_id: int, restaurant_id: int) -> None:
    category = get_record_or_404(db, MenuCategory, category_id, "Menu category not found")
    if category.restaurant_id != restaurant_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Menu category does not belong to this restaurant",
        )


@router.get("", response_model=list[MenuItemRead])
def list_menu_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> list[MenuItem]:
    return list_records(db, MenuItem, skip=skip, limit=limit)


@router.post("", response_model=MenuItemRead, status_code=status.HTTP_201_CREATED)
def create_menu_item(payload: MenuItemCreate, db: Session = Depends(get_db)) -> MenuItem:
    get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    ensure_category_matches_restaurant(db, payload.category_id, payload.restaurant_id)
    return create_record(db, MenuItem, payload)


@router.get("/{menu_item_id}", response_model=MenuItemRead)
def get_menu_item(menu_item_id: int, db: Session = Depends(get_db)) -> MenuItem:
    return get_menu_item_or_404(db, menu_item_id)


@router.patch("/{menu_item_id}", response_model=MenuItemRead)
def update_menu_item(
    menu_item_id: int,
    payload: MenuItemUpdate,
    db: Session = Depends(get_db),
) -> MenuItem:
    menu_item = get_menu_item_or_404(db, menu_item_id)
    restaurant_id = payload.restaurant_id if payload.restaurant_id is not None else menu_item.restaurant_id
    category_id = payload.category_id if payload.category_id is not None else menu_item.category_id

    if payload.restaurant_id is not None:
        get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    ensure_category_matches_restaurant(db, category_id, restaurant_id)

    return update_record(db, menu_item, payload)


@router.delete("/{menu_item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_menu_item(menu_item_id: int, db: Session = Depends(get_db)) -> Response:
    menu_item = get_menu_item_or_404(db, menu_item_id)
    delete_record(db, menu_item)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
