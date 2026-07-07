from __future__ import annotations

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Enum, ForeignKey, Index, JSON, String, Text, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class Notification(Base):
    __tablename__ = "notifications"
    __table_args__ = (
        Index("ix_notifications_utilisateur_id", "utilisateur_id"),
        Index("ix_notifications_est_lue", "est_lue"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    utilisateur_id: Mapped[int] = mapped_column(
        BIGINT(unsigned=True),
        ForeignKey("utilisateurs.id", ondelete="CASCADE"),
        nullable=False,
    )
    type_notification: Mapped[str] = mapped_column(
        Enum(
            "nouvelle_note",
            "nouvelle_publication",
            "reclamation_mise_a_jour",
            "alerte_academique",
            "information_systeme",
            name="type_notification",
        ),
        nullable=False,
    )
    titre: Mapped[str] = mapped_column(String(180), nullable=False)
    contenu: Mapped[str] = mapped_column(Text, nullable=False)
    donnees_json: Mapped[dict | None] = mapped_column(JSON)
    est_lue: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)
    lue_le: Mapped[datetime | None] = mapped_column(DateTime)

    utilisateur = relationship("Utilisateur")
