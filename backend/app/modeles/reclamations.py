from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class Reclamation(Base):
    __tablename__ = "reclamations"
    __table_args__ = (
        Index("ix_reclamations_etudiant_id", "etudiant_id"),
        Index("ix_reclamations_cours_id", "cours_id"),
        Index("ix_reclamations_note_id", "note_id"),
        Index("ix_reclamations_statut", "statut"),
        Index("ix_reclamations_assignee_a", "assignee_a"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    etudiant_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("etudiants.id", ondelete="RESTRICT"), nullable=False)
    cours_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="SET NULL"))
    note_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("notes.id", ondelete="SET NULL"))
    categorie: Mapped[str] = mapped_column(
        Enum("erreur_note", "inscription", "cours", "document_academique", "autre", name="categorie_reclamation"),
        nullable=False,
    )
    objet: Mapped[str] = mapped_column(String(180), nullable=False)
    description: Mapped[str] = mapped_column(Text, nullable=False)
    statut: Mapped[str] = mapped_column(
        Enum("en_attente", "en_cours", "resolue", "rejetee", name="statut_reclamation"),
        nullable=False,
        default="en_attente",
    )
    priorite: Mapped[str] = mapped_column(
        Enum("faible", "normale", "elevee", "urgente", name="priorite_reclamation"),
        nullable=False,
        default="normale",
    )
    assignee_a: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="SET NULL"))
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)
    resolue_le: Mapped[datetime | None] = mapped_column(DateTime)

    messages: Mapped[list[MessageReclamation]] = relationship(back_populates="reclamation")
    historiques: Mapped[list[HistoriqueReclamation]] = relationship(back_populates="reclamation")


class MessageReclamation(Base):
    __tablename__ = "messages_reclamations"
    __table_args__ = (
        Index("ix_messages_reclamations_reclamation_id", "reclamation_id"),
        Index("ix_messages_reclamations_auteur_id", "auteur_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    reclamation_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("reclamations.id", ondelete="CASCADE"),
        nullable=False,
    )
    auteur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    message: Mapped[str] = mapped_column(Text, nullable=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    est_interne: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    reclamation: Mapped[Reclamation] = relationship(back_populates="messages")
    auteur = relationship("Utilisateur")


class HistoriqueReclamation(Base):
    __tablename__ = "historiques_reclamations"
    __table_args__ = (
        Index("ix_historiques_reclamations_reclamation_id", "reclamation_id"),
        Index("ix_historiques_reclamations_modifie_par", "modifie_par"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    reclamation_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("reclamations.id", ondelete="CASCADE"),
        nullable=False,
    )
    ancien_statut: Mapped[str | None] = mapped_column(String(40))
    nouveau_statut: Mapped[str] = mapped_column(String(40), nullable=False)
    modifie_par: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    commentaire: Mapped[str | None] = mapped_column(Text)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    reclamation: Mapped[Reclamation] = relationship(back_populates="historiques")
    auteur_modification = relationship("Utilisateur")
