from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import CheckConstraint, Date, DateTime, Enum, ForeignKey, Index, Numeric, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


STATUTS_ENROLEMENT = ("en_attente", "valide", "annule")


class EnrolementAcademique(Base):
    __tablename__ = "enrolements_academiques"
    __table_args__ = (
        UniqueConstraint("reference_fiche", name="uq_enrolements_academiques_reference"),
        Index("ix_enrolements_academiques_etudiant_annee", "etudiant_id", "annee_academique_id"),
        Index("ix_enrolements_academiques_promotion_statut", "promotion_id", "statut"),
        CheckConstraint(
            "pourcentage_paiement >= 0 AND pourcentage_paiement <= 100",
            name="ck_enrolements_academiques_paiement_valide",
        ),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("etudiants.id", ondelete="RESTRICT"),
        nullable=False,
    )
    promotion_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("promotions.id", ondelete="RESTRICT"),
        nullable=False,
    )
    annee_academique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("annees_academiques.id", ondelete="RESTRICT"),
        nullable=False,
    )
    date_enrolement: Mapped[date] = mapped_column(Date, nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum(*STATUTS_ENROLEMENT, name="statut_enrolement_academique"),
        nullable=False,
        default="en_attente",
        index=True,
    )
    cree_par_utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
        nullable=False,
    )
    valide_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
    )
    annule_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="RESTRICT"),
    )
    reference_fiche: Mapped[str] = mapped_column(String(80), nullable=False)
    date_validation: Mapped[datetime | None] = mapped_column(DateTime)
    date_annulation: Mapped[datetime | None] = mapped_column(DateTime)
    motif_annulation: Mapped[str | None] = mapped_column(Text)
    # Administrative percentage read by access control; no payment operation is performed here.
    pourcentage_paiement: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), nullable=False, default=Decimal("0.00"), server_default="0.00"
    )
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    date_modification: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )
    # Null for an annulled record, unique for every active lifecycle.
    cle_doublon_actif: Mapped[str | None] = mapped_column(String(180), unique=True)

    etudiant = relationship("Etudiant")
    promotion = relationship("Promotion")
    annee_academique = relationship("AnneeAcademique")
    cree_par_utilisateur = relationship("Utilisateur", foreign_keys=[cree_par_utilisateur_id])
    valide_par_utilisateur = relationship("Utilisateur", foreign_keys=[valide_par_utilisateur_id])
    annule_par_utilisateur = relationship("Utilisateur", foreign_keys=[annule_par_utilisateur_id])
