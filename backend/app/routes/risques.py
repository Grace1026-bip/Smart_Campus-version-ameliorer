from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_un_des_roles
from app.schemas.pagination import ParametresPagination
from app.schemas.risques import PresenceLotCreation, RecalculRisquesRequete
from app.services import risques as service
from app.utilitaires.reponses import reponse_succes


routeur_risques = APIRouter(tags=["risques academiques"])


def _pagination(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
) -> ParametresPagination:
    return ParametresPagination(page=page, taille=taille, recherche=recherche)


@routeur_risques.post("/enseignant/cours/{cours_id}/presences", status_code=status.HTTP_201_CREATED)
def route_enregistrer_presences(
    cours_id: int,
    donnees: PresenceLotCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    resultat = service.enregistrer_presences_cours(session, contexte.utilisateur.id, cours_id, donnees)
    return reponse_succes("Presences enregistrees", resultat, status.HTTP_201_CREATED)


@routeur_risques.get("/enseignant/cours/{cours_id}/risques")
def route_risques_cours_enseignant(
    cours_id: int,
    pagination: ParametresPagination = Depends(_pagination),
    niveau: str | None = Query(default=None, max_length=20),
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_risques_cours_enseignant(
        session,
        contexte.utilisateur.id,
        cours_id,
        pagination,
        niveau,
    )
    return reponse_succes("Risques du cours recuperes", donnees)


@routeur_risques.post("/enseignant/cours/{cours_id}/risques/recalculer")
def route_recalculer_risques_cours(
    cours_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.recalculer_risques_cours(session, contexte.utilisateur.id, cours_id)
    return reponse_succes("Risques recalcules", donnees)


@routeur_risques.get("/etudiant/risques")
def route_risques_etudiant(
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Risques recuperes", service.lister_risques_etudiant(session, contexte.utilisateur.id))


@routeur_risques.get("/etudiant/cours/{cours_id}/risques")
def route_risques_cours_etudiant(
    cours_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_risques_etudiant(session, contexte.utilisateur.id, cours_id)
    return reponse_succes("Risques du cours recuperes", donnees)


@routeur_risques.get("/risques")
def route_lister_risques_global(
    pagination: ParametresPagination = Depends(_pagination),
    promotion_id: int | None = Query(default=None, gt=0),
    cours_id: int | None = Query(default=None, gt=0),
    niveau: str | None = Query(default=None, max_length=20),
    est_active: bool | None = True,
    _contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_risques_global(session, pagination, promotion_id, cours_id, niveau, est_active)
    return reponse_succes("Risques recuperes", donnees)


@routeur_risques.post("/risques/recalculer")
def route_recalculer_risques_global(
    donnees: RecalculRisquesRequete,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    resultat = service.recalculer_risques_global(session, contexte.utilisateur.id, donnees)
    return reponse_succes("Risques recalcules", resultat)
