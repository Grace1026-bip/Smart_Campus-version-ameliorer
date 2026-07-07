from __future__ import annotations

from datetime import date, datetime

from sqlalchemy import Boolean, CheckConstraint, Date, DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT, INTEGER
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class AnneeAcademique(Base):
    __tablename__ = "annees_academiques"
    __table_args__ = (
        CheckConstraint("date_fin > date_debut", name="ck_annees_academiques_dates"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    libelle: Mapped[str] = mapped_column(String(30), nullable=False, unique=True)
    date_debut: Mapped[date] = mapped_column(Date, nullable=False)
    date_fin: Mapped[date] = mapped_column(Date, nullable=False)
    est_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)

    semestres: Mapped[list[Semestre]] = relationship(back_populates="annee_academique")
    promotions: Mapped[list[Promotion]] = relationship(back_populates="annee_academique")


class Semestre(Base):
    __tablename__ = "semestres"
    __table_args__ = (
        UniqueConstraint("annee_academique_id", "numero", name="uq_semestres_annee_numero"),
        CheckConstraint("numero > 0", name="ck_semestres_numero_positif"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(String(80), nullable=False)
    numero: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    annee_academique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("annees_academiques.id", ondelete="RESTRICT"),
        nullable=False,
    )

    annee_academique: Mapped[AnneeAcademique] = relationship(back_populates="semestres")
    cours: Mapped[list[Cours]] = relationship(back_populates="semestre")


class Promotion(Base):
    __tablename__ = "promotions"
    __table_args__ = (
        UniqueConstraint("nom", "annee_academique_id", name="uq_promotions_nom_annee"),
        Index("ix_promotions_annee_academique_id", "annee_academique_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(String(150), nullable=False)
    niveau: Mapped[str] = mapped_column(String(60), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    annee_academique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("annees_academiques.id", ondelete="RESTRICT"),
        nullable=False,
    )
    est_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, index=True)

    annee_academique: Mapped[AnneeAcademique] = relationship(back_populates="promotions")
    etudiants: Mapped[list[Etudiant]] = relationship(back_populates="promotion")
    cours: Mapped[list[Cours]] = relationship(back_populates="promotion")


class Etudiant(Base):
    __tablename__ = "etudiants"
    __table_args__ = (
        Index("ix_etudiants_promotion_id", "promotion_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    matricule: Mapped[str] = mapped_column(String(80), nullable=False, unique=True)
    promotion_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("promotions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    date_inscription: Mapped[date] = mapped_column(Date, nullable=False)
    statut_academique: Mapped[str] = mapped_column(
        Enum("actif", "suspendu", "diplome", "abandon", "archive", name="statut_academique_etudiant"),
        nullable=False,
        default="actif",
        index=True,
    )

    promotion: Mapped[Promotion] = relationship(back_populates="etudiants")
    utilisateur = relationship("Utilisateur")
    inscriptions_cours: Mapped[list[InscriptionCours]] = relationship(back_populates="etudiant")


class Enseignant(Base):
    __tablename__ = "enseignants"

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
        nullable=False,
        unique=True,
    )
    matricule_agent: Mapped[str | None] = mapped_column(String(80), unique=True)
    grade: Mapped[str | None] = mapped_column(String(100))
    departement: Mapped[str | None] = mapped_column(String(150))
    statut: Mapped[str] = mapped_column(
        Enum("actif", "suspendu", "archive", name="statut_enseignant"),
        nullable=False,
        default="actif",
        index=True,
    )

    utilisateur = relationship("Utilisateur")
    cours_attribues: Mapped[list[CoursEnseignant]] = relationship(back_populates="enseignant")


class Cours(Base):
    __tablename__ = "cours"
    __table_args__ = (
        UniqueConstraint("code", "promotion_id", "semestre_id", name="uq_cours_code_promotion_semestre"),
        CheckConstraint("nombre_heures > 0", name="ck_cours_nombre_heures_positif"),
        CheckConstraint("nombre_credits > 0", name="ck_cours_nombre_credits_positif"),
        Index("ix_cours_semestre_id", "semestre_id"),
        Index("ix_cours_promotion_id", "promotion_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(40), nullable=False)
    intitule: Mapped[str] = mapped_column(String(180), nullable=False)
    description: Mapped[str | None] = mapped_column(Text)
    nombre_heures: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    nombre_credits: Mapped[int] = mapped_column(INTEGER(unsigned=True), nullable=False)
    semestre_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("semestres.id", ondelete="RESTRICT"),
        nullable=False,
    )
    promotion_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("promotions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    est_actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True, index=True)

    semestre: Mapped[Semestre] = relationship(back_populates="cours")
    promotion: Mapped[Promotion] = relationship(back_populates="cours")
    enseignants: Mapped[list[CoursEnseignant]] = relationship(back_populates="cours")
    inscriptions: Mapped[list[InscriptionCours]] = relationship(back_populates="cours")


class CoursEnseignant(Base):
    __tablename__ = "cours_enseignants"
    __table_args__ = (
        UniqueConstraint("cours_id", "enseignant_id", "type_intervenant", name="uq_cours_enseignants_intervention"),
        Index("ix_cours_enseignants_enseignant_id", "enseignant_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    cours_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("cours.id", ondelete="RESTRICT"),
        nullable=False,
    )
    enseignant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("enseignants.id", ondelete="RESTRICT"),
        nullable=False,
    )
    type_intervenant: Mapped[str] = mapped_column(
        Enum("professeur", "assistant", "charge_de_cours", name="type_intervenant"),
        nullable=False,
    )
    est_responsable: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    attribue_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    cours: Mapped[Cours] = relationship(back_populates="enseignants")
    enseignant: Mapped[Enseignant] = relationship(back_populates="cours_attribues")


class InscriptionCours(Base):
    __tablename__ = "inscriptions_cours"
    __table_args__ = (
        UniqueConstraint("etudiant_id", "cours_id", "annee_academique_id", name="uq_inscriptions_cours_etudiant_cours_annee"),
        Index("ix_inscriptions_cours_cours_id", "cours_id"),
        Index("ix_inscriptions_cours_annee_academique_id", "annee_academique_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("etudiants.id", ondelete="RESTRICT"),
        nullable=False,
    )
    cours_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("cours.id", ondelete="RESTRICT"),
        nullable=False,
    )
    annee_academique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("annees_academiques.id", ondelete="RESTRICT"),
        nullable=False,
    )
    date_inscription: Mapped[date] = mapped_column(Date, nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum("active", "retiree", "validee", "archivee", name="statut_inscription_cours"),
        nullable=False,
        default="active",
        index=True,
    )

    etudiant: Mapped[Etudiant] = relationship(back_populates="inscriptions_cours")
    cours: Mapped[Cours] = relationship(back_populates="inscriptions")
    annee_academique: Mapped[AnneeAcademique] = relationship()
