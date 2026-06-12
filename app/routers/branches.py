from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.branch import Branch
from app.models.restaurant import Restaurant
from app.schemas.branch import BranchCreate, BranchRead, BranchUpdate
from app.services.crud import create_record, delete_record, get_record_or_404, list_records, update_record

router = APIRouter(prefix="/branches", tags=["branches"])


def get_branch_or_404(db: Session, branch_id: int) -> Branch:
    return get_record_or_404(db, Branch, branch_id, "Branch not found")


@router.get("", response_model=list[BranchRead])
def list_branches(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)) -> list[Branch]:
    return list_records(db, Branch, skip=skip, limit=limit)


@router.post("", response_model=BranchRead, status_code=status.HTTP_201_CREATED)
def create_branch(payload: BranchCreate, db: Session = Depends(get_db)) -> Branch:
    get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    return create_record(db, Branch, payload)


@router.get("/{branch_id}", response_model=BranchRead)
def get_branch(branch_id: int, db: Session = Depends(get_db)) -> Branch:
    return get_branch_or_404(db, branch_id)


@router.patch("/{branch_id}", response_model=BranchRead)
def update_branch(branch_id: int, payload: BranchUpdate, db: Session = Depends(get_db)) -> Branch:
    branch = get_branch_or_404(db, branch_id)
    if payload.restaurant_id is not None:
        get_record_or_404(db, Restaurant, payload.restaurant_id, "Restaurant not found")
    return update_record(db, branch, payload)


@router.delete("/{branch_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_branch(branch_id: int, db: Session = Depends(get_db)) -> Response:
    branch = get_branch_or_404(db, branch_id)
    delete_record(db, branch)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
