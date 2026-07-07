from __future__ import annotations

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_un_des_roles
from app.schemas.pagination import ParametresPagination
from app.schemas.reclamations import MessageReclamationCreation, ReclamationCreation, TraitementReclamation
from app.services import reclamations as service
from app.utilitaires.reponses import reponse_succes


routeur_reclamations = APIRouter(tags=["reclamations"])


def _pagination(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
) -> ParametresPagination:
    return ParametresPagination(page=page, taille=taille, recherche=recherche)


@routeur_reclamations.post("/etudiant/reclamations", status_code=status.HTTP_201_CREATED)
def route_creer_reclamation(
    donnees: ReclamationCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    reclamation = service.creer_reclamation(session, contexte.utilisateur.id, donnees)
    return reponse_succes("Reclamation creee", {"reclamation": reclamation}, status.HTTP_201_CREATED)


@routeur_reclamations.get("/etudiant/reclamations")
def route_lister_reclamations_etudiant(
    pagination: ParametresPagination = Depends(_pagination),
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Reclamations recuperees",
        service.lister_reclamations_etudiant(session, contexte.utilisateur.id, pagination),
    )


@routeur_reclamations.get("/etudiant/reclamations/{reclamation_id}")
def route_obtenir_reclamation_etudiant(
    reclamation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    reclamation = service.obtenir_reclamation_etudiant(session, contexte.utilisateur.id, reclamation_id)
    return reponse_succes("Reclamation recuperee", {"reclamation": reclamation})


@routeur_reclamations.post("/etudiant/reclamations/{reclamation_id}/messages", status_code=status.HTTP_201_CREATED)
def route_message_reclamation_etudiant(
    reclamation_id: int,
    donnees: MessageReclamationCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    message = service.ajouter_message_etudiant(session, contexte.utilisateur.id, reclamation_id, donnees)
    return reponse_succes("Message ajoute", {"message": message}, status.HTTP_201_CREATED)


@routeur_reclamations.get("/reclamations")
def route_lister_reclamations_traitement(
    pagination: ParametresPagination = Depends(_pagination),
    statut_reclamation: str | None = Query(default=None, alias="statut", max_length=40),
    categorie: str | None = Query(default=None, max_length=60),
    cours_id: int | None = Query(default=None, gt=0),
    etudiant_id: int | None = Query(default=None, gt=0),
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant", "appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_reclamations_traitement(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        pagination,
        statut_reclamation,
        categorie,
        cours_id,
        etudiant_id,
    )
    return reponse_succes("Reclamations recuperees", donnees)


@routeur_reclamations.get("/reclamations/{reclamation_id}")
def route_obtenir_reclamation_traitement(
    reclamation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant", "appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    reclamation = service.obtenir_reclamation_traitement(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        reclamation_id,
    )
    return reponse_succes("Reclamation recuperee", {"reclamation": reclamation})


@routeur_reclamations.post("/reclamations/{reclamation_id}/messages", status_code=status.HTTP_201_CREATED)
def route_message_reclamation_traitement(
    reclamation_id: int,
    donnees: MessageReclamationCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant", "appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    message = service.ajouter_message_traitement(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        reclamation_id,
        donnees,
    )
    return reponse_succes("Message ajoute", {"message": message}, status.HTTP_201_CREATED)


@routeur_reclamations.put("/reclamations/{reclamation_id}/traitement")
def route_traiter_reclamation(
    reclamation_id: int,
    donnees: TraitementReclamation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant", "appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    reclamation = service.traiter_reclamation(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        reclamation_id,
        donnees,
    )
    return reponse_succes("Reclamation traitee", {"reclamation": reclamation})
