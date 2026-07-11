"""Demandes d'inscription.

Revision ID: 20260711_0003
Revises: 20260705_0002
Create Date: 2026-07-11
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260711_0003"
down_revision: Union[str, None] = "20260705_0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def upgrade() -> None:
    if "demandes_inscription" in _tables():
        return

    op.create_table(
        "demandes_inscription",
        sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
        sa.Column("reference", sa.String(length=40), nullable=False),
        sa.Column("type_demande", sa.Enum("etudiant", "enseignant", name="type_demande_inscription"), nullable=False),
        sa.Column("email", sa.String(length=190), nullable=False),
        sa.Column("nom", sa.String(length=100), nullable=False),
        sa.Column("postnom", sa.String(length=100), nullable=True),
        sa.Column("prenom", sa.String(length=100), nullable=True),
        sa.Column("telephone", sa.String(length=30), nullable=True),
        sa.Column("mot_de_passe_hash", sa.String(length=255), nullable=False),
        sa.Column("matricule", sa.String(length=80), nullable=True),
        sa.Column("promotion_id", mysql.BIGINT(unsigned=True), nullable=True),
        sa.Column("matricule_agent", sa.String(length=80), nullable=True),
        sa.Column("grade", sa.String(length=100), nullable=True),
        sa.Column("departement", sa.String(length=150), nullable=True),
        sa.Column(
            "statut",
            sa.Enum("en_attente", "approuvee", "rejetee", name="statut_demande_inscription"),
            nullable=False,
        ),
        sa.Column("utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
        sa.Column("traite_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
        sa.Column("motif_rejet", sa.Text(), nullable=True),
        sa.Column("cree_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("traite_le", sa.DateTime(), nullable=True),
        sa.ForeignKeyConstraint(["promotion_id"], ["promotions.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["traite_par_utilisateur_id"], ["utilisateurs.id"], ondelete="SET NULL"),
        sa.ForeignKeyConstraint(["utilisateur_id"], ["utilisateurs.id"], ondelete="SET NULL"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("reference", name="uq_demandes_inscription_reference"),
    )
    op.create_index("ix_demandes_inscription_email", "demandes_inscription", ["email"])
    op.create_index("ix_demandes_inscription_statut", "demandes_inscription", ["statut"])
    op.create_index(
        "ix_demandes_inscription_type_statut",
        "demandes_inscription",
        ["type_demande", "statut"],
    )


def downgrade() -> None:
    if "demandes_inscription" in _tables():
        op.drop_table("demandes_inscription")
