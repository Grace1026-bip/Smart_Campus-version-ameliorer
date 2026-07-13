from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


TYPES_PROJET = (
    "reseaux",
    "systemes_embarques",
    "intelligence_artificielle",
    "genie_logiciel",
)
STATUTS_PROJET = ("propose", "en_cours", "suspendu", "termine", "archive")
ROLES_ENCADREMENT = ("principal", "coencadreur")


class ProjetAcademique(Base):
    __tablename__ = "projets_academiques"
    __table_args__ = (
        Index("ix_projets_academiques_etudiant_id", "etudiant_id"),
        Index("ix_projets_academiques_promotion_annee", "promotion_id", "annee_academique_id"),
        Index("ix_projets_academiques_type_statut", "type_projet", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    titre: Mapped[str] = mapped_column(String(180), nullable=False)
    type_projet: Mapped[str] = mapped_column(Enum(*TYPES_PROJET, name="type_projet_academique"), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    promotion_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("promotions.id", ondelete="RESTRICT"), nullable=False)
    annee_academique_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("annees_academiques.id", ondelete="RESTRICT"), nullable=False)
    statut: Mapped[str] = mapped_column(Enum(*STATUTS_PROJET, name="statut_projet_academique"), nullable=False, default="propose", index=True)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    etudiant = relationship("Etudiant")
    promotion = relationship("Promotion")
    annee_academique = relationship("AnneeAcademique")
    encadrements: Mapped[list[EncadrementProjet]] = relationship(back_populates="projet", cascade="all, delete-orphan")


class EncadrementProjet(Base):
    __tablename__ = "encadrements_projet"
    __table_args__ = (
        UniqueConstraint("projet_id", "enseignant_id", name="uq_encadrements_projet_enseignant"),
        Index("ix_encadrements_projet_enseignant_actif", "enseignant_id", "actif"),
        Index("ix_encadrements_projet_projet_actif", "projet_id", "actif"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    projet_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("projets_academiques.id", ondelete="CASCADE"), nullable=False)
    enseignant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("enseignants.id", ondelete="RESTRICT"), nullable=False)
    attribue_par_utilisateur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    role_encadrement: Mapped[str] = mapped_column(Enum(*ROLES_ENCADREMENT, name="role_encadrement_projet"), nullable=False, default="principal")
    date_attribution: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, index=True)
    date_fin: Mapped[datetime | None] = mapped_column(DateTime)
    desactive_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
    )

    projet: Mapped[ProjetAcademique] = relationship(back_populates="encadrements")
    enseignant = relationship("Enseignant")
    attribue_par = relationship("Utilisateur", foreign_keys=[attribue_par_utilisateur_id])
    desactive_par = relationship("Utilisateur", foreign_keys=[desactive_par_utilisateur_id])
