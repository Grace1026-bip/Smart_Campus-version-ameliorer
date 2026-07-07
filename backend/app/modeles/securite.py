from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, String, Text, UniqueConstraint, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class Utilisateur(Base):
    __tablename__ = "utilisateurs"

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(String(100), nullable=False)
    postnom: Mapped[str | None] = mapped_column(String(100))
    prenom: Mapped[str | None] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(190), nullable=False, unique=True, index=True)
    mot_de_passe_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    telephone: Mapped[str | None] = mapped_column(String(30))
    photo: Mapped[str | None] = mapped_column(String(255))
    statut: Mapped[str] = mapped_column(
        Enum("en_attente", "actif", "bloque", "rejete", "archive", name="statut_utilisateur"),
        nullable=False,
        default="en_attente",
        index=True,
    )
    derniere_connexion: Mapped[datetime | None] = mapped_column(DateTime)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    modifie_le: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=func.now(),
        onupdate=func.now(),
        nullable=False,
    )

    roles: Mapped[list[UtilisateurRole]] = relationship(
        back_populates="utilisateur",
        cascade="all, delete-orphan",
        foreign_keys="UtilisateurRole.utilisateur_id",
    )
    jetons_actualisation: Mapped[list[JetonActualisation]] = relationship(
        back_populates="utilisateur",
        cascade="all, delete-orphan",
    )


class Role(Base):
    __tablename__ = "roles"

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    nom: Mapped[str] = mapped_column(String(60), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text)

    utilisateurs: Mapped[list[UtilisateurRole]] = relationship(back_populates="role", cascade="all, delete-orphan")
    permissions: Mapped[list[RolePermission]] = relationship(back_populates="role", cascade="all, delete-orphan")


class Permission(Base):
    __tablename__ = "permissions"

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    code: Mapped[str] = mapped_column(String(100), nullable=False, unique=True)
    description: Mapped[str | None] = mapped_column(Text)

    roles: Mapped[list[RolePermission]] = relationship(back_populates="permission", cascade="all, delete-orphan")


class UtilisateurRole(Base):
    __tablename__ = "utilisateur_roles"
    __table_args__ = (
        UniqueConstraint("utilisateur_id", "role_id", name="uq_utilisateur_roles_utilisateur_role"),
        Index("ix_utilisateur_roles_role_id", "role_id"),
    )

    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="CASCADE"),
        primary_key=True,
    )
    role_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("roles.id", ondelete="RESTRICT"),
        primary_key=True,
    )
    attribue_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    attribue_par: Mapped[int | None] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="SET NULL"),
    )

    utilisateur: Mapped[Utilisateur] = relationship(
        back_populates="roles",
        foreign_keys=[utilisateur_id],
    )
    role: Mapped[Role] = relationship(back_populates="utilisateurs")
    attribue_par_utilisateur: Mapped[Utilisateur | None] = relationship(foreign_keys=[attribue_par])


class RolePermission(Base):
    __tablename__ = "role_permissions"
    __table_args__ = (
        UniqueConstraint("role_id", "permission_id", name="uq_role_permissions_role_permission"),
        Index("ix_role_permissions_permission_id", "permission_id"),
    )

    role_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("roles.id", ondelete="CASCADE"),
        primary_key=True,
    )
    permission_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("permissions.id", ondelete="CASCADE"),
        primary_key=True,
    )

    role: Mapped[Role] = relationship(back_populates="permissions")
    permission: Mapped[Permission] = relationship(back_populates="roles")


class JetonActualisation(Base):
    __tablename__ = "jetons_actualisation"
    __table_args__ = (
        Index("ix_jetons_actualisation_utilisateur_id", "utilisateur_id"),
        Index("ix_jetons_actualisation_expiration", "expiration"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="CASCADE"),
        nullable=False,
    )
    jeton_hash: Mapped[str] = mapped_column(String(190), nullable=False, unique=True)
    expiration: Mapped[datetime] = mapped_column(DateTime, nullable=False)
    est_revoque: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    revoque_le: Mapped[datetime | None] = mapped_column(DateTime)
    appareil: Mapped[str | None] = mapped_column(String(255))
    adresse_ip: Mapped[str | None] = mapped_column(String(45))

    utilisateur: Mapped[Utilisateur] = relationship(back_populates="jetons_actualisation")
