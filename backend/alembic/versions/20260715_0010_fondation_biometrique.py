"""Ajoute la fondation biométrique sans conserver les images originales."""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects.mysql import BIGINT, DECIMAL


revision: str = "20260715_0010"
down_revision: Union[str, None] = "20260715_0009"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    bind = op.get_bind()
    tables = set(inspect(bind).get_table_names())
    if "profils_biometriques" not in tables:
        op.create_table(
            "profils_biometriques",
            sa.Column("id", BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("etudiant_id", BIGINT(unsigned=True), nullable=False),
            sa.Column(
                "statut",
                sa.Enum("actif", "suspendu", "revoque", name="statut_profil_biometrique"),
                nullable=False,
            ),
            sa.Column("version_moteur", sa.String(length=80), nullable=False),
            sa.Column("seuil_utilise", DECIMAL(6, 4), nullable=False),
            sa.Column("consentement_enregistre", sa.Boolean(), nullable=False),
            sa.Column("date_consentement", sa.DateTime(), nullable=True),
            sa.Column("cree_par_utilisateur_id", BIGINT(unsigned=True), nullable=False),
            sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("date_modification", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("date_revocation", sa.DateTime(), nullable=True),
            sa.Column("motif_revocation", sa.Text(), nullable=True),
            sa.Column("cle_profil_actif", sa.String(length=80), nullable=True),
            sa.ForeignKeyConstraint(["etudiant_id"], ["etudiants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["cree_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("cle_profil_actif", name="uq_profils_biometriques_cle_actif"),
            mysql_engine="InnoDB",
        )
        op.create_index(
            "ix_profils_biometriques_etudiant_statut",
            "profils_biometriques",
            ["etudiant_id", "statut"],
        )

    if "encodages_faciaux" not in tables:
        op.create_table(
            "encodages_faciaux",
            sa.Column("id", BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("profil_biometrique_id", BIGINT(unsigned=True), nullable=False),
            sa.Column("encodage_binaire", sa.LargeBinary(), nullable=False),
            sa.Column("dimension", sa.Integer(), nullable=False),
            sa.Column("format", sa.String(length=40), nullable=False),
            sa.Column("version_moteur", sa.String(length=80), nullable=False),
            sa.Column("actif", sa.Boolean(), nullable=False),
            sa.Column("empreinte_integrite", sa.String(length=64), nullable=False),
            sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.CheckConstraint("dimension > 0", name="ck_encodages_faciaux_dimension_positive"),
            sa.ForeignKeyConstraint(["profil_biometrique_id"], ["profils_biometriques.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            mysql_engine="InnoDB",
        )
        op.create_index(
            "ix_encodages_faciaux_profil_actif",
            "encodages_faciaux",
            ["profil_biometrique_id", "actif"],
        )

    op.execute(
        "ALTER TABLE presences_academiques MODIFY COLUMN methode_identification "
        "ENUM('manuelle','matricule','future_reconnaissance_faciale','reconnaissance_faciale') "
        "NOT NULL DEFAULT 'matricule'"
    )


def downgrade() -> None:
    bind = op.get_bind()
    if "presences_academiques" in inspect(bind).get_table_names():
        count = bind.execute(
            sa.text(
                "SELECT COUNT(*) FROM presences_academiques "
                "WHERE methode_identification = 'reconnaissance_faciale'"
            )
        ).scalar_one()
        if count:
            raise RuntimeError("Impossible de revenir en arrière: des présences faciales existent")
        op.execute(
            "ALTER TABLE presences_academiques MODIFY COLUMN methode_identification "
            "ENUM('manuelle','matricule','future_reconnaissance_faciale') "
            "NOT NULL DEFAULT 'matricule'"
        )
    if "encodages_faciaux" in inspect(bind).get_table_names():
        op.drop_table("encodages_faciaux")
    if "profils_biometriques" in inspect(bind).get_table_names():
        op.drop_table("profils_biometriques")
