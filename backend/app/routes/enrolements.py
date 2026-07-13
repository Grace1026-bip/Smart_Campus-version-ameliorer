from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role
from app.schemas.academique import EnrolementAnnulation, EnrolementCreation, EnrolementModification
from app.services import enrolements as service
from app.utilitaires.reponses import reponse_succes


routeur_enrolements = APIRouter(prefix="/appariteur", tags=["enrolements academiques"])
lecture_appariteur = Depends(exiger_role("appariteur"))


@routeur_enrolements.get("/enrolements")
def route_lister_enrolements(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
    annee_academique_id: int | None = Query(default=None, gt=0),
    promotion_id: int | None = Query(default=None, gt=0),
    statut: str | None = Query(default=None, max_length=20),
    contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    del contexte
    return reponse_succes(
        "Enrolements recuperes",
        service.lister(
            session,
            page=page,
            taille=taille,
            recherche=recherche,
            annee_academique_id=annee_academique_id,
            promotion_id=promotion_id,
            statut=statut,
        ),
    )


@routeur_enrolements.post("/enrolements", status_code=status.HTTP_201_CREATED)
def route_creer_enrolement(
    donnees: EnrolementCreation,
    contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Enrolement cree",
        service.creer(session, contexte.utilisateur.id, donnees),
        status.HTTP_201_CREATED,
    )


@routeur_enrolements.post("/enrolements/{enrolement_id}/valider")
def route_valider_enrolement(
    enrolement_id: int,
    contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Enrolement valide",
        service.valider(session, contexte.utilisateur.id, enrolement_id),
    )


@routeur_enrolements.post("/enrolements/{enrolement_id}/annuler")
def route_annuler_enrolement(
    enrolement_id: int,
    donnees: EnrolementAnnulation,
    contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Enrolement annule",
        service.annuler(session, contexte.utilisateur.id, enrolement_id, donnees),
    )


@routeur_enrolements.get("/enrolements/{enrolement_id}/fiche/donnees")
def route_donnees_fiche(
    enrolement_id: int,
    _contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Donnees de fiche recuperees", service.donnees_fiche(session, enrolement_id))


@routeur_enrolements.get("/enrolements/{enrolement_id}")
def route_obtenir_enrolement(
    enrolement_id: int,
    _contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enrolement recupere", service.obtenir(session, enrolement_id, avec_programme=True))


@routeur_enrolements.patch("/enrolements/{enrolement_id}")
def route_modifier_enrolement(
    enrolement_id: int,
    donnees: EnrolementModification,
    _contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enrolement modifie", service.modifier(session, enrolement_id, donnees))


@routeur_enrolements.get("/etudiants/{etudiant_id}/enrolements")
def route_lister_enrolements_etudiant(
    etudiant_id: int,
    _contexte: ContexteUtilisateur = lecture_appariteur,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enrolements de l etudiant recuperes", {"elements": service.lister_etudiant(session, etudiant_id)})
