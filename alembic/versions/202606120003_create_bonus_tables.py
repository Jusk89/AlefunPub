"""create bonus tables

Revision ID: 202606120003
Revises: 202606120002
Create Date: 2026-06-12 00:03:00.000000
"""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = "202606120003"
down_revision: Union[str, None] = "202606120002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bonus_transaction_type = postgresql.ENUM(
        "earn",
        "spend",
        "expire",
        "manual",
        name="bonus_transaction_type",
        create_type=False,
    )
    bonus_transaction_type.create(op.get_bind(), checkfirst=True)

    op.create_table(
        "bonus_accounts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("balance", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("total_earned", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("total_spent", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("user_id", "restaurant_id", name="uq_bonus_accounts_user_restaurant"),
    )
    op.create_index(op.f("ix_bonus_accounts_id"), "bonus_accounts", ["id"], unique=False)
    op.create_index(op.f("ix_bonus_accounts_restaurant_id"), "bonus_accounts", ["restaurant_id"], unique=False)
    op.create_index(op.f("ix_bonus_accounts_user_id"), "bonus_accounts", ["user_id"], unique=False)

    op.create_table(
        "bonus_transactions",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("restaurant_id", sa.Integer(), nullable=False),
        sa.Column("branch_id", sa.Integer(), nullable=True),
        sa.Column("order_id", sa.Integer(), nullable=True),
        sa.Column("type", bonus_transaction_type, nullable=False),
        sa.Column("amount", sa.Numeric(precision=12, scale=2), nullable=False),
        sa.Column("remaining_amount", sa.Numeric(precision=12, scale=2), server_default="0", nullable=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("source_transaction_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.ForeignKeyConstraint(["branch_id"], ["branches.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["order_id"], ["orders.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["restaurant_id"], ["restaurants.id"], ondelete="CASCADE"),
        sa.ForeignKeyConstraint(["source_transaction_id"], ["bonus_transactions.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index(op.f("ix_bonus_transactions_branch_id"), "bonus_transactions", ["branch_id"], unique=False)
    op.create_index(
        "ix_bonus_transactions_fifo_lookup",
        "bonus_transactions",
        ["user_id", "restaurant_id", "type", "expires_at", "created_at"],
        unique=False,
    )
    op.create_index(op.f("ix_bonus_transactions_id"), "bonus_transactions", ["id"], unique=False)
    op.create_index(op.f("ix_bonus_transactions_order_id"), "bonus_transactions", ["order_id"], unique=False)
    op.create_index("ix_bonus_transactions_order_type", "bonus_transactions", ["order_id", "type"], unique=False)
    op.create_index(op.f("ix_bonus_transactions_restaurant_id"), "bonus_transactions", ["restaurant_id"], unique=False)
    op.create_index(
        op.f("ix_bonus_transactions_source_transaction_id"),
        "bonus_transactions",
        ["source_transaction_id"],
        unique=False,
    )
    op.create_index(op.f("ix_bonus_transactions_user_id"), "bonus_transactions", ["user_id"], unique=False)


def downgrade() -> None:
    op.drop_index(op.f("ix_bonus_transactions_user_id"), table_name="bonus_transactions")
    op.drop_index(op.f("ix_bonus_transactions_source_transaction_id"), table_name="bonus_transactions")
    op.drop_index(op.f("ix_bonus_transactions_restaurant_id"), table_name="bonus_transactions")
    op.drop_index("ix_bonus_transactions_order_type", table_name="bonus_transactions")
    op.drop_index(op.f("ix_bonus_transactions_order_id"), table_name="bonus_transactions")
    op.drop_index(op.f("ix_bonus_transactions_id"), table_name="bonus_transactions")
    op.drop_index("ix_bonus_transactions_fifo_lookup", table_name="bonus_transactions")
    op.drop_index(op.f("ix_bonus_transactions_branch_id"), table_name="bonus_transactions")
    op.drop_table("bonus_transactions")

    op.drop_index(op.f("ix_bonus_accounts_user_id"), table_name="bonus_accounts")
    op.drop_index(op.f("ix_bonus_accounts_restaurant_id"), table_name="bonus_accounts")
    op.drop_index(op.f("ix_bonus_accounts_id"), table_name="bonus_accounts")
    op.drop_table("bonus_accounts")

    postgresql.ENUM(
        "earn",
        "spend",
        "expire",
        "manual",
        name="bonus_transaction_type",
        create_type=False,
    ).drop(
        op.get_bind(),
        checkfirst=True,
    )
