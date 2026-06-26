from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin_or_owner
from app.models.audit import AuditAction
from app.models.menu import MenuCategory
from app.schemas.menu import MenuCategoryCreate, MenuCategoryRead, MenuCategoryUpdate
from app.models.user import User
from app.services.audit import AuditService
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/menu/categories", tags=["menu categories"])


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
def create_menu_category(
    payload: MenuCategoryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> MenuCategory:
    category = create_record(db, MenuCategory, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_category_created,
        actor_user_id=current_user.id,
        entity_type="menu_category",
        entity_id=category.id,
    )
    return category


@router.get("/{category_id}", response_model=MenuCategoryRead)
def get_menu_category(category_id: int, db: Session = Depends(get_db)) -> MenuCategory:
    return get_category_or_404(db, category_id)


@router.patch("/{category_id}", response_model=MenuCategoryRead)
def update_menu_category(
    category_id: int,
    payload: MenuCategoryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> MenuCategory:
    category = get_category_or_404(db, category_id)
    category = update_record(db, category, payload)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_category_updated,
        actor_user_id=current_user.id,
        entity_type="menu_category",
        entity_id=category.id,
    )
    return category


@router.delete("/{category_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_menu_category(
    category_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> Response:
    category = get_category_or_404(db, category_id)
    delete_record(db, category)
    AuditService(db, auto_commit=True).write_log(
        AuditAction.menu_category_deleted,
        actor_user_id=current_user.id,
        entity_type="menu_category",
        entity_id=category_id,
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
