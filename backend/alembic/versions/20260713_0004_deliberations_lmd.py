"""Sessions de deliberation LMD et snapshots officiels.

Revision ID: 20260713_0004
Revises: 20260711_0003
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260713_0004"
down_revision: Union[str, None] = "20260711_0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def _ensure_innodb_parent_tables() -> None:
    bind = op.get_bind()
    tables = _tables()
    parent_tables = {
        "promotions",
        "annees_academiques",
        "semestres",
        "utilisateurs",
        "etudiants",
        "enseignants",
    }
    for table in sorted(parent_tables & tables):
        moteur = bind.execute(
            sa.text(
                "SELECT ENGINE FROM information_schema.tables "
                "WHERE table_schema = DATABASE() AND table_name = :table"
            ),
            {"table": table},
        ).scalar()
        if moteur and str(moteur).upper() != "INNODB":
            op.execute(sa.text(f"ALTER TABLE `{table}` ENGINE=InnoDB"))


def upgrade() -> None:
    _ensure_innodb_parent_tables()
    tables = _tables()
    if "sessions_deliberation" not in tables:
        op.create_table(
            "sessions_deliberation",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("promotion_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("annee_academique_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("semestre_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("statut", sa.Enum("preparation", "ouverte", "cloturee", "publiee", "annulee", name="statut_session_deliberation"), nullable=False),
            sa.Column("cree_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("president_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("date_ouverture", sa.DateTime(), nullable=True),
            sa.Column("date_cloture", sa.DateTime(), nullable=True),
            sa.Column("version", sa.Integer(), nullable=False),
            sa.Column("motif_reouverture", sa.Text(), nullable=True),
            sa.Column("cree_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("modifie_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["promotion_id"], ["promotions.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["annee_academique_id"], ["annees_academiques.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["semestre_id"], ["semestres.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["cree_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["president_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("promotion_id", "annee_academique_id", "semestre_id", "version", name="uq_sessions_deliberation_perimetre_version"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_sessions_deliberation_statut", "sessions_deliberation", ["statut"])

    if "membres_jury" not in tables:
        op.create_table(
            "membres_jury",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("session_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("qualite", sa.Enum("president", "membre", "secretaire", name="qualite_membre_jury"), nullable=False),
            sa.Column("present", sa.Boolean(), nullable=False),
            sa.Column("date_ajout", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["session_id"], ["sessions_deliberation.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("session_id", "utilisateur_id", name="uq_membres_jury_session_utilisateur"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_membres_jury_utilisateur_id", "membres_jury", ["utilisateur_id"])

    if "decisions_jury" not in tables:
        op.create_table(
            "decisions_jury",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("session_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("decision", sa.Enum("ADM", "COMP", "DEF", "AJ", name="decision_jury"), nullable=False),
            sa.Column("motif", sa.Text(), nullable=True),
            sa.Column("enregistre_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("cree_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["session_id"], ["sessions_deliberation.id"], ondelete="CASCADE"),
            sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["enregistre_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("session_id", "etudiant_id", name="uq_decisions_jury_session_etudiant"),
            mysql_engine="InnoDB",
        )

    if "resultats_semestre_officiels" not in tables:
        op.create_table(
            "resultats_semestre_officiels",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("session_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("etudiant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("annee_academique_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("semestre_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("moyenne_ponderee", mysql.DECIMAL(5, 2), nullable=False),
            sa.Column("credits_prevus", sa.Integer(), nullable=False),
            sa.Column("credits_capitalises", sa.Integer(), nullable=False),
            sa.Column("credits_non_capitalises", sa.Integer(), nullable=False),
            sa.Column("decision", sa.Enum("ADM", "COMP", "DEF", "AJ", name="decision_officielle"), nullable=False),
            sa.Column("statut_publication", sa.Enum("non_publie", "publie", "remplace", name="statut_publication_snapshot"), nullable=False),
            sa.Column("formule_version", sa.String(length=80), nullable=False),
            sa.Column("valide_par_jury", sa.Boolean(), nullable=False),
            sa.Column("president_jury_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("date_validation", sa.DateTime(), nullable=False),
            sa.Column("publie_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
            sa.Column("date_publication", sa.DateTime(), nullable=True),
            sa.Column("version", sa.Integer(), nullable=False),
            sa.Column("est_actif", sa.Boolean(), nullable=False),
            sa.Column("motif_correction", sa.Text(), nullable=True),
            sa.Column("cree_le", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.ForeignKeyConstraint(["session_id"], ["sessions_deliberation.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["annee_academique_id"], ["annees_academiques.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["semestre_id"], ["semestres.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["president_jury_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["publie_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("session_id", "etudiant_id", name="uq_snapshots_session_etudiant"),
            sa.UniqueConstraint("etudiant_id", "annee_academique_id", "semestre_id", "version", name="uq_snapshots_etudiant_perimetre_version"),
            mysql_engine="InnoDB",
        )
        op.create_index("ix_snapshots_etudiant_actif", "resultats_semestre_officiels", ["etudiant_id", "est_actif"])


def downgrade() -> None:
    tables = _tables()
    if "resultats_semestre_officiels" in tables:
        op.drop_table("resultats_semestre_officiels")
    if "decisions_jury" in tables:
        op.drop_table("decisions_jury")
    if "membres_jury" in tables:
        op.drop_table("membres_jury")
    if "sessions_deliberation" in tables:
        op.drop_table("sessions_deliberation")
