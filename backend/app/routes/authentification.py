from fastapi import APIRouter, Depends, Request, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, obtenir_utilisateur_connecte
from app.schemas.authentification import (
    ActualisationRequete,
    ChangementMotDePasseRequete,
    ConnexionRequete,
    DeconnexionRequete,
)
from app.services.authentification import (
    actualiser,
    changer_mot_de_passe,
    connecter,
    deconnecter,
    serialiser_utilisateur,
)
from app.utilitaires.reponses import reponse_succes


routeur_auth = APIRouter(prefix="/auth", tags=["authentification"])


@routeur_auth.post("/connexion", status_code=status.HTTP_200_OK)
def route_connexion(
    donnees: ConnexionRequete,
    request: Request,
    session: Session = Depends(obtenir_session),
):
    jetons = connecter(session, donnees, request)
    return reponse_succes("Connexion reussie", jetons)


@routeur_auth.post("/actualiser", status_code=status.HTTP_200_OK)
def route_actualiser(
    donnees: ActualisationRequete,
    request: Request,
    session: Session = Depends(obtenir_session),
):
    jetons = actualiser(session, donnees, request)
    return reponse_succes("Session actualisee", jetons)


@routeur_auth.post("/deconnexion", status_code=status.HTTP_200_OK)
def route_deconnexion(
    donnees: DeconnexionRequete,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    deconnecter(session, contexte.utilisateur, donnees)
    return reponse_succes("Deconnexion reussie")


@routeur_auth.get("/moi", status_code=status.HTTP_200_OK)
def route_moi(contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte)):
    return reponse_succes(
        "Utilisateur connecte",
        serialiser_utilisateur(contexte.utilisateur, role_actif=contexte.role_actif),
    )


@routeur_auth.put("/mot-de-passe", status_code=status.HTTP_200_OK)
def route_changer_mot_de_passe(
    donnees: ChangementMotDePasseRequete,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    changer_mot_de_passe(session, contexte.utilisateur, donnees)
    return reponse_succes("Mot de passe modifie")
