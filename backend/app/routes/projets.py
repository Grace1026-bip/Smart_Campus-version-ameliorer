from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role
from app.schemas.projets import (
    EncadrementCreation,
    EncadrementModification,
    ProjetCreation,
    ProjetModification,
    SpecialitesEnseignantModification,
)
from app.services import projets as service
from app.utilitaires.reponses import reponse_succes


routeur_projets_appariteur = APIRouter(prefix="/appariteur", tags=["projets appariteur"])
gestion_appariteur = Depends(exiger_role("appariteur"))


@routeur_projets_appariteur.get("/projets")
def route_lister_projets(
    type_projet: str | None = Query(default=None, max_length=40),
    promotion_id: int | None = Query(default=None, gt=0),
    annee_academique_id: int | None = Query(default=None, gt=0),
    statut: str | None = Query(default=None, max_length=30),
    etudiant_id: int | None = Query(default=None, gt=0),
    enseignant_id: int | None = Query(default=None, gt=0),
    recherche: str | None = Query(default=None, max_length=120),
    sans_encadreur: bool = False,
    avec_encadreur: bool = False,
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Projets academiques recuperes",
        service.lister_projets_appariteur(
            session,
            type_projet=type_projet,
            promotion_id=promotion_id,
            annee_academique_id=annee_academique_id,
            statut=statut,
            etudiant_id=etudiant_id,
            enseignant_id=enseignant_id,
            recherche=recherche,
            sans_encadreur=sans_encadreur,
            avec_encadreur=avec_encadreur,
        ),
    )


@routeur_projets_appariteur.post("/projets", status_code=status.HTTP_201_CREATED)
def route_creer_projet(
    donnees: ProjetCreation,
    contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    projet = service.creer_projet_appariteur(session, contexte.utilisateur.id, donnees)
    return reponse_succes("Projet academique cree", projet)


@routeur_projets_appariteur.get("/projets/{projet_id}")
def route_obtenir_projet(
    projet_id: int,
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Projet academique recupere", service.obtenir_projet_appariteur(session, projet_id))


@routeur_projets_appariteur.patch("/projets/{projet_id}")
def route_modifier_projet(
    projet_id: int,
    donnees: ProjetModification,
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Projet academique modifie", service.modifier_projet_appariteur(session, projet_id, donnees))


@routeur_projets_appariteur.post("/projets/{projet_id}/archiver")
def route_archiver_projet(
    projet_id: int,
    contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Projet academique archive",
        service.archiver_projet_appariteur(session, contexte.utilisateur.id, projet_id),
    )


@routeur_projets_appariteur.get("/enseignants-encadreurs")
def route_lister_enseignants_encadreurs(
    type_projet: str | None = Query(default=None, max_length=40),
    recherche: str | None = Query(default=None, max_length=120),
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Enseignants encadreurs recuperes",
        service.lister_enseignants_encadreurs(session, type_projet, recherche),
    )


@routeur_projets_appariteur.get("/enseignants-encadreurs/{enseignant_id}/specialites")
def route_obtenir_specialites(
    enseignant_id: int,
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Specialites enseignant recuperees",
        service.obtenir_specialites_enseignant(session, enseignant_id),
    )


@routeur_projets_appariteur.put("/enseignants-encadreurs/{enseignant_id}/specialites")
def route_configurer_specialites(
    enseignant_id: int,
    donnees: SpecialitesEnseignantModification,
    contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Specialites enseignant mises a jour",
        service.configurer_specialites_enseignant(
            session,
            contexte.utilisateur.id,
            enseignant_id,
            donnees,
        ),
    )


@routeur_projets_appariteur.post("/projets/{projet_id}/encadrements", status_code=status.HTTP_201_CREATED)
def route_attribuer_encadrement(
    projet_id: int,
    donnees: EncadrementCreation,
    contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Encadrement attribue",
        service.attribuer_encadrement_appariteur(
            session,
            contexte.utilisateur.id,
            projet_id,
            donnees,
        ),
    )


@routeur_projets_appariteur.patch("/projets/{projet_id}/encadrements/{encadrement_id}")
def route_modifier_encadrement(
    projet_id: int,
    encadrement_id: int,
    donnees: EncadrementModification,
    _contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Encadrement modifie",
        service.modifier_encadrement_appariteur(session, projet_id, encadrement_id, donnees),
    )


@routeur_projets_appariteur.post("/projets/{projet_id}/encadrements/{encadrement_id}/desactiver")
def route_desactiver_encadrement(
    projet_id: int,
    encadrement_id: int,
    contexte: ContexteUtilisateur = gestion_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Encadrement desactive",
        service.desactiver_encadrement_appariteur(
            session,
            contexte.utilisateur.id,
            projet_id,
            encadrement_id,
        ),
    )
