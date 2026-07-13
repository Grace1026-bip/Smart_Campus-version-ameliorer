from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, obtenir_utilisateur_connecte
from app.exceptions.erreurs import AccesInterdit
from app.services import resultats_academiques as service
from app.services import deliberations as service_deliberations
from app.utilitaires.reponses import reponse_succes


routeur_resultats = APIRouter(prefix="/resultats", tags=["resultats academiques"])


@routeur_resultats.get("/etudiants")
def route_lister_etudiants(
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    if contexte.role_actif not in service.ROLES_RESPONSABLES:
        raise AccesInterdit("Role non autorise pour la consultation des resultats")
    return reponse_succes(
        "Etudiants academiques recuperes",
        {"etudiants": service.lister_etudiants_responsable(session)},
    )


@routeur_resultats.get("/mes-semestres")
def route_lister_mes_semestres(
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    etudiant = service._etudiant_connecte(session, contexte.utilisateur.id)
    semestres = service.lister_semestres(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        etudiant.id,
    )
    return reponse_succes("Mes semestres academiques recuperes", {"semestres": semestres})


@routeur_resultats.get("/mes-semestres/{semestre_id}/apercu")
def route_apercu_mon_semestre(
    semestre_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    etudiant = service._etudiant_connecte(session, contexte.utilisateur.id)
    apercu = service.apercu_semestre(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        etudiant.id,
        semestre_id,
    )
    return reponse_succes("Mon apercu semestriel recupere", apercu)


@routeur_resultats.get("/mes-semestres/{semestre_id}/officiel")
def route_resultat_officiel_mon_semestre(
    semestre_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    if contexte.role_actif != "etudiant":
        raise AccesInterdit("Seul l etudiant concerne peut consulter son resultat officiel")
    return reponse_succes(
        "Resultat officiel recupere",
        service_deliberations.resultats_officiels_etudiant(session, contexte.utilisateur.id, semestre_id),
    )


@routeur_resultats.get("/etudiants/{etudiant_id}/semestres")
def route_lister_semestres(
    etudiant_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    semestres = service.lister_semestres(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        etudiant_id,
    )
    return reponse_succes("Semestres academiques recuperes", {"semestres": semestres})


@routeur_resultats.get("/etudiants/{etudiant_id}/semestres/{semestre_id}/apercu")
def route_apercu_semestre(
    etudiant_id: int,
    semestre_id: int,
    contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte),
    session: Session = Depends(obtenir_session),
):
    apercu = service.apercu_semestre(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        etudiant_id,
        semestre_id,
    )
    return reponse_succes("Apercu semestriel recupere", apercu)
