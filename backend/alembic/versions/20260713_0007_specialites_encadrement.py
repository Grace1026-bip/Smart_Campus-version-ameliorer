"""Specialites enseignants et historique de desactivation des encadrements.

Revision ID: 20260713_0007
Revises: 20260713_0006
"""

from typing import Sequence, Union

import sqlalchemy as sa
from alembic import op
from sqlalchemy import inspect
from sqlalchemy.dialects import mysql


revision: str = "20260713_0007"
down_revision: Union[str, None] = "20260713_0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def _tables() -> set[str]:
    return set(inspect(op.get_bind()).get_table_names())


def upgrade() -> None:
    bind = op.get_bind()
    tables = _tables()
    if "specialites_encadrement_enseignant" not in tables:
        op.create_table(
            "specialites_encadrement_enseignant",
            sa.Column("id", mysql.BIGINT(unsigned=True), autoincrement=True, nullable=False),
            sa.Column("enseignant_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column(
                "type_projet",
                sa.Enum(
                    "reseaux",
                    "systemes_embarques",
                    "intelligence_artificielle",
                    "genie_logiciel",
                    name="type_specialite_encadrement",
                ),
                nullable=False,
            ),
            sa.Column("actif", sa.Boolean(), nullable=False),
            sa.Column("date_creation", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False),
            sa.Column("date_desactivation", sa.DateTime(), nullable=True),
            sa.Column("cree_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=False),
            sa.Column("cle_doublon_active", sa.String(length=120), nullable=True),
            sa.ForeignKeyConstraint(["enseignant_id"], ["enseignants.id"], ondelete="RESTRICT"),
            sa.ForeignKeyConstraint(["cree_par_utilisateur_id"], ["utilisateurs.id"], ondelete="RESTRICT"),
            sa.PrimaryKeyConstraint("id"),
            sa.UniqueConstraint("cle_doublon_active", name="uq_specialites_encadrement_cle_active"),
            mysql_engine="InnoDB",
        )
        op.create_index(
            "ix_specialites_encadrement_enseignant_actif",
            "specialites_encadrement_enseignant",
            ["enseignant_id", "actif"],
        )
        op.create_index(
            "ix_specialites_encadrement_type_actif",
            "specialites_encadrement_enseignant",
            ["type_projet", "actif"],
        )

    columns = {column["name"] for column in inspect(bind).get_columns("encadrements_projet")}
    if "desactive_par_utilisateur_id" not in columns:
        op.add_column(
            "encadrements_projet",
            sa.Column("desactive_par_utilisateur_id", mysql.BIGINT(unsigned=True), nullable=True),
        )
        op.create_foreign_key(
            "fk_encadrements_projet_desactive_par_utilisateur",
            "encadrements_projet",
            "utilisateurs",
            ["desactive_par_utilisateur_id"],
            ["id"],
            ondelete="RESTRICT",
        )


def downgrade() -> None:
    bind = op.get_bind()
    columns = {column["name"] for column in inspect(bind).get_columns("encadrements_projet")}
    if "desactive_par_utilisateur_id" in columns:
        foreign_key = next(
            (
                foreign_key
                for foreign_key in inspect(bind).get_foreign_keys("encadrements_projet")
                if foreign_key.get("constrained_columns") == ["desactive_par_utilisateur_id"]
            ),
            None,
        )
        if foreign_key and foreign_key.get("name"):
            op.drop_constraint(foreign_key["name"], "encadrements_projet", type_="foreignkey")
        op.drop_column("encadrements_projet", "desactive_par_utilisateur_id")
    if "specialites_encadrement_enseignant" in _tables():
        op.drop_table("specialites_encadrement_enseignant")
