from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, obtenir_utilisateur_connecte
from app.schemas.notifications import TypeNotification
from app.schemas.pagination import ParametresPagination
from app.services import notifications as service
from app.utilitaires.reponses import reponse_succes


routeur_notifications = APIRouter(prefix="/notifications", tags=["notifications"])


def _pagination(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
) -> ParametresPagination:
    return ParametresPagination(page=page, taille=taille, recherche=recherche)


@routeur_notifications.get("")
def route_lister_notifications(
    pagination: ParametresPagination = Depends(_pagination),
    est_lue: bool | None = None,
    type_notification: TypeNotification | None = None,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_notifications(
        session,
        contexte.utilisateur.id,
        pagination,
        est_lue,
        type_notification,
    )
    return reponse_succes("Notifications recuperees", donnees)


@routeur_notifications.get("/non-lues/compteur")
def route_compter_notifications_non_lues(
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Compteur de notifications recupere",
        service.compter_notifications_non_lues(session, contexte.utilisateur.id),
    )


@routeur_notifications.post("/tout-lire")
def route_marquer_toutes_notifications_lues(
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Notifications marquees comme lues",
        service.marquer_toutes_notifications_lues(session, contexte.utilisateur.id),
    )


@routeur_notifications.post("/{notification_id}/lire")
def route_marquer_notification_lue(
    notification_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    notification = service.marquer_notification_lue(session, contexte.utilisateur.id, notification_id)
    return reponse_succes("Notification marquee comme lue", {"notification": notification})
