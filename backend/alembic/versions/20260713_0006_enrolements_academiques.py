"""Enrolements academiques geres par l'appariteur.

Revision ID: 20260713_0006
Revises: 20260713_0005
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260713_0006"
down_revision: Union[str, None] = "20260713_0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def upgrade() -> None:
    if "enrolements_academiques" in _tables():
        return

    op.create_table(
        "enrolements_academiques",
        sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
        sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("promotion_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("annee_academique_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("date_enrolement", sa.Date(), nullable=False),
        sa.Column(
            "statut",
            sa.Enum("en_attente", "valide", "annule", name="statut_enrolement_academique"),
            nullable=False,
        ),
        sa.Column("cree_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
        sa.Column("valide_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
        sa.Column("annule_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
        sa.Column("reference_fiche", sa.String(length=80), nullable=False),
        sa.Column("date_validation", sa.DateTime(), nullable=True),
        sa.Column("date_annulation", sa.DateTime(), nullable=True),
        sa.Column("motif_annulation", sa.Text(), nullable=True),
        sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("date_modification", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
        sa.Column("cle_doublon_actif", sa.String(length=180), nullable=True),
        sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["promotion_id"], ["promotions.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["annee_academique_id"], ["annees_academiques.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["cree_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["valide_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
        sa.ForeignKeyConstraint(["annule_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("reference_fiche", name="uq_enrolements_academiques_reference"),
        sa.UniqueConstraint("cle_doublon_actif", name="uq_enrolements_academiques_cle_active"),
        mysql_engine="InnoDB",
    )
    op.create_index(
        "ix_enrolements_academiques_etudiant_annee",
        "enrolements_academiques",
        ["etudiant_id", "annee_academique_id"],
    )
    op.create_index(
        "ix_enrolements_academiques_promotion_statut",
        "enrolements_academiques",
        ["promotion_id", "statut"],
    )
    op.create_index("ix_enrolements_academiques_statut", "enrolements_academiques", ["statut"])


def downgrade() -> None:
    if "enrolements_academiques" in _tables():
        op.drop_table("enrolements_academiques")
