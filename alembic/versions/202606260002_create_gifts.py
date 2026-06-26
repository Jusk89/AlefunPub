"""create gifts

Revision ID: 202606260002
Revises: 202606260001
Create Date: 2026-06-26 00:02:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "202606260002"
down_revision: Union[str, None] = "202606260001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "gifts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=255), nullable=False),
        sa.Column("description", sa.Text(), nullable=False),
        sa.Column("image_url", sa.String(length=2048), nullable=True),
        sa.Column("is_active", sa.Boolean(), server_default="true", nullable=False),
        sa.Column("created_by_user_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["created_by_user_id"], ["users.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_gifts_id"), "gifts", ["id"], unique=False)
    op.create_index(op.f("ix_gifts_created_by_user_id"), "gifts", ["created_by_user_id"], unique=False)

    op.create_table(
        "gift_redemptions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("gift_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("used_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["gift_id"], ["gifts.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("gift_id", "user_id", name="uq_gift_redemptions_gift_user"),
    )
    op.create_index(op.f("ix_gift_redemptions_id"), "gift_redemptions", ["id"], unique=False)
    op.create_index(op.f("ix_gift_redemptions_gift_id"), "gift_redemptions", ["gift_id"], unique=False)
    op.create_index(op.f("ix_gift_redemptions_user_id"), "gift_redemptions", ["user_id"], unique=False)
    op.create_index("ix_gift_redemptions_user_used", "gift_redemptions", ["user_id", "used_at"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_gift_redemptions_user_used", table_name="gift_redemptions")
    op.drop_index(op.f("ix_gift_redemptions_user_id"), table_name="gift_redemptions")
    op.drop_index(op.f("ix_gift_redemptions_gift_id"), table_name="gift_redemptions")
    op.drop_index(op.f("ix_gift_redemptions_id"), table_name="gift_redemptions")
    op.drop_table("gift_redemptions")
    op.drop_index(op.f("ix_gifts_created_by_user_id"), table_name="gifts")
    op.drop_index(op.f("ix_gifts_id"), table_name="gifts")
    op.drop_table("gifts")
