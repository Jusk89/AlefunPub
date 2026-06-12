from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.menu import MenuCategory
from app.models.restaurant import Restaurant
from app.schemas.menu import MenuCategoryCreate, MenuCategoryRead, MenuCategoryUpdate
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/menu-categories", tags=["menu categories"])


def get_category_or_404(db: Session, category_id: int) -> MenuCategory:
    return get_record_or_404(db, MenuCategory, category_id, "Menu category not found")


@router.get("", response_model=list[MenuCategoryRead])
def list_menu_categories(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
) -> list[MenuCategory]:
    return list_records(db, MenuCategory, skip=skip, limit=limit)


@router.post("", response_model=MenuCategoryRead, status_code=status.HTTP_201_CREATED)
def create_menu_category(payload: MenuCategoryCreate, db: Session = Depends(get_db)) -> MenuCategory:
    get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    return create_record(db, MenuCategory, payload)


@router.get("/{category_id}", response_model=MenuCategoryRead)
def get_menu_category(category_id: int, db: Session = Depends(get_db)) -> MenuCategory:
    return get_category_or_404(db, category_id)


@router.patch("/{category_id}", response_model=MenuCategoryRead)
def update_menu_category(
    category_id: int,
    payload: MenuCategoryUpdate,
    db: Session = Depends(get_db),
) -> MenuCategory:
    category = get_category_or_404(db, category_id)
    if payload.restaurant_id is not None:
        get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    return update_record(db, category, payload)


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_menu_category(category_id: int, db: Session = Depends(get_db)) -> Response:
    category = get_category_or_404(db, category_id)
    delete_record(db, category)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
