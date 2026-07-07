from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class PublicationValve(Base):
    __tablename__ = "publications_valve"
    __table_args__ = (
        Index("ix_publications_valve_cours_id", "cours_id"),
        Index("ix_publications_valve_auteur_id", "auteur_id"),
        Index("ix_publications_valve_statut", "statut"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    cours_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("cours.id", ondelete="RESTRICT"), nullable=False)
    auteur_id: Mapped[int] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="RESTRICT"), nullable=False)
    type_publication: Mapped[str] = mapped_column(
        Enum(
            "annonce",
            "communique",
            "devoir",
            "support_de_cours",
            "changement_horaire",
            "consigne_examen",
            "rappel",
            "publication_notes",
            name="type_publication_valve",
        ),
        nullable=False,
    )
    titre: Mapped[str] = mapped_column(String(180), nullable=False)
    contenu: Mapped[str] = mapped_column(Text, nullable=False)
    est_importante: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    statut: Mapped[str] = mapped_column(
        Enum("brouillon", "publiee", "archivee", name="statut_publication_valve"),
        nullable=False,
        default="brouillon",
    )
    publie_le: Mapped[datetime | None] = mapped_column(DateTime)
    modifie_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), onupdate=func.now(), nullable=False)

    cours = relationship("Cours")
    auteur = relationship("Utilisateur")
    pieces_jointes: Mapped[list[PieceJointePublication]] = relationship(back_populates="publication")
    lectures: Mapped[list[LecturePublication]] = relationship(back_populates="publication")


class PieceJointePublication(Base):
    __tablename__ = "pieces_jointes_publications"
    __table_args__ = (
        Index("ix_pieces_jointes_publications_publication_id", "publication_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    publication_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("publications_valve.id", ondelete="CASCADE"),
        nullable=False,
    )
    nom_original: Mapped[str] = mapped_column(String(255), nullable=False)
    nom_stockage: Mapped[str] = mapped_column(String(190), nullable=False, unique=True)
    chemin: Mapped[str] = mapped_column(String(500), nullable=False)
    type_mime: Mapped[str] = mapped_column(String(120), nullable=False)
    taille: Mapped[int] = mapped_column(BIGINT(unsigned=True), nullable=False)
    est_archivee: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False, index=True)
    ajoute_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    archivee_le: Mapped[datetime | None] = mapped_column(DateTime)

    publication: Mapped[PublicationValve] = relationship(back_populates="pieces_jointes")


class LecturePublication(Base):
    __tablename__ = "lectures_publications"
    __table_args__ = (
        UniqueConstraint("publication_id", "utilisateur_id", name="uq_lectures_publications_publication_utilisateur"),
        Index("ix_lectures_publications_utilisateur_id", "utilisateur_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    publication_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("publications_valve.id", ondelete="CASCADE"),
        nullable=False,
    )
    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="CASCADE"),
        nullable=False,
    )
    lu_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    publication: Mapped[PublicationValve] = relationship(back_populates="lectures")
    utilisateur = relationship("Utilisateur")
