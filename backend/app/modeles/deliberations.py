from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, Integer, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class SessionDeliberation(Base):
    __tablename__ = "sessions_deliberation"
    __table_args__ = (
        UniqueConstraint(
            "promotion_id",
            "annee_academique_id",
            "semestre_id",
            "version",
            name="uq_sessions_deliberation_perimetre_version",
        ),
        Index("ix_sessions_deliberation_statut", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    promotion_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("promotions.id", ondelete="RESTRICT"), nullable=False)
    annee_academique_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("annees_academiques.id", ondelete="RESTRICT"), nullable=False)
    semestre_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("semestres.id", ondelete="RESTRICT"), nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum("preparation", "ouverte", "cloturee", "publiee", "annulee", name="statut_session_deliberation"),
        nullable=False,
        default="preparation",
    )
    cree_par_utilisateur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    president_utilisateur_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"))
    date_ouverture: Mapped[datetime | None] = mapped_column(DateTime)
    date_cloture: Mapped[datetime | None] = mapped_column(DateTime)
    version: Mapped[int] = mapped_column(Integer, nullable=False, default=1)
    motif_reouverture: Mapped[str | None] = mapped_column(Text)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    membres: Mapped[list[MembreJury]] = relationship(back_populates="session", cascade="all, delete-orphan")
    decisions: Mapped[list[DecisionJury]] = relationship(back_populates="session", cascade="all, delete-orphan")
    snapshots: Mapped[list[ResultatSemestrielOfficiel]] = relationship(back_populates="session", cascade="all, delete-orphan")


class MembreJury(Base):
    __tablename__ = "membres_jury"
    __table_args__ = (
        UniqueConstraint("session_id", "utilisateur_id", name="uq_membres_jury_session_utilisateur"),
        Index("ix_membres_jury_utilisateur_id", "utilisateur_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    session_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("sessions_deliberation.id", ondelete="CASCADE"), nullable=False)
    utilisateur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    qualite: Mapped[str] = mapped_column(Enum("president", "membre", "secretaire", name="qualite_membre_jury"), nullable=False)
    present: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    date_ajout: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    session: Mapped[SessionDeliberation] = relationship(back_populates="membres")
    utilisateur = relationship("Utilisateur")


class DecisionJury(Base):
    __tablename__ = "decisions_jury"
    __table_args__ = (UniqueConstraint("session_id", "etudiant_id", name="uq_decisions_jury_session_etudiant"),)

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    session_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("sessions_deliberation.id", ondelete="CASCADE"), nullable=False)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    decision: Mapped[str] = mapped_column(Enum("ADM", "COMP", "DEF", "AJ", name="decision_jury"), nullable=False)
    motif: Mapped[str | None] = mapped_column(Text)
    enregistre_par_utilisateur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    session: Mapped[SessionDeliberation] = relationship(back_populates="decisions")
    etudiant = relationship("Etudiant")
    enregistre_par = relationship("Utilisateur", foreign_keys=[enregistre_par_utilisateur_id])


class ResultatSemestrielOfficiel(Base):
    __tablename__ = "resultats_semestre_officiels"
    __table_args__ = (
        UniqueConstraint("session_id", "etudiant_id", name="uq_snapshots_session_etudiant"),
        UniqueConstraint(
            "etudiant_id",
            "annee_academique_id",
            "semestre_id",
            "version",
            name="uq_snapshots_etudiant_perimetre_version",
        ),
        Index("ix_snapshots_etudiant_actif", "etudiant_id", "est_actif"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    session_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("sessions_deliberation.id", ondelete="RESTRICT"), nullable=False)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    annee_academique_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("annees_academiques.id", ondelete="RESTRICT"), nullable=False)
    semestre_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("semestres.id", ondelete="RESTRICT"), nullable=False)
    moyenne_ponderee: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    credits_prevus: Mapped[int] = mapped_column(Integer, nullable=False)
    credits_capitalises: Mapped[int] = mapped_column(Integer, nullable=False)
    credits_non_capitalises: Mapped[int] = mapped_column(Integer, nullable=False)
    decision: Mapped[str] = mapped_column(Enum("ADM", "COMP", "DEF", "AJ", name="decision_officielle"), nullable=False)
    statut_publication: Mapped[str] = mapped_column(Enum("non_publie", "publie", "remplace", name="statut_publication_snapshot"), nullable=False, default="non_publie")
    formule_version: Mapped[str] = mapped_column(String(80), nullable=False)
    valide_par_jury: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    president_jury_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"))
    date_validation: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    publie_par_utilisateur_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"))
    date_publication: Mapped[datetime | None] = mapped_column(DateTime)
    version: Mapped[int] = mapped_column(Integer, nullable=False)
    est_actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    motif_correction: Mapped[str | None] = mapped_column(Text)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    session: Mapped[SessionDeliberation] = relationship(back_populates="snapshots")
    etudiant = relationship("Etudiant")

