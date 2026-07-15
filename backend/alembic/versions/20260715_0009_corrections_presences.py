"""Ajoute l'historique immutable des corrections de presence."""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260715_0009"
down_revision: Union[str, None] = "20260714_0008"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    if "corrections_presences_academiques" in inspect(bind).get_table_names():
        return

    op.create_table(
        "corrections_presences_academiques",
        sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
        sa.Column("presence_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("seance_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column(
            "ancien_statut",
            sa.Enum("present", "retard", "absent", "refuse", name="ancien_statut_presence_academique"),
            nullable=False,
        ),
        sa.Column(
            "nouveau_statut",
            sa.Enum("present", "retard", "absent", "refuse", name="nouveau_statut_presence_academique"),
            nullable=False,
        ),
        sa.Column("motif", sa.Text(), nullable=False),
        sa.Column("corrige_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("date_correction", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.ForeignKeyConstraint(["presence_id"], ["presences_academiques.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["seance_id"], ["seances_academiques.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["corrige_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        mysql_engine="InnoDB",
    )
    op.create_index("ix_corrections_presences_presence_id", "corrections_presences_academiques", ["presence_id"])
    op.create_index(
        "ix_corrections_presences_seance_etudiant",
        "corrections_presences_academiques",
        ["seance_id", "etudiant_id"],
    )


def downgrade() -> None:
    if "corrections_presences_academiques" in inspect(op.get_bind()).get_table_names():
        op.drop_table("corrections_presences_academiques")
