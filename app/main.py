from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

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
    orders,
    qr,
    restaurants,
    staff,
    upload,
)
from app.services.activity import register_order_activity_events
from app.services.bonuses import register_order_bonus_events

app = FastAPI(title=settings.app_name, debug=settings.debug)
Path("uploads").mkdir(parents=True, exist_ok=True)
register_order_bonus_events()
register_order_activity_events()

app.include_router(auth.router)
app.include_router(staff.router)
app.include_router(restaurants.router)
app.include_router(branches.router)
app.include_router(menu_categories.router)
app.include_router(menu_items.router)
app.include_router(bonuses.router)
app.include_router(campaigns.router)
app.include_router(notifications.router)
app.include_router(orders.router)
app.include_router(activity.router)
app.include_router(addresses.router)
app.include_router(qr.router)
app.include_router(upload.router)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.get("/health", tags=["health"])
def health_check() -> dict[str, str]:
    return {"status": "ok"}
