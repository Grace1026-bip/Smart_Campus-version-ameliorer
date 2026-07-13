from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role
from app.services import enseignants as service
from app.services import projets as service_projets
from app.utilitaires.reponses import reponse_succes


routeur_enseignants = APIRouter(prefix="/enseignants", tags=["espace enseignant"])
lecture_enseignant = Depends(exiger_role("enseignant"))


@routeur_enseignants.get("/moi")
def route_profil_enseignant(
    contexte: ContexteUtilisateur = lecture_enseignant,
    session: Session = Depends(obtenir_session),
):
    profil = service.obtenir_profil(session, contexte.utilisateur.id, contexte.role_actif)
    return reponse_succes("Profil enseignant recupere", profil)


@routeur_enseignants.get("/moi/cours")
def route_lister_cours_enseignant(
    contexte: ContexteUtilisateur = lecture_enseignant,
    session: Session = Depends(obtenir_session),
):
    elements = service.lister_cours(session, contexte.utilisateur.id)
    return reponse_succes("Cours enseignant recuperes", {"elements": elements, "total": len(elements)})


@routeur_enseignants.get("/moi/cours/{cours_id}")
def route_obtenir_cours_enseignant(
    cours_id: int,
    contexte: ContexteUtilisateur = lecture_enseignant,
    session: Session = Depends(obtenir_session),
):
    cours = service.obtenir_cours(session, contexte.utilisateur.id, cours_id)
    return reponse_succes("Cours enseignant recupere", cours)


@routeur_enseignants.get("/moi/encadrements")
def route_lister_encadrements_enseignant(
    type_projet: str | None = Query(default=None, max_length=40),
    statut: str | None = Query(default=None, max_length=30),
    annee_academique_id: int | None = Query(default=None, gt=0),
    recherche: str | None = Query(default=None, max_length=120),
    contexte: ContexteUtilisateur = lecture_enseignant,
    session: Session = Depends(obtenir_session),
):
    elements = service_projets.lister_encadrements(
        session,
        contexte.utilisateur.id,
        type_projet=type_projet,
        statut=statut,
        annee_academique_id=annee_academique_id,
        recherche=recherche,
    )
    return reponse_succes(
        "Encadrements enseignant recuperes",
        {"elements": elements, "total": len(elements)},
    )


@routeur_enseignants.get("/moi/encadrements/{encadrement_id}")
def route_obtenir_encadrement_enseignant(
    encadrement_id: int,
    contexte: ContexteUtilisateur = lecture_enseignant,
    session: Session = Depends(obtenir_session),
):
    encadrement = service_projets.obtenir_encadrement(
        session,
        contexte.utilisateur.id,
        encadrement_id,
    )
    return reponse_succes("Encadrement enseignant recupere", encadrement)
