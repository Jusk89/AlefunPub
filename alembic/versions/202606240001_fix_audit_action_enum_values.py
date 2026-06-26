"""ensure PostgreSQL enum values match Python models

Revision ID: 202606240001
Revises: fe6f5488fb10
Create Date: 2026-06-24 00:01:00.000000
"""

from typing import Sequence, Union

from alembic import op

revision: str = "202606240001"
down_revision: Union[str, None] = "fe6f5488fb10"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


ENUM_VALUES = {
    "user_role": (
        "client",
        "admin",
        "cashier",
        "courier",
        "owner",
    ),
    "audit_action": (
        "user_registered",
        "staff_created",
        "staff_updated",
        "staff_deactivated",
        "staff_activated",
        "order_created",
        "order_completed",
        "order_created_from_qr",
        "bonus_earned",
        "bonus_spent",
        "bonus_earned_from_qr",
        "bonus_spent_from_qr",
        "campaign_created",
        "campaign_updated",
        "campaign_deleted",
        "menu_category_created",
        "menu_category_updated",
        "menu_category_deleted",
        "menu_item_created",
        "menu_item_updated",
        "menu_item_deleted",
    ),
    "order_type": (
        "in_restaurant",
        "dine_in",
        "pickup",
        "delivery",
    ),
    "order_status": (
        "pending",
        "confirmed",
        "preparing",
        "ready",
        "delivering",
        "completed",
        "cancelled",
    ),
    "payment_method": (
        "cash",
        "card",
        "online",
        "mixed",
    ),
    "payment_status": (
        "pending",
        "paid",
        "failed",
        "refunded",
    ),
    "bonus_transaction_type": (
        "earn",
        "spend",
        "expire",
        "manual",
    ),
    "campaign_target_group": (
        "all_clients",
        "inactive_clients",
        "birthday_clients",
        "vip_clients",
    ),
    "delivery_status": (
        "waiting",
        "assigned",
        "on_the_way",
        "delivered",
        "cancelled",
    ),
}


def upgrade() -> None:
    for enum_name, values in ENUM_VALUES.items():
        for value in values:
            op.execute(f"ALTER TYPE {enum_name} ADD VALUE IF NOT EXISTS '{value}'")


def downgrade() -> None:
    # PostgreSQL enum values cannot be removed safely without recreating the type.
    pass
