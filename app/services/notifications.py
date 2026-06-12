import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.notification import PushToken

logger = logging.getLogger(__name__)


class NotificationService:
    """Placeholder notification service; real Firebase integration can replace this class."""

    def send_push(
        self,
        token: str,
        title: str,
        body: str,
        data: dict[str, str] | None = None,
    ) -> None:
        masked_token = f"{token[:6]}...{token[-4:]}" if len(token) > 10 else "***"
        payload = {"token": masked_token, "title": title, "body": body, "data": data or {}}
        logger.info("Placeholder push notification: %s", payload)
        print(f"Placeholder push notification: {payload}")


def register_push_token(db: Session, user_id: int, token: str, platform: str | None = None) -> PushToken:
    """Create or reactivate a device push token for a user."""
    push_token = db.scalar(select(PushToken).where(PushToken.token == token))
    if push_token is None:
        push_token = PushToken(user_id=user_id, token=token, platform=platform, is_active=True)
        db.add(push_token)
    else:
        push_token.user_id = user_id
        push_token.platform = platform
        push_token.is_active = True

    db.commit()
    db.refresh(push_token)
    return push_token
