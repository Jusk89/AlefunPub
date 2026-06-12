"""create notifications campaigns activity delivery audit

Revision ID: 202606120004
Revises: 202606120003
Create Date: 2026-06-12 00:04:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "202606120004"
down_revision: Union[str, None] = "202606120003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    campaign_target_group = postgresql.ENUM(
        "all_clients",
        "inactive_clients",
        "birthday_clients",
        "vip_clients",
        name="campaign_target_group",
        create_type=False,
    )
    delivery_status = postgresql.ENUM(
        "waiting",
        "assigned",
        "on_the_way",
        "delivered",
        "cancelled",
        name="delivery_status",
        create_type=False,
    )
    audit_action = postgresql.ENUM(
        "user_registered",
        "order_created",
        "order_completed",
        "bonus_earned",
        "bonus_spent",
        "campaign_created",
        name="audit_action",
        create_type=False,
    )

    bind = op.get_bind()
    campaign_target_group.create(bind, checkfirst=True)
    delivery_status.create(bind, checkfirst=True)
    audit_action.create(bind, checkfirst=True)

    op.create_table(
        "campaigns",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("message", sa.Text(), nullable=False),
        sa.Column("target_group", campaign_target_group, nullable=False),
        sa.Column("starts_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("ends_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_campaigns_id"), "campaigns", ["id"], unique=False)

    op.create_table(
        "push_tokens",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("token", sa.String(length=512), nullable=False),
        sa.Column("platform", sa.String(length=50), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("token", name="uq_push_tokens_token"),
    )
    op.create_index(op.f("ix_push_tokens_id"), "push_tokens", ["id"], unique=False)
    op.create_index(op.f("ix_push_tokens_user_id"), "push_tokens", ["user_id"], unique=False)

    op.create_table(
        "user_activities",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("last_visit_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("total_spent", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("total_orders", sa.Integer(), server_default="0", nullable=False),
        sa.Column("last_notification_sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", name="uq_user_activities_user_id"),
    )
    op.create_index(op.f("ix_user_activities_id"), "user_activities", ["id"], unique=False)
    op.create_index("ix_user_activities_last_visit_at", "user_activities", ["last_visit_at"], unique=False)
    op.create_index(op.f("ix_user_activities_user_id"), "user_activities", ["user_id"], unique=False)

    op.create_table(
        "addresses",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("label", sa.String(length=100), nullable=True),
        sa.Column("address_line", sa.String(length=500), nullable=False),
        sa.Column("city", sa.String(length=255), nullable=False),
        sa.Column("apartment", sa.String(length=50), nullable=True),
        sa.Column("entrance", sa.String(length=50), nullable=True),
        sa.Column("floor", sa.String(length=50), nullable=True),
        sa.Column("latitude", sa.Numeric(precision=9, scale=6), nullable=True),
        sa.Column("longitude", sa.Numeric(precision=9, scale=6), nullable=True),
        sa.Column("is_default", sa.Boolean(), server_default="false", nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_addresses_id"), "addresses", ["id"], unique=False)
    op.create_index("ix_addresses_user_default", "addresses", ["user_id", "is_default"], unique=False)
    op.create_index(op.f("ix_addresses_user_id"), "addresses", ["user_id"], unique=False)

    op.create_table(
        "audit_logs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("action", audit_action, nullable=False),
        sa.Column("actor_user_id", sa.Integer(), nullable=True),
        sa.Column("entity_type", sa.String(length=100), nullable=True),
        sa.Column("entity_id", sa.Integer(), nullable=True),
        sa.Column("details", sa.JSON(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["actor_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_audit_logs_action"), "audit_logs", ["action"], unique=False)
    op.create_index(op.f("ix_audit_logs_actor_user_id"), "audit_logs", ["actor_user_id"], unique=False)
    op.create_index("ix_audit_logs_entity", "audit_logs", ["entity_type", "entity_id"], unique=False)
    op.create_index(op.f("ix_audit_logs_id"), "audit_logs", ["id"], unique=False)

    op.create_table(
        "delivery_orders",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("order_id", sa.Integer(), nullable=False),
        sa.Column("address_id", sa.Integer(), nullable=False),
        sa.Column("courier_id", sa.Integer(), nullable=True),
        sa.Column("delivery_fee", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("delivery_status", delivery_status, server_default="waiting", nullable=False),
        sa.Column("estimated_delivery_time", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["address_id"], ["addresses.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["courier_id"], ["users.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("order_id", name="uq_delivery_orders_order_id"),
    )
    op.create_index(op.f("ix_delivery_orders_address_id"), "delivery_orders", ["address_id"], unique=False)
    op.create_index(op.f("ix_delivery_orders_courier_id"), "delivery_orders", ["courier_id"], unique=False)
    op.create_index(op.f("ix_delivery_orders_id"), "delivery_orders", ["id"], unique=False)
    op.create_index(op.f("ix_delivery_orders_order_id"), "delivery_orders", ["order_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_delivery_orders_order_id"), table_name="delivery_orders")
    op.drop_index(op.f("ix_delivery_orders_id"), table_name="delivery_orders")
    op.drop_index(op.f("ix_delivery_orders_courier_id"), table_name="delivery_orders")
    op.drop_index(op.f("ix_delivery_orders_address_id"), table_name="delivery_orders")
    op.drop_table("delivery_orders")

    op.drop_index(op.f("ix_audit_logs_id"), table_name="audit_logs")
    op.drop_index("ix_audit_logs_entity", table_name="audit_logs")
    op.drop_index(op.f("ix_audit_logs_actor_user_id"), table_name="audit_logs")
    op.drop_index(op.f("ix_audit_logs_action"), table_name="audit_logs")
    op.drop_table("audit_logs")

    op.drop_index(op.f("ix_addresses_user_id"), table_name="addresses")
    op.drop_index("ix_addresses_user_default", table_name="addresses")
    op.drop_index(op.f("ix_addresses_id"), table_name="addresses")
    op.drop_table("addresses")

    op.drop_index(op.f("ix_user_activities_user_id"), table_name="user_activities")
    op.drop_index("ix_user_activities_last_visit_at", table_name="user_activities")
    op.drop_index(op.f("ix_user_activities_id"), table_name="user_activities")
    op.drop_table("user_activities")

    op.drop_index(op.f("ix_push_tokens_user_id"), table_name="push_tokens")
    op.drop_index(op.f("ix_push_tokens_id"), table_name="push_tokens")
    op.drop_table("push_tokens")

    op.drop_index(op.f("ix_campaigns_id"), table_name="campaigns")
    op.drop_table("campaigns")

    bind = op.get_bind()
    postgresql.ENUM(
        "user_registered",
        "order_created",
        "order_completed",
        "bonus_earned",
        "bonus_spent",
        "campaign_created",
        name="audit_action",
        create_type=False,
    ).drop(bind, checkfirst=True)
    postgresql.ENUM(
        "waiting",
        "assigned",
        "on_the_way",
        "delivered",
        "cancelled",
        name="delivery_status",
        create_type=False,
    ).drop(bind, checkfirst=True)
    postgresql.ENUM(
        "all_clients",
        "inactive_clients",
        "birthday_clients",
        "vip_clients",
        name="campaign_target_group",
        create_type=False,
    ).drop(bind, checkfirst=True)
