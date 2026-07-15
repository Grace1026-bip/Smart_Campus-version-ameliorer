from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, CheckConstraint, DateTime, Enum, ForeignKey, Index, Integer, LargeBinary, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT, DECIMAL
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class ProfilBiometrique(Base):
    __tablename__ = "profils_biometriques"
    __table_args__ = (
        UniqueConstraint("cle_profil_actif", name="uq_profils_biometriques_cle_actif"),
        Index("ix_profils_biometriques_etudiant_statut", "etudiant_id", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False
    )
    statut: Mapped[str] = mapped_column(
        Enum("actif", "suspendu", "revoque", name="statut_profil_biometrique"), nullable=False, default="actif"
    )
    version_moteur: Mapped[str] = mapped_column(String(80), nullable=False)
    seuil_utilise: Mapped[float] = mapped_column(DECIMAL(6, 4), nullable=False)
    consentement_enregistre: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    date_consentement: Mapped[datetime | None] = mapped_column(DateTime)
    cree_par_utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False
    )
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    date_modification: Mapped[datetime] = mapped_column(
        DateTime, server_default=func.now(), onupdate=func.now(), nullable=False
    )
    date_revocation: Mapped[datetime | None] = mapped_column(DateTime)
    motif_revocation: Mapped[str | None] = mapped_column(Text)
    cle_profil_actif: Mapped[str | None] = mapped_column(String(80), unique=True)

    etudiant = relationship("Etudiant")
    cree_par_utilisateur = relationship("Utilisateur")
    encodages: Mapped[list[EncodageFacial]] = relationship(
        "EncodageFacial", back_populates="profil_biometrique", cascade="all, delete-orphan"
    )


class EncodageFacial(Base):
    __tablename__ = "encodages_faciaux"
    __table_args__ = (
        CheckConstraint("dimension > 0", name="ck_encodages_faciaux_dimension_positive"),
        Index("ix_encodages_faciaux_profil_actif", "profil_biometrique_id", "actif"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    profil_biometrique_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True), ForeignKey("profils_biometriques.id", ondelete="RESTRICT"), nullable=False
    )
    encodage_binaire: Mapped[bytes] = mapped_column(LargeBinary, nullable=False)
    dimension: Mapped[int] = mapped_column(Integer, nullable=False)
    format: Mapped[str] = mapped_column(String(40), nullable=False, default="float32-le")
    version_moteur: Mapped[str] = mapped_column(String(80), nullable=False)
    actif: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    empreinte_integrite: Mapped[str] = mapped_column(String(64), nullable=False)
    date_creation: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    profil_biometrique: Mapped[ProfilBiometrique] = relationship(back_populates="encodages")
