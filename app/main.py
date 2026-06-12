from fastapi import FastAPI

from app.config import settings
from app.routers import (
    activity,
    addresses,
    auth,
    bonuses,
    branches,
    campaigns,
    menu_categories,
    menu_items,
    notifications,
    qr,
    restaurants,
)
from app.services.activity import register_order_activity_events
from app.services.bonuses import register_order_bonus_events

app = FastAPI(title=settings.app_name, debug=settings.debug)
register_order_bonus_events()
register_order_activity_events()

app.include_router(auth.router)
app.include_router(restaurants.router)
app.include_router(branches.router)
app.include_router(menu_categories.router)
app.include_router(menu_items.router)
app.include_router(bonuses.router)
app.include_router(campaigns.router)
app.include_router(notifications.router)
app.include_router(activity.router)
app.include_router(addresses.router)
app.include_router(qr.router)


@app.get("/health", tags=["health"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}
