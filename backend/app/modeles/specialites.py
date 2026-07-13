from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base
from app.modeles.projets import TYPES_PROJET


class SpecialiteEncadrementEnseignant(Base):
    __tablename__ = "specialites_encadrement_enseignant"
    __table_args__ = (
        UniqueConstraint("cle_doublon_active", name="uq_specialites_encadrement_cle_active"),
        Index("ix_specialites_encadrement_enseignant_actif", "enseignant_id", "actif"),
        Index("ix_specialites_encadrement_type_actif", "type_projet", "actif"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    enseignant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("enseignants.id", ondelete="RESTRICT"),
        nullable=False,
    )
    type_projet: Mapped[str] = mapped_column(
        Enum(*TYPES_PROJET, name="type_specialite_encadrement"),
        nullable=False,
    )
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    date_desactivation: Mapped[datetime | None] = mapped_column(DateTime)
    cree_par_utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
        nullable=False,
    )
    cle_doublon_active: Mapped[str | None] = mapped_column(String(120), unique=True)

    enseignant = relationship("Enseignant", back_populates="specialites_encadrement")
    cree_par = relationship("Utilisateur", foreign_keys=[cree_par_utilisateur_id])
