from typing import Any, TypeVar

from pydantic import BaseModel
from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

ModelT = TypeVar("ModelT")


def list_records(db: Session, model: type[ModelT], skip: int = 0, limit: int = 100) -> list[ModelT]:
    """Return a simple paginated list for small CRUD endpoints."""
    statement = select(model).offset(skip).limit(limit)
    return list(db.scalars(statement).all())


def get_record(db: Session, model: type[ModelT], record_id: int) -> ModelT | None:
    """Fetch one ORM record by primary key."""
    return db.get(model, record_id)


def get_record_or_404(db: Session, model: type[ModelT], record_id: int, detail: str) -> ModelT:
    """Fetch one ORM record or raise the standard API 404 response."""
    record = get_record(db, model, record_id)
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=detail)
    return record


def create_record(db: Session, model: type[ModelT], payload: BaseModel) -> ModelT:
    """Create an ORM record from a Pydantic payload and commit it."""
    record = model(**payload.model_dump())
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def update_record(db: Session, record: ModelT, payload: BaseModel) -> ModelT:
    """Patch an ORM record with fields explicitly sent by the client."""
    update_data: dict[str, Any] = payload.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(record, field, value)

    db.add(record)
    db.commit()
    db.refresh(record)
    return record


def delete_record(db: Session, record: ModelT) -> None:
    """Delete an ORM record and commit the transaction."""
    db.delete(record)
    db.commit()
