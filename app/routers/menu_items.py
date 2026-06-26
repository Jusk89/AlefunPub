from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin_or_owner
from app.models.audit import AuditAction
from app.models.menu import MenuCategory, MenuItem
from app.models.user import User
from app.schemas.menu import MenuItemCreate, MenuItemRead, MenuItemUpdate
from app.services.audit import AuditService
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/menu/items", tags=["menu items"])


def get_menu_item_or_404(db: Session, menu_item_id: int) -> MenuItem:
    return get_record_or_404(db, MenuItem, menu_item_id, "Menu item not found")


@router.get("", response_model=list[MenuItemRead])
def list_menu_items(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> list[MenuItem]:
    return list_records(db, MenuItem, skip=skip, limit=limit)


@router.post("", response_model=MenuItemRead, status_code=status.HTTP_201_CREATED)
def create_menu_item(
    payload: MenuItemCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> MenuItem:
    get_record_or_404(db, MenuCategory, payload.category_id, "Menu category not found")
    menu_item = create_record(db, MenuItem, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_item_created,
        actor_user_id=current_user.id,
        entity_type="menu_item",
        entity_id=menu_item.id,
    )
    return menu_item


@router.get("/{menu_item_id}", response_model=MenuItemRead)
def get_menu_item(menu_item_id: int, db: Session = Depends(get_db)) -> MenuItem:
    return get_menu_item_or_404(db, menu_item_id)


@router.patch("/{menu_item_id}", response_model=MenuItemRead)
def update_menu_item(
    menu_item_id: int,
    payload: MenuItemUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> MenuItem:
    menu_item = get_menu_item_or_404(db, menu_item_id)

    if payload.category_id is not None:
        get_record_or_404(db, MenuCategory, payload.category_id, "Menu category not found")

    menu_item = update_record(db, menu_item, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_item_updated,
        actor_user_id=current_user.id,
        entity_type="menu_item",
        entity_id=menu_item.id,
    )
    return menu_item


@router.delete("/{menu_item_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_menu_item(
    menu_item_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> Response:
    menu_item = get_menu_item_or_404(db, menu_item_id)
    delete_record(db, menu_item)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_item_deleted,
        actor_user_id=current_user.id,
        entity_type="menu_item",
        entity_id=menu_item_id,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
