"""add permanent qr loyalty flow

Revision ID: 202606120005
Revises: 202606120004
Create Date: 2026-06-12 00:05:00.000000
"""

from typing import Sequence, Union
import uuid

from alembic import op
import sqlalchemy as sa

revision: str = "202606120005"
down_revision: Union[str, None] = "202606120004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("users", sa.Column("qr_code", sa.String(length=36), nullable=True))

    bind = op.get_bind()
    client_rows = bind.execute(
        sa.text("SELECT id FROM users WHERE role = 'client' AND qr_code IS NULL")
    ).fetchall()
    for row in client_rows:
        bind.execute(
            sa.text("UPDATE users SET qr_code = :qr_code WHERE id = :user_id"),
            {"qr_code": str(uuid.uuid4()), "user_id": row.id},
        )

    op.create_index(op.f("ix_users_qr_code"), "users", ["qr_code"], unique=True)

    op.execute("ALTER TYPE order_type ADD VALUE IF NOT EXISTS 'in_restaurant'")
    op.execute("ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'order_created_from_qr'")
    op.execute("ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'bonus_earned_from_qr'")
    op.execute("ALTER TYPE audit_action ADD VALUE IF NOT EXISTS 'bonus_spent_from_qr'")


def downgrade() -> None:
    op.drop_index(op.f("ix_users_qr_code"), table_name="users")
    op.drop_column("users", "qr_code")
    # PostgreSQL enum values cannot be removed safely without recreating the enum type.
