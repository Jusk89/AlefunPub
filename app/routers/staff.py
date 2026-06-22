import uuid

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.dependencies import require_admin_or_owner
from app.models.audit import AuditAction
from app.models.branch import Branch
from app.models.user import User, UserRole
from app.schemas.staff import StaffCreate, StaffRead, StaffUpdate
from app.services.audit import AuditService
from app.services.security import hash_password
from app.services.users import get_user_by_email, get_user_by_phone

router = APIRouter(prefix="/staff", tags=["staff"])

STAFF_ROLES = {UserRole.owner, UserRole.admin, UserRole.cashier, UserRole.courier}
ADMIN_MANAGED_ROLES = {UserRole.cashier, UserRole.courier}
OWNER_CREATABLE_ROLES = {UserRole.admin, UserRole.cashier, UserRole.courier}


def _get_staff_or_404(db: Session, staff_id: int) -> User:
    staff = db.get(User, staff_id)
    if staff is None or staff.role not in STAFF_ROLES:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Staff user not found")
    return staff


def _ensure_unique_identity(db: Session, email: str | None, phone: str | None, user_id: int | None = None) -> None:
    if email:
        existing = get_user_by_email(db, email)
        if existing is not None and existing.id != user_id:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")
    if phone:
        existing = get_user_by_phone(db, phone)
        if existing is not None and existing.id != user_id:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Phone is already registered")


def _ensure_branch_exists(db: Session, branch_id: int | None) -> None:
    if branch_id is not None and db.get(Branch, branch_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Branch not found")


def _ensure_can_create(actor: User, role: UserRole) -> None:
    if role == UserRole.client or role == UserRole.owner:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid staff role")
    if actor.role == UserRole.owner and role in OWNER_CREATABLE_ROLES:
        return
    if actor.role == UserRole.admin and role in ADMIN_MANAGED_ROLES:
        return
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to create this role")


def _ensure_can_manage(actor: User, target: User, next_role: UserRole | None = None) -> None:
    role_to_validate = next_role or target.role
    if target.role == UserRole.owner:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Owner account cannot be managed here")
    if actor.role == UserRole.owner:
        if role_to_validate in OWNER_CREATABLE_ROLES:
            return
    if actor.role == UserRole.admin:
        if target.role in ADMIN_MANAGED_ROLES and role_to_validate in ADMIN_MANAGED_ROLES:
            return
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Not allowed to manage this staff user")


@router.post("", response_model=StaffRead, status_code=status.HTTP_201_CREATED)
def create_staff(
    payload: StaffCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> User:
    _ensure_can_create(current_user, payload.role)
    _ensure_unique_identity(db, payload.email, payload.phone)
    _ensure_branch_exists(db, payload.branch_id)

    staff = User(
        full_name=payload.full_name,
        phone=payload.phone,
        email=payload.email.lower(),
        password_hash=hash_password(payload.password),
        role=payload.role,
        branch_id=payload.branch_id,
        created_by_user_id=current_user.id,
        qr_code=str(uuid.uuid4()) if payload.role == UserRole.client else None,
    )
    db.add(staff)
    db.flush()
    AuditService(db).write_log(
        AuditAction.staff_created,
        actor_user_id=current_user.id,
        entity_type="user",
        entity_id=staff.id,
        details={"role": staff.role.value, "branch_id": staff.branch_id},
    )
    db.commit()
    db.refresh(staff)
    return staff


@router.get("", response_model=list[StaffRead])
def list_staff(
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> list[User]:
    statement = select(User).where(User.role.in_(list(STAFF_ROLES))).order_by(User.id)
    staff = list(db.scalars(statement))
    if current_user.role == UserRole.admin:
        staff = [user for user in staff if user.role in ADMIN_MANAGED_ROLES]
    return staff


@router.get("/{staff_id}", response_model=StaffRead)
def get_staff(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> User:
    staff = _get_staff_or_404(db, staff_id)
    _ensure_can_manage(current_user, staff)
    return staff


@router.patch("/{staff_id}", response_model=StaffRead)
def update_staff(
    staff_id: int,
    payload: StaffUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> User:
    staff = _get_staff_or_404(db, staff_id)
    _ensure_can_manage(current_user, staff, payload.role)
    _ensure_unique_identity(db, str(payload.email) if payload.email else None, payload.phone, staff.id)
    _ensure_branch_exists(db, payload.branch_id)

    data = payload.model_dump(exclude_unset=True)
    password = data.pop("password", None)
    if password is not None:
        staff.password_hash = hash_password(password)
    if "email" in data and data["email"] is not None:
        data["email"] = str(data["email"]).lower()
    for field, value in data.items():
        setattr(staff, field, value)

    AuditService(db).write_log(
        AuditAction.staff_updated,
        actor_user_id=current_user.id,
        entity_type="user",
        entity_id=staff.id,
        details={key: str(value) for key, value in data.items()},
    )
    db.commit()
    db.refresh(staff)
    return staff


@router.patch("/{staff_id}/deactivate", response_model=StaffRead)
def deactivate_staff(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> User:
    staff = _get_staff_or_404(db, staff_id)
    _ensure_can_manage(current_user, staff)
    staff.is_active = False
    AuditService(db).write_log(
        AuditAction.staff_deactivated,
        actor_user_id=current_user.id,
        entity_type="user",
        entity_id=staff.id,
    )
    db.commit()
    db.refresh(staff)
    return staff


@router.patch("/{staff_id}/activate", response_model=StaffRead)
def activate_staff(
    staff_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_admin_or_owner),
) -> User:
    staff = _get_staff_or_404(db, staff_id)
    _ensure_can_manage(current_user, staff)
    staff.is_active = True
    AuditService(db).write_log(
        AuditAction.staff_activated,
        actor_user_id=current_user.id,
        entity_type="user",
        entity_id=staff.id,
    )
    db.commit()
    db.refresh(staff)
    return staff
