from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, Date, DateTime, Enum, ForeignKey, Index, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class Presence(Base):
    __tablename__ = "presences"
    __table_args__ = (
        UniqueConstraint("etudiant_id", "cours_id", "date_seance", name="uq_presences_etudiant_cours_seance"),
        Index("ix_presences_cours_id", "cours_id"),
        Index("ix_presences_enregistre_par", "enregistre_par"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    cours_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="RESTRICT"), nullable=False)
    date_seance: Mapped[date] = mapped_column(Date, nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum("present", "absent", "retard", "justifie", name="statut_presence"),
        nullable=False,
    )
    enregistre_par: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    etudiant = relationship("Etudiant")
    cours = relationship("Cours")
    enregistreur = relationship("Utilisateur")


class EvaluationRisque(Base):
    __tablename__ = "evaluations_risque"
    __table_args__ = (
        CheckConstraint("score_risque >= 0", name="ck_evaluations_risque_score_min"),
        CheckConstraint("score_risque <= 100", name="ck_evaluations_risque_score_max"),
        Index("ix_evaluations_risque_etudiant_id", "etudiant_id"),
        Index("ix_evaluations_risque_cours_id", "cours_id"),
        Index("ix_evaluations_risque_niveau", "niveau_risque"),
        Index("ix_evaluations_risque_active", "est_active"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    cours_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="SET NULL"))
    score_risque: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    niveau_risque: Mapped[str] = mapped_column(
        Enum("faible", "moyen", "eleve", name="niveau_risque"),
        nullable=False,
    )
    raisons: Mapped[str] = mapped_column(Text, nullable=False)
    calcule_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    est_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    etudiant = relationship("Etudiant")
    cours = relationship("Cours")
