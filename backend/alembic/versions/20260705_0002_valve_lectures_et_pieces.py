"""Lectures de publications et archivage des pieces jointes.

Revision ID: 20260705_0002
Revises: 20260705_0001
Create Date: 2026-07-05
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260705_0002"
down_revision: Union[str, None] = "20260705_0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _colonnes(table: str) -> set[str]:
    bind = op.get_bind()
    return {colonne["name"] for colonne in inspect(bind).get_columns(table)}


def _tables() -> set[str]:
    bind = op.get_bind()
    return set(inspect(bind).get_table_names())


def _index_existe(table: str, nom: str) -> bool:
    bind = op.get_bind()
    return any(index["name"] == nom for index in inspect(bind).get_indexes(table))


def upgrade() -> None:
    tables = _tables()

    if "pieces_jointes_publications" in tables:
        colonnes_pieces = _colonnes("pieces_jointes_publications")
        if "est_archivee" not in colonnes_pieces:
            op.add_column(
                "pieces_jointes_publications",
                sa.Column("est_archivee", sa.Boolean(), nullable=False, server_default=sa.text("0")),
            )
        if "archivee_le" not in colonnes_pieces:
            op.add_column("pieces_jointes_publications", sa.Column("archivee_le", sa.DateTime(), nullable=True))
        if not _index_existe("pieces_jointes_publications", "ix_pieces_jointes_publications_est_archivee"):
            op.create_index(
                "ix_pieces_jointes_publications_est_archivee",
                "pieces_jointes_publications",
                ["est_archivee"],
            )

    if "lectures_publications" not in tables:
        op.create_table(
            "lectures_publications",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("publication_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("lu_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["publication_id"], ["publications_valve.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["utilisateur_id"], ["utilisateurs.id"], ondelete="CASCADE"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint(
                "publication_id",
                "utilisateur_id",
                name="uq_lectures_publications_publication_utilisateur",
            ),
        )
        op.create_index(
            "ix_lectures_publications_utilisateur_id",
            "lectures_publications",
            ["utilisateur_id"],
        )


def downgrade() -> None:
    tables = _tables()

    if "lectures_publications" in tables:
        op.drop_table("lectures_publications")

    if "pieces_jointes_publications" in tables:
        if _index_existe("pieces_jointes_publications", "ix_pieces_jointes_publications_est_archivee"):
            op.drop_index("ix_pieces_jointes_publications_est_archivee", table_name="pieces_jointes_publications")
        colonnes_pieces = _colonnes("pieces_jointes_publications")
        if "archivee_le" in colonnes_pieces:
            op.drop_column("pieces_jointes_publications", "archivee_le")
        if "est_archivee" in colonnes_pieces:
            op.drop_column("pieces_jointes_publications", "est_archivee")
