from __future__ import annotations

from sqlalchemy.orm import Session

from app.modeles.notifications import Notification


def creer_notification(
    session: Session,
    utilisateur_id: int,
    type_notification: str,
    titre: str,
    contenu: str,
    donnees_json: dict | None = None,
) -> Notification:
    notification = Notification(
        utilisateur_id=utilisateur_id,
        type_notification=type_notification,
        titre=titre,
        contenu=contenu,
        donnees_json=donnees_json,
        est_lue=False,
    )
    session.add(notification)
    return notification
