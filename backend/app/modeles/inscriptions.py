from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class DemandeInscription(Base):
    __tablename__ = "demandes_inscription"
    __table_args__ = (
        UniqueConstraint("reference", name="uq_demandes_inscription_reference"),
        Index("ix_demandes_inscription_email", "email"),
        Index("ix_demandes_inscription_statut", "statut"),
        Index("ix_demandes_inscription_type_statut", "type_demande", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    reference: Mapped[str] = mapped_column(String(40), nullable=False)
    type_demande: Mapped[str] = mapped_column(
        Enum("etudiant", "enseignant", name="type_demande_inscription"),
        nullable=False,
    )
    email: Mapped[str] = mapped_column(String(190), nullable=False)
    nom: Mapped[str] = mapped_column(String(100), nullable=False)
    postnom: Mapped[str | None] = mapped_column(String(100))
    prenom: Mapped[str | None] = mapped_column(String(100))
    telephone: Mapped[str | None] = mapped_column(String(30))
    mot_de_passe_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    matricule: Mapped[str | None] = mapped_column(String(80))
    promotion_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("promotions.id", ondelete="RESTRICT"),
    )
    matricule_agent: Mapped[str | None] = mapped_column(String(80))
    grade: Mapped[str | None] = mapped_column(String(100))
    departement: Mapped[str | None] = mapped_column(String(150))
    statut: Mapped[str] = mapped_column(
        Enum("en_attente", "approuvee", "rejetee", name="statut_demande_inscription"),
        nullable=False,
        default="en_attente",
    )
    utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="SET NULL"),
    )
    traite_par_utilisateur_id: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="SET NULL"),
    )
    motif_rejet: Mapped[str | None] = mapped_column(Text)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    traite_le: Mapped[datetime | None] = mapped_column(DateTime)

    promotion = relationship("Promotion")
    utilisateur = relationship("Utilisateur", foreign_keys=[utilisateur_id])
    traite_par = relationship("Utilisateur", foreign_keys=[traite_par_utilisateur_id])
