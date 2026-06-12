"""create restaurant menu order tables

Revision ID: 202606120002
Revises: 202606120001
Create Date: 2026-06-12 00:02:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "202606120002"
down_revision: Union[str, None] = "202606120001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    order_type = postgresql.ENUM("dine_in", "pickup", "delivery", name="order_type", create_type=False)
    order_status = postgresql.ENUM(
        "pending",
        "confirmed",
        "preparing",
        "ready",
        "delivering",
        "completed",
        "cancelled",
        name="order_status",
        create_type=False,
    )
    payment_method = postgresql.ENUM("cash", "card", "online", "mixed", name="payment_method", create_type=False)
    payment_status = postgresql.ENUM(
        "pending",
        "paid",
        "failed",
        "refunded",
        name="payment_status",
        create_type=False,
    )

    bind = op.get_bind()
    order_type.create(bind, checkfirst=True)
    order_status.create(bind, checkfirst=True)
    payment_method.create(bind, checkfirst=True)
    payment_status.create(bind, checkfirst=True)

    op.create_table(
        "restaurants",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("logo_url", sa.String(length=2048), nullable=True),
        sa.Column("bonus_percent", sa.Numeric(precision=5, scale=2), server_default="0", nullable=False),
        sa.Column("bonus_expiration_days", sa.Integer(), server_default="0", nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_restaurants_id"), "restaurants", ["id"], unique=False)

    op.create_table(
        "branches",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("phone", sa.String(length=32), nullable=True),
        sa.Column("latitude", sa.Numeric(precision=9, scale=6), nullable=True),
        sa.Column("longitude", sa.Numeric(precision=9, scale=6), nullable=True),
        sa.Column("opening_time", sa.Time(), nullable=True),
        sa.Column("closing_time", sa.Time(), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_branches_id"), "branches", ["id"], unique=False)
    op.create_index(op.f("ix_branches_restaurant_id"), "branches", ["restaurant_id"], unique=False)

    op.create_table(
        "menu_categories",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("sort_order", sa.Integer(), server_default="0", nullable=False),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_menu_categories_id"), "menu_categories", ["id"], unique=False)
    op.create_index(op.f("ix_menu_categories_restaurant_id"), "menu_categories", ["restaurant_id"], unique=False)

    op.create_table(
        "menu_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("category_id", sa.Integer(), nullable=False),
        sa.Column("name", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=True),
        sa.Column("price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("image_url", sa.String(length=2048), nullable=True),
        sa.Column("is_available", sa.Boolean(), server_default="true", nullable=False),
        sa.ForeignKeyConstraint(["category_id"], ["menu_categories.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_menu_items_category_id"), "menu_items", ["category_id"], unique=False)
    op.create_index(op.f("ix_menu_items_id"), "menu_items", ["id"], unique=False)
    op.create_index(op.f("ix_menu_items_restaurant_id"), "menu_items", ["restaurant_id"], unique=False)

    op.create_table(
        "orders",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("branch_id", sa.Integer(), nullable=False),
        sa.Column("order_type", order_type, nullable=False),
        sa.Column("status", order_status, server_default="pending", nullable=False),
        sa.Column("total_amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("bonus_earned", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("bonus_spent", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("final_amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("payment_method", payment_method, nullable=False),
        sa.Column("payment_status", payment_status, server_default="pending", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["branch_id"], ["branches.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_orders_branch_id"), "orders", ["branch_id"], unique=False)
    op.create_index(op.f("ix_orders_id"), "orders", ["id"], unique=False)
    op.create_index(op.f("ix_orders_restaurant_id"), "orders", ["restaurant_id"], unique=False)
    op.create_index(op.f("ix_orders_user_id"), "orders", ["user_id"], unique=False)

    op.create_table(
        "order_items",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("order_id", sa.Integer(), nullable=False),
        sa.Column("menu_item_id", sa.Integer(), nullable=False),
        sa.Column("name_snapshot", sa.String(length=255), nullable=False),
        sa.Column("price_snapshot", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("quantity", sa.Integer(), nullable=False),
        sa.Column("total_price", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.ForeignKeyConstraint(["menu_item_id"], ["menu_items.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_order_items_id"), "order_items", ["id"], unique=False)
    op.create_index(op.f("ix_order_items_menu_item_id"), "order_items", ["menu_item_id"], unique=False)
    op.create_index(op.f("ix_order_items_order_id"), "order_items", ["order_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_order_items_order_id"), table_name="order_items")
    op.drop_index(op.f("ix_order_items_menu_item_id"), table_name="order_items")
    op.drop_index(op.f("ix_order_items_id"), table_name="order_items")
    op.drop_table("order_items")

    op.drop_index(op.f("ix_orders_user_id"), table_name="orders")
    op.drop_index(op.f("ix_orders_restaurant_id"), table_name="orders")
    op.drop_index(op.f("ix_orders_id"), table_name="orders")
    op.drop_index(op.f("ix_orders_branch_id"), table_name="orders")
    op.drop_table("orders")

    op.drop_index(op.f("ix_menu_items_restaurant_id"), table_name="menu_items")
    op.drop_index(op.f("ix_menu_items_id"), table_name="menu_items")
    op.drop_index(op.f("ix_menu_items_category_id"), table_name="menu_items")
    op.drop_table("menu_items")

    op.drop_index(op.f("ix_menu_categories_restaurant_id"), table_name="menu_categories")
    op.drop_index(op.f("ix_menu_categories_id"), table_name="menu_categories")
    op.drop_table("menu_categories")

    op.drop_index(op.f("ix_branches_restaurant_id"), table_name="branches")
    op.drop_index(op.f("ix_branches_id"), table_name="branches")
    op.drop_table("branches")

    op.drop_index(op.f("ix_restaurants_id"), table_name="restaurants")
    op.drop_table("restaurants")

    bind = op.get_bind()
    postgresql.ENUM(
        "pending",
        "paid",
        "failed",
        "refunded",
        name="payment_status",
        create_type=False,
    ).drop(bind, checkfirst=True)
    postgresql.ENUM("cash", "card", "online", "mixed", name="payment_method", create_type=False).drop(
        bind,
        checkfirst=True,
    )
    postgresql.ENUM(
        "pending",
        "confirmed",
        "preparing",
        "ready",
        "delivering",
        "completed",
        "cancelled",
        name="order_status",
        create_type=False,
    ).drop(bind, checkfirst=True)
    postgresql.ENUM("dine_in", "pickup", "delivery", name="order_type", create_type=False).drop(
        bind,
        checkfirst=True,
    )
