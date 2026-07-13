"""Projets academiques et encadrements enseignants.

Revision ID: 20260713_0005
Revises: 20260713_0004
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260713_0005"
down_revision: Union[str, None] = "20260713_0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def upgrade() -> None:
    tables = _tables()
    if "projets_academiques" not in tables:
        op.create_table(
            "projets_academiques",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("titre", sa.String(length=180), nullable=False),
            sa.Column("type_projet", sa.Enum("reseaux", "systemes_embarques", "intelligence_artificielle", "genie_logiciel", name="type_projet_academique"), nullable=False),
            sa.Column("description", sa.Text(), nullable=True),
            sa.Column("promotion_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("annee_academique_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("statut", sa.Enum("propose", "en_cours", "suspendu", "termine", "archive", name="statut_projet_academique"), nullable=False),
            sa.Column("cree_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("modifie_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["promotion_id"], ["promotions.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["annee_academique_id"], ["annees_academiques.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_projets_academiques_etudiant_id", "projets_academiques", ["etudiant_id"])
        op.create_index("ix_projets_academiques_promotion_annee", "projets_academiques", ["promotion_id", "annee_academique_id"])
        op.create_index("ix_projets_academiques_type_statut", "projets_academiques", ["type_projet", "statut"])

    tables = _tables()
    if "encadrements_projet" not in tables:
        op.create_table(
            "encadrements_projet",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("projet_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("enseignant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("attribue_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("role_encadrement", sa.Enum("principal", "coencadreur", name="role_encadrement_projet"), nullable=False),
            sa.Column("date_attribution", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("actif", sa.Boolean(), nullable=False),
            sa.Column("date_fin", sa.DateTime(), nullable=True),
            sa.ForeignKeyConstraint(["projet_id"], ["projets_academiques.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["enseignant_id"], ["enseignants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["attribue_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("projet_id", "enseignant_id", name="uq_encadrements_projet_enseignant"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_encadrements_projet_enseignant_actif", "encadrements_projet", ["enseignant_id", "actif"])
        op.create_index("ix_encadrements_projet_projet_actif", "encadrements_projet", ["projet_id", "actif"])


def downgrade() -> None:
    tables = _tables()
    if "encadrements_projet" in tables:
        op.drop_table("encadrements_projet")
    if "projets_academiques" in tables:
        op.drop_table("projets_academiques")
