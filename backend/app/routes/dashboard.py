from __future__ import annotations

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_un_des_roles
from app.schemas.pagination import ParametresPagination
from app.services import dashboard as service
from app.utilitaires.reponses import reponse_succes


routeur_dashboard = APIRouter(prefix="/dashboard", tags=["dashboard decisionnel"])
acces_dashboard = Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur"))


def _pagination(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
) -> ParametresPagination:
    return ParametresPagination(page=page, taille=taille, recherche=recherche)


@routeur_dashboard.get("/resume")
def route_resume_dashboard(
    _contexte: ContexteUtilisateur = acces_dashboard,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Resume decisionnel recupere", service.obtenir_resume(session))


@routeur_dashboard.get("/cours-difficiles")
def route_cours_difficiles(
    pagination: ParametresPagination = Depends(_pagination),
    promotion_id: int | None = Query(default=None, gt=0),
    _contexte: ContexteUtilisateur = acces_dashboard,
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_cours_difficiles(session, pagination, promotion_id)
    return reponse_succes("Cours difficiles recuperes", donnees)


@routeur_dashboard.get("/performances-promotions")
def route_performances_promotions(
    pagination: ParametresPagination = Depends(_pagination),
    _contexte: ContexteUtilisateur = acces_dashboard,
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_performances_promotions(session, pagination)
    return reponse_succes("Performances par promotion recuperees", donnees)


@routeur_dashboard.get("/reclamations")
def route_reclamations_dashboard(
    _contexte: ContexteUtilisateur = acces_dashboard,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Indicateurs des reclamations recuperes", service.obtenir_reclamations_dashboard(session))


@routeur_dashboard.get("/risques")
def route_risques_dashboard(
    niveau: str | None = Query(default=None, max_length=20),
    _contexte: ContexteUtilisateur = acces_dashboard,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Indicateurs des risques recuperes", service.obtenir_risques_dashboard(session, niveau))
