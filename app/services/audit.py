from typing import Any

from sqlalchemy.orm import Session

from app.models.audit import AuditAction, AuditLog


class AuditService:
    """Append-only audit log writer for important system actions."""

    def __init__(self, db: Session, auto_commit: bool = False) -> None:
        self.db = db
        self.auto_commit = auto_commit

    def write_log(
        self,
        action: AuditAction,
        actor_user_id: int | None = None,
        entity_type: str | None = None,
        entity_id: int | None = None,
        details: dict[str, Any] | None = None,
    ) -> AuditLog:
        """Persist one audit log record."""
        log = AuditLog(
            action=action,
            actor_user_id=actor_user_id,
            entity_type=entity_type,
            entity_id=entity_id,
            details=details,
        )
        self.db.add(log)
        if self.auto_commit:
            self.db.commit()
            self.db.refresh(log)
        elif not getattr(self.db, "_flushing", False):
            self.db.flush()
        return log
