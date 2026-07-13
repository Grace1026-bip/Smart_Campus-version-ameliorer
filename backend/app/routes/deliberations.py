from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, obtenir_utilisateur_connecte
from app.schemas.deliberations import DecisionJuryCreation, MembreJuryCreation, ReouvertureCreation, SessionDeliberationCreation
from app.services import deliberations as service
from app.utilitaires.reponses import reponse_succes


routeur_deliberations = APIRouter(prefix="/deliberations", tags=["deliberations LMD"])


@routeur_deliberations.post("", status_code=status.HTTP_201_CREATED)
def route_creer_session(donnees: SessionDeliberationCreation, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Session de deliberation creee", service.creer_session(session, contexte.utilisateur.id, contexte.role_actif, donnees.promotion_id, donnees.annee_academique_id, donnees.semestre_id), status.HTTP_201_CREATED)


@routeur_deliberations.get("")
def route_lister_sessions(contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Sessions de deliberation recuperees", {"sessions": service.lister_sessions(session, contexte.role_actif, contexte.utilisateur.id)})


@routeur_deliberations.get("/{session_id}")
def route_obtenir_session(session_id: int, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Session de deliberation recuperee", service.obtenir_session(session, session_id, contexte.role_actif, contexte.utilisateur.id))


@routeur_deliberations.post("/{session_id}/membres")
def route_ajouter_membre(session_id: int, donnees: MembreJuryCreation, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Membre du jury enregistre", service.ajouter_membre(session, session_id, contexte.utilisateur.id, contexte.role_actif, donnees.utilisateur_id, donnees.qualite, donnees.present))


@routeur_deliberations.post("/{session_id}/ouvrir")
def route_ouvrir_session(session_id: int, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Session de deliberation ouverte", service.ouvrir_session(session, session_id, contexte.utilisateur.id, contexte.role_actif))


@routeur_deliberations.get("/{session_id}/grille")
def route_grille(session_id: int, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Grille de deliberation recuperee", service.obtenir_grille(session, session_id, contexte.utilisateur.id, contexte.role_actif))


@routeur_deliberations.post("/{session_id}/decisions/{etudiant_id}")
def route_enregistrer_decision(session_id: int, etudiant_id: int, donnees: DecisionJuryCreation, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Decision du jury enregistree", service.enregistrer_decision(session, session_id, etudiant_id, contexte.utilisateur.id, donnees.decision, donnees.motif))


@routeur_deliberations.post("/{session_id}/cloturer")
def route_cloturer_session(session_id: int, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Session de deliberation cloturee", service.cloturer_session(session, session_id, contexte.utilisateur.id))


@routeur_deliberations.post("/{session_id}/publier")
def route_publier_session(session_id: int, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Resultats officiels publies", service.publier_session(session, session_id, contexte.utilisateur.id, contexte.role_actif))


@routeur_deliberations.post("/{session_id}/demander-reouverture")
def route_demander_reouverture(session_id: int, donnees: ReouvertureCreation, contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte), session: Session = Depends(obtenir_session)):
    return reponse_succes("Nouvelle version de deliberation preparee", service.demander_reouverture(session, session_id, contexte.utilisateur.id, contexte.role_actif, donnees.motif), status.HTTP_201_CREATED)
