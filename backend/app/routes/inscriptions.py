from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, obtenir_utilisateur_connecte
from app.schemas.inscriptions import (
    ConsultationStatutDemande,
    DemandeInscriptionCreation,
    RejetDemandeInscription,
)
from app.services import inscriptions as service
from app.utilitaires.reponses import reponse_succes


routeur_inscriptions = APIRouter(prefix="/inscriptions", tags=["inscriptions"])


@routeur_inscriptions.post("/demandes", status_code=status.HTTP_201_CREATED)
def route_creer_demande(
    donnees: DemandeInscriptionCreation,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Demande d'inscription creee",
        service.creer_demande(session, donnees),
        status.HTTP_201_CREATED,
    )


@routeur_inscriptions.get("/demandes/statut")
def route_statut_demande(
    reference: str = Query(min_length=6, max_length=40),
    email: str = Query(min_length=3, max_length=190),
    session: Session = Depends(obtenir_session),
):
    donnees = ConsultationStatutDemande(reference=reference, email=email)
    return reponse_succes(
        "Statut de la demande recupere",
        service.consulter_statut(session, donnees.reference, donnees.email),
    )


@routeur_inscriptions.get("/demandes")
def route_lister_demandes(
    statut: str | None = Query(default="en_attente", max_length=30),
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Demandes d'inscription recuperees",
        service.lister_demandes(session, contexte.role_actif, statut),
    )


@routeur_inscriptions.get("/demandes/{demande_id}")
def route_obtenir_demande(
    demande_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Demande d'inscription recuperee",
        service.obtenir_demande(session, demande_id, contexte.role_actif),
    )


@routeur_inscriptions.post("/demandes/{demande_id}/approuver")
def route_approuver_demande(
    demande_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Demande d'inscription approuvee",
        service.approuver_demande(session, demande_id, contexte.utilisateur, contexte.role_actif),
    )


@routeur_inscriptions.post("/demandes/{demande_id}/rejeter")
def route_rejeter_demande(
    demande_id: int,
    donnees: RejetDemandeInscription,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Demande d'inscription rejetee",
        service.rejeter_demande(session, demande_id, donnees, contexte.utilisateur, contexte.role_actif),
    )
