from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import Boolean, CheckConstraint, Date, DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class TypeEvaluation(Base):
    __tablename__ = "types_evaluations"

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(String(80), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text)


class Evaluation(Base):
    __tablename__ = "evaluations"
    __table_args__ = (
        CheckConstraint("note_maximale > 0", name="ck_evaluations_note_maximale_positive"),
        CheckConstraint("ponderation > 0", name="ck_evaluations_ponderation_positive"),
        Index("ix_evaluations_cours_id", "cours_id"),
        Index("ix_evaluations_type_evaluation_id", "type_evaluation_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    cours_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="RESTRICT"), nullable=False)
    type_evaluation_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("types_evaluations.id", ondelete="RESTRICT"),
        nullable=False,
    )
    titre: Mapped[str] = mapped_column(String(180), nullable=False)
    note_maximale: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    ponderation: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum("brouillon", "publiee", "archivee", name="statut_evaluation"),
        nullable=False,
        default="brouillon",
        index=True,
    )
    cree_par: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    date_evaluation: Mapped[date | None] = mapped_column(Date)
    date_publication: Mapped[datetime | None] = mapped_column(DateTime)
    est_verrouillee: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    cours = relationship("Cours")
    type_evaluation = relationship("TypeEvaluation")
    notes: Mapped[list[Note]] = relationship(back_populates="evaluation")


class Note(Base):
    __tablename__ = "notes"
    __table_args__ = (
        UniqueConstraint("evaluation_id", "etudiant_id", name="uq_notes_evaluation_etudiant"),
        CheckConstraint("note_obtenue >= 0", name="ck_notes_note_obtenue_positive"),
        Index("ix_notes_etudiant_id", "etudiant_id"),
        Index("ix_notes_encodee_par", "encodee_par"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    evaluation_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("evaluations.id", ondelete="RESTRICT"),
        nullable=False,
    )
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    note_obtenue: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    commentaire: Mapped[str | None] = mapped_column(Text)
    encodee_par: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    evaluation: Mapped[Evaluation] = relationship(back_populates="notes")
    etudiant = relationship("Etudiant")
    encodeur = relationship("Utilisateur")


class ResultatCours(Base):
    __tablename__ = "resultats_cours"
    __table_args__ = (
        UniqueConstraint("etudiant_id", "cours_id", name="uq_resultats_cours_etudiant_cours"),
        CheckConstraint("moyenne >= 0", name="ck_resultats_cours_moyenne_positive"),
        Index("ix_resultats_cours_cours_id", "cours_id"),
        Index("ix_resultats_cours_statut_resultat", "statut_resultat"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    cours_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="RESTRICT"), nullable=False)
    moyenne: Mapped[Decimal] = mapped_column(DECIMAL(5, 2), nullable=False)
    credits_obtenus: Mapped[int] = mapped_column(BIGINT(unsigned=True), nullable=False, default=0)
    statut_resultat: Mapped[str] = mapped_column(
        Enum("en_attente", "reussi", "echoue", name="statut_resultat_cours"),
        nullable=False,
        default="en_attente",
    )
    calcule_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    etudiant = relationship("Etudiant")
    cours = relationship("Cours")
