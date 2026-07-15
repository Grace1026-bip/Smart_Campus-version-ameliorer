from __future__ import annotations

from datetime import date, datetime, time
from decimal import Decimal

from sqlalchemy import CheckConstraint, Date, DateTime, Enum, ForeignKey, Index, Numeric, Text, Time, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class SeanceAcademique(Base):
    __tablename__ = "seances_academiques"
    __table_args__ = (
        UniqueConstraint(
            "cours_id", "date_seance", "type_cours", name="uq_seances_academiques_cours_date_type"
        ),
        CheckConstraint(
            "heure_fin IS NULL OR heure_debut IS NULL OR heure_fin > heure_debut",
            name="ck_seances_academiques_heures_coherentes",
        ),
        Index("ix_seances_academiques_promotion_date", "promotion_id", "date_seance"),
        Index("ix_seances_academiques_statut", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    cours_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="RESTRICT"), nullable=False
    )
    promotion_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("promotions.id", ondelete="RESTRICT"), nullable=False
    )
    enseignant_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("enseignants.id", ondelete="RESTRICT")
    )
    annee_academique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("annees_academiques.id", ondelete="RESTRICT"), nullable=False
    )
    semestre_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("semestres.id", ondelete="RESTRICT"), nullable=False
    )
    date_seance: Mapped[date] = mapped_column(Date, nullable=False)
    heure_debut: Mapped[time | None] = mapped_column(Time)
    heure_fin: Mapped[time | None] = mapped_column(Time)
    type_cours: Mapped[str] = mapped_column(
        Enum("cours_1", "cours_2", "autre", name="type_cours_seance"), nullable=False
    )
    statut: Mapped[str] = mapped_column(
        Enum("planifiee", "ouverte", "fermee", "annulee", name="statut_seance_academique"),
        nullable=False,
        default="planifiee",
    )
    ouverte_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT")
    )
    date_ouverture: Mapped[datetime | None] = mapped_column(DateTime)
    date_fermeture: Mapped[datetime | None] = mapped_column(DateTime)
    fermee_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT")
    )
    confirme_cours_2_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT")
    )
    confirme_cours_2_le: Mapped[datetime | None] = mapped_column(DateTime)
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    date_modification: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    cours = relationship("Cours")
    promotion = relationship("Promotion")
    enseignant = relationship("Enseignant")
    annee_academique = relationship("AnneeAcademique")
    semestre = relationship("Semestre")
    ouverte_par = relationship("Utilisateur", foreign_keys=[ouverte_par_utilisateur_id])
    fermee_par = relationship("Utilisateur", foreign_keys=[fermee_par_utilisateur_id])
    confirme_cours_2_par = relationship("Utilisateur", foreign_keys=[confirme_cours_2_par_utilisateur_id])
    presences = relationship("PresenceAcademique", back_populates="seance", cascade="all, delete-orphan")


class PresenceAcademique(Base):
    __tablename__ = "presences_academiques"
    __table_args__ = (
        UniqueConstraint("seance_id", "etudiant_id", name="uq_presences_academiques_seance_etudiant"),
        Index("ix_presences_academiques_etudiant", "etudiant_id"),
        Index("ix_presences_academiques_statut", "statut"),
        CheckConstraint(
            "pourcentage_paiement_observe IS NULL OR (pourcentage_paiement_observe >= 0 AND pourcentage_paiement_observe <= 100)",
            name="ck_presences_academiques_paiement_valide",
        ),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    seance_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("seances_academiques.id", ondelete="CASCADE"), nullable=False
    )
    etudiant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False
    )
    statut: Mapped[str] = mapped_column(
        Enum("present", "retard", "absent", "refuse", name="statut_presence_academique"),
        nullable=False,
    )
    heure_identification: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    heure_enregistrement: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    methode_identification: Mapped[str] = mapped_column(
        Enum(
            "manuelle",
            "matricule",
            "future_reconnaissance_faciale",
            "reconnaissance_faciale",
            name="methode_identification_presence",
        ),
        nullable=False,
        default="matricule",
    )
    enregistre_par_utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False
    )
    motif_refus: Mapped[str | None] = mapped_column(
        Enum(
            "autorise",
            "paiement_insuffisant",
            "etudiant_inactif",
            "non_enrole",
            "mauvaise_promotion",
            "seance_fermee",
            "deja_enregistre",
            "etudiant_introuvable",
            name="motif_refus_presence",
        )
    )
    pourcentage_paiement_observe: Mapped[Decimal | None] = mapped_column(Numeric(5, 2))
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    date_modification: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )

    seance = relationship("SeanceAcademique", back_populates="presences")
    etudiant = relationship("Etudiant")
    enregistre_par = relationship("Utilisateur")
    corrections = relationship(
        "CorrectionPresenceAcademique",
        back_populates="presence",
        cascade="all, delete-orphan",
        order_by="CorrectionPresenceAcademique.date_correction",
    )


class CorrectionPresenceAcademique(Base):
    __tablename__ = "corrections_presences_academiques"
    __table_args__ = (
        Index("ix_corrections_presences_presence_id", "presence_id"),
        Index("ix_corrections_presences_seance_etudiant", "seance_id", "etudiant_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    presence_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("presences_academiques.id", ondelete="RESTRICT"), nullable=False
    )
    seance_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("seances_academiques.id", ondelete="RESTRICT"), nullable=False
    )
    etudiant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False
    )
    ancien_statut: Mapped[str] = mapped_column(
        Enum("present", "retard", "absent", "refuse", name="ancien_statut_presence_academique"), nullable=False
    )
    nouveau_statut: Mapped[str] = mapped_column(
        Enum("present", "retard", "absent", "refuse", name="nouveau_statut_presence_academique"), nullable=False
    )
    motif: Mapped[str] = mapped_column(Text, nullable=False)
    corrige_par_utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False
    )
    date_correction: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    presence = relationship("PresenceAcademique", back_populates="corrections")
    seance = relationship("SeanceAcademique")
    etudiant = relationship("Etudiant")
    corrige_par = relationship("Utilisateur")
