from __future__ import annotations

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.exceptions.erreurs import RessourceIntrouvable
from app.modeles.notifications import Notification
from app.schemas.pagination import ParametresPagination, construire_page


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


def _maintenant() -> datetime:
    return datetime.utcnow()


def _serialiser_notification(notification: Notification) -> dict:
    return {
        "id": notification.id,
        "utilisateur_id": notification.utilisateur_id,
        "type_notification": notification.type_notification,
        "titre": notification.titre,
        "contenu": notification.contenu,
        "donnees_json": notification.donnees_json,
        "est_lue": notification.est_lue,
        "cree_le": notification.cree_le,
        "lue_le": notification.lue_le,
    }


def _requete_notifications(utilisateur_id: int, est_lue: bool | None = None, type_notification: str | None = None):
    requete = select(Notification).where(Notification.utilisateur_id == utilisateur_id)
    conditions = [Notification.utilisateur_id == utilisateur_id]
    if est_lue is not None:
        conditions.append(Notification.est_lue.is_(est_lue))
        requete = requete.where(Notification.est_lue.is_(est_lue))
    if type_notification:
        conditions.append(Notification.type_notification == type_notification)
        requete = requete.where(Notification.type_notification == type_notification)
    return requete, conditions


def lister_notifications(
    session: Session,
    utilisateur_id: int,
    pagination: ParametresPagination,
    est_lue: bool | None = None,
    type_notification: str | None = None,
) -> dict:
    requete, conditions = _requete_notifications(utilisateur_id, est_lue, type_notification)
    total = session.scalar(select(func.count()).select_from(Notification).where(*conditions)) or 0
    notifications = session.scalars(
        requete.order_by(Notification.cree_le.desc()).offset(pagination.offset).limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_notification(notification) for notification in notifications],
        total,
        pagination.page,
        pagination.taille,
    )


def compter_notifications_non_lues(session: Session, utilisateur_id: int) -> dict:
    total = session.scalar(
        select(func.count()).select_from(Notification).where(
            Notification.utilisateur_id == utilisateur_id,
            Notification.est_lue.is_(False),
        )
    ) or 0
    par_type = {}
    lignes = session.execute(
        select(Notification.type_notification, func.count())
        .where(Notification.utilisateur_id == utilisateur_id, Notification.est_lue.is_(False))
        .group_by(Notification.type_notification)
    ).all()
    for type_notification, nombre in lignes:
        par_type[type_notification] = int(nombre)
    return {"total_non_lues": int(total), "par_type": par_type}


def obtenir_notification_utilisateur(session: Session, utilisateur_id: int, notification_id: int) -> Notification:
    notification = session.scalar(
        select(Notification).where(
            Notification.id == notification_id,
            Notification.utilisateur_id == utilisateur_id,
        )
    )
    if notification is None:
        raise RessourceIntrouvable("Notification introuvable")
    return notification


def marquer_notification_lue(session: Session, utilisateur_id: int, notification_id: int) -> dict:
    notification = obtenir_notification_utilisateur(session, utilisateur_id, notification_id)
    if not notification.est_lue:
        notification.est_lue = True
        notification.lue_le = _maintenant()
        session.commit()
        session.refresh(notification)
    return _serialiser_notification(notification)


def marquer_toutes_notifications_lues(session: Session, utilisateur_id: int) -> dict:
    notifications = session.scalars(
        select(Notification).where(Notification.utilisateur_id == utilisateur_id, Notification.est_lue.is_(False))
    ).all()
    moment = _maintenant()
    for notification in notifications:
        notification.est_lue = True
        notification.lue_le = moment
    session.commit()
    return {"nombre_mises_a_jour": len(notifications)}
