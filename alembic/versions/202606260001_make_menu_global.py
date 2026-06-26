"""make menu categories and items global

Revision ID: 202606260001
Revises: 202606240001
Create Date: 2026-06-26 00:01:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "202606260001"
down_revision: Union[str, None] = "202606240001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Remove restaurant ownership from menu tables.

    Menu categories and dishes are shared across the restaurant network. Orders,
    branches, bonuses, and QR flow still keep their restaurant linkage.
    """
    op.drop_index(op.f("ix_menu_items_restaurant_id"), table_name="menu_items")
    op.drop_constraint("menu_items_restaurant_id_fkey", "menu_items", type_="foreignkey")
    op.drop_column("menu_items", "restaurant_id")

    op.drop_index(op.f("ix_menu_categories_restaurant_id"), table_name="menu_categories")
    op.drop_constraint("menu_categories_restaurant_id_fkey", "menu_categories", type_="foreignkey")
    op.drop_column("menu_categories", "restaurant_id")


def downgrade() -> None:
    """Restore restaurant ownership for menu tables."""
    op.add_column("menu_categories", sa.Column("restaurant_id", sa.Integer(), nullable=True))
    op.add_column("menu_items", sa.Column("restaurant_id", sa.Integer(), nullable=True))

    # Rollback needs a restaurant id for existing menu rows. Use the first
    # restaurant when available, matching the old single-restaurant behavior.
    op.execute(
        """
        UPDATE menu_categories
        SET restaurant_id = (SELECT id FROM restaurants ORDER BY id LIMIT 1)
        WHERE restaurant_id IS NULL
        """
    )
    op.execute(
        """
        UPDATE menu_items
        SET restaurant_id = (SELECT id FROM restaurants ORDER BY id LIMIT 1)
        WHERE restaurant_id IS NULL
        """
    )

    op.alter_column("menu_categories", "restaurant_id", nullable=False)
    op.alter_column("menu_items", "restaurant_id", nullable=False)

    op.create_foreign_key(
        "menu_categories_restaurant_id_fkey",
        "menu_categories",
        "restaurants",
        ["restaurant_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(op.f("ix_menu_categories_restaurant_id"), "menu_categories", ["restaurant_id"], unique=False)

    op.create_foreign_key(
        "menu_items_restaurant_id_fkey",
        "menu_items",
        "restaurants",
        ["restaurant_id"],
        ["id"],
        ondelete="CASCADE",
    )
    op.create_index(op.f("ix_menu_items_restaurant_id"), "menu_items", ["restaurant_id"], unique=False)
