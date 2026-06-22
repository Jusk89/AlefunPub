"""add staff management and campaign admin fields

Revision ID: 202606120006
Revises: 202606120005
Create Date: 2026-06-12 00:06:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "202606120006"
down_revision: Union[str, None] = "202606120005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


AUDIT_ACTIONS = [
    "staff_created",
    "staff_updated",
    "staff_deactivated",
    "staff_activated",
    "campaign_updated",
    "campaign_deleted",
    "menu_category_created",
    "menu_category_updated",
    "menu_category_deleted",
    "menu_item_created",
    "menu_item_updated",
    "menu_item_deleted",
]


def upgrade() -> None:
    op.execute("ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'owner'")
    for action in AUDIT_ACTIONS:
        op.execute(f"ALTER TYPE audit_action ADD VALUE IF NOT EXISTS '{action}'")
    op.alter_column("restaurants", "bonus_percent", server_default="5")
    op.execute("UPDATE restaurants SET bonus_percent = 5 WHERE bonus_percent = 0")

    op.add_column("users", sa.Column("branch_id", sa.Integer(), nullable=True))
    op.add_column("users", sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False))
    op.add_column("users", sa.Column("last_login_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("created_by_user_id", sa.Integer(), nullable=True))
    op.create_index(op.f("ix_users_branch_id"), "users", ["branch_id"], unique=False)
    op.create_index(op.f("ix_users_created_by_user_id"), "users", ["created_by_user_id"], unique=False)
    op.create_foreign_key(
        "fk_users_branch_id_branches",
        "users",
        "branches",
        ["branch_id"],
        ["id"],
        ondelete="SET NULL",
    )
    op.create_foreign_key(
        "fk_users_created_by_user_id_users",
        "users",
        "users",
        ["created_by_user_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.drop_constraint("audit_logs_actor_user_id_fkey", "audit_logs", type_="foreignkey")
    op.drop_index(op.f("ix_audit_logs_actor_user_id"), table_name="audit_logs")
    op.alter_column("audit_logs", "actor_user_id", new_column_name="user_id")
    op.create_index(op.f("ix_audit_logs_user_id"), "audit_logs", ["user_id"], unique=False)
    op.create_foreign_key(
        "fk_audit_logs_user_id_users",
        "audit_logs",
        "users",
        ["user_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.alter_column("campaigns", "message", new_column_name="description")
    op.alter_column("campaigns", "starts_at", new_column_name="start_date")
    op.alter_column("campaigns", "ends_at", new_column_name="end_date")
    op.add_column("campaigns", sa.Column("image_url", sa.String(length=2048), nullable=True))
    op.add_column("campaigns", sa.Column("created_by_user_id", sa.Integer(), nullable=True))
    op.add_column(
        "campaigns",
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index(
        op.f("ix_campaigns_created_by_user_id"),
        "campaigns",
        ["created_by_user_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_campaigns_created_by_user_id_users",
        "campaigns",
        "users",
        ["created_by_user_id"],
        ["id"],
        ondelete="SET NULL",
    )


def downgrade() -> None:
    op.alter_column("restaurants", "bonus_percent", server_default="0")
    op.drop_constraint("fk_campaigns_created_by_user_id_users", "campaigns", type_="foreignkey")
    op.drop_index(op.f("ix_campaigns_created_by_user_id"), table_name="campaigns")
    op.drop_column("campaigns", "updated_at")
    op.drop_column("campaigns", "created_by_user_id")
    op.drop_column("campaigns", "image_url")
    op.alter_column("campaigns", "end_date", new_column_name="ends_at")
    op.alter_column("campaigns", "start_date", new_column_name="starts_at")
    op.alter_column("campaigns", "description", new_column_name="message")

    op.drop_constraint("fk_audit_logs_user_id_users", "audit_logs", type_="foreignkey")
    op.drop_index(op.f("ix_audit_logs_user_id"), table_name="audit_logs")
    op.alter_column("audit_logs", "user_id", new_column_name="actor_user_id")
    op.create_index(op.f("ix_audit_logs_actor_user_id"), "audit_logs", ["actor_user_id"], unique=False)
    op.create_foreign_key(
        "audit_logs_actor_user_id_fkey",
        "audit_logs",
        "users",
        ["actor_user_id"],
        ["id"],
        ondelete="SET NULL",
    )

    op.drop_constraint("fk_users_created_by_user_id_users", "users", type_="foreignkey")
    op.drop_constraint("fk_users_branch_id_branches", "users", type_="foreignkey")
    op.drop_index(op.f("ix_users_created_by_user_id"), table_name="users")
    op.drop_index(op.f("ix_users_branch_id"), table_name="users")
    op.drop_column("users", "created_by_user_id")
    op.drop_column("users", "last_login_at")
    op.drop_column("users", "is_active")
    op.drop_column("users", "branch_id")
    # PostgreSQL enum values cannot be removed safely without recreating enum types.
