"""Structure initiale Smart Faculty.

Revision ID: 20260705_0001
Revises:
Create Date: 2026-07-05
"""

from typing import Sequence, Union

from alembic import op

from app.base_de_donnees.base import Base
import app.modeles  # noqa: F401


revision: str = "20260705_0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    Base.metadata.create_all(bind=bind)


def downgrade() -> None:
    bind = op.get_bind()
    Base.metadata.drop_all(bind=bind)
