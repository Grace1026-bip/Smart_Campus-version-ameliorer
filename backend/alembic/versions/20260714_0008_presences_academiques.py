"""Ajoute les seances academiques et le controle manuel des acces.

Revision ID: 20260714_0008
Revises: 20260713_0007
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260714_0008"
down_revision: Union[str, None] = "20260713_0007"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def upgrade() -> None:
    bind = op.get_bind()
    tables = _tables()

    if "pourcentage_paiement" not in {
        column["name"] for column in inspect(bind).get_columns("enrolements_academiques")
    }:
        op.add_column(
            "enrolements_academiques",
            sa.Column(
                "pourcentage_paiement",
                mysql.DECIMAL(precision=5, scale=2),
                nullable=False,
                server_default=sa.text("0.00"),
            ),
        )
        op.create_check_constraint(
            "ck_enrolements_academiques_paiement_valide",
            "enrolements_academiques",
            "pourcentage_paiement >= 0 AND pourcentage_paiement <= 100",
        )

    if "seances_academiques" not in tables:
        op.create_table(
            "seances_academiques",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("cours_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("promotion_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("enseignant_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("annee_academique_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("semestre_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("date_seance", sa.Date(), nullable=False),
            sa.Column("heure_debut", sa.Time(), nullable=True),
            sa.Column("heure_fin", sa.Time(), nullable=True),
            sa.Column(
                "type_cours",
                sa.Enum("cours_1", "cours_2", "autre", name="type_cours_seance"),
                nullable=False,
            ),
            sa.Column(
                "statut",
                sa.Enum("planifiee", "ouverte", "fermee", "annulee", name="statut_seance_academique"),
                nullable=False,
                server_default="planifiee",
            ),
            sa.Column("ouverte_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("date_ouverture", sa.DateTime(), nullable=True),
            sa.Column("date_fermeture", sa.DateTime(), nullable=True),
            sa.Column("fermee_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("confirme_cours_2_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("confirme_cours_2_le", sa.DateTime(), nullable=True),
            sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column(
                "date_modification",
                sa.DateTime(),
                server_default=sa.text("CURRENT_TIMESTAMP"),
                nullable=False,
            ),
            sa.CheckConstraint(
                "heure_fin IS NULL OR heure_debut IS NULL OR heure_fin > heure_debut",
                name="ck_seances_academiques_heures_coherentes",
            ),
            sa.ForeignKeyConstraint(["cours_id"], ["cours.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["promotion_id"], ["promotions.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["enseignant_id"], ["enseignants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["annee_academique_id"], ["annees_academiques.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["semestre_id"], ["semestres.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(
                ["ouverte_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"
            ),
            sa.ForeignKeyConstraint(["fermee_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(
                ["confirme_cours_2_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"
            ),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint(
                "cours_id", "date_seance", "type_cours", name="uq_seances_academiques_cours_date_type"
            ),
            mysql_engine="InnoDB",
        )
        op.create_index(
            "ix_seances_academiques_promotion_date",
            "seances_academiques",
            ["promotion_id", "date_seance"],
        )
        op.create_index("ix_seances_academiques_statut", "seances_academiques", ["statut"])

    if "presences_academiques" not in tables:
        op.create_table(
            "presences_academiques",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("seance_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column(
                "statut",
                sa.Enum("present", "retard", "absent", "refuse", name="statut_presence_academique"),
                nullable=False,
            ),
            sa.Column("heure_identification", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("heure_enregistrement", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column(
                "methode_identification",
                sa.Enum("manuelle", "matricule", "future_reconnaissance_faciale", name="methode_identification_presence"),
                nullable=False,
                server_default="matricule",
            ),
            sa.Column("enregistre_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column(
                "motif_refus",
                sa.Enum(
                    "autorise",
                    "paiement_insuffisant",
                    "etudiant_inactif",
                    "non_enrole",
                    "mauvaise_promotion",
                    "seance_fermee",
                    "deja_enregistre",
                    "etudiant_introuvable",
                    name="motif_refus_presence",
                ),
                nullable=True,
            ),
            sa.Column("pourcentage_paiement_observe", mysql.DECIMAL(precision=5, scale=2), nullable=True),
            sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column(
                "date_modification",
                sa.DateTime(),
                server_default=sa.text("CURRENT_TIMESTAMP"),
                nullable=False,
            ),
            sa.CheckConstraint(
                "pourcentage_paiement_observe IS NULL OR (pourcentage_paiement_observe >= 0 AND pourcentage_paiement_observe <= 100)",
                name="ck_presences_academiques_paiement_valide",
            ),
            sa.ForeignKeyConstraint(["seance_id"], ["seances_academiques.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(
                ["enregistre_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"
            ),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("seance_id", "etudiant_id", name="uq_presences_academiques_seance_etudiant"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_presences_academiques_etudiant", "presences_academiques", ["etudiant_id"])
        op.create_index("ix_presences_academiques_statut", "presences_academiques", ["statut"])


def downgrade() -> None:
    bind = op.get_bind()
    tables = _tables()
    if "presences_academiques" in tables:
        op.drop_table("presences_academiques")
    if "seances_academiques" in tables:
        op.drop_table("seances_academiques")

    columns = {column["name"] for column in inspect(bind).get_columns("enrolements_academiques")}
    if "pourcentage_paiement" in columns:
        op.drop_constraint(
            "ck_enrolements_academiques_paiement_valide",
            "enrolements_academiques",
            type_="check",
        )
        op.drop_column("enrolements_academiques", "pourcentage_paiement")
