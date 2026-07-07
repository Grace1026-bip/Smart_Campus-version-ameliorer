from __future__ import annotations

from datetime import datetime

from sqlalchemy import DateTime, ForeignKey, Index, JSON, String, func
from sqlalchemy.dialects.mysql import BIGINT
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.base_de_donnees.base import Base


class JournalAudit(Base):
    __tablename__ = "journaux_audit"
    __table_args__ = (
        Index("ix_journaux_audit_utilisateur_id", "utilisateur_id"),
        Index("ix_journaux_audit_entite", "entite", "entite_id"),
    )

    id: Mapped[int] = mapped_column(BIGINT(unsigned=True), primary_key=True, autoincrement=True)
    utilisateur_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True), ForeignKey("utilisateurs.id", ondelete="SET NULL"))
    action: Mapped[str] = mapped_column(String(100), nullable=False)
    entite: Mapped[str] = mapped_column(String(100), nullable=False)
    entite_id: Mapped[int | None] = mapped_column(BIGINT(unsigned=True))
    details_json: Mapped[dict | None] = mapped_column(JSON)
    cree_le: Mapped[datetime] = mapped_column(DateTime, server_default=func.now(), nullable=False)

    utilisateur = relationship("Utilisateur")
