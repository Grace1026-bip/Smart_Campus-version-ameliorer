from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role, exiger_un_des_roles
from app.schemas.presences_academiques import CorrectionPresence, ControleAccesPresence, SeanceAcademiqueCreation
from app.services import presences_academiques as service
from app.utilitaires.reponses import reponse_succes


routeur_presences_academiques = APIRouter(tags=["presences academiques"])


@routeur_presences_academiques.get("/surveillant/seances")
def lister_seances(
    date_seance: date | None = Query(default=None),
    _contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Seances academiques recuperees", {"elements": service.lister_seances(session, date_seance)})


@routeur_presences_academiques.post("/surveillant/seances", status_code=status.HTTP_201_CREATED)
def creer_seance(
    donnees: SeanceAcademiqueCreation,
    contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Seance academique creee",
        service.creer_seance(session, contexte.utilisateur.id, donnees),
        status.HTTP_201_CREATED,
    )


@routeur_presences_academiques.get("/surveillant/seances/{seance_id}")
def obtenir_seance(
    seance_id: int,
    _contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Seance academique recuperee", service.obtenir_seance(session, seance_id))


@routeur_presences_academiques.post("/surveillant/seances/{seance_id}/ouvrir")
def ouvrir_seance(
    seance_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Seance academique ouverte", service.ouvrir_seance(session, contexte.utilisateur.id, seance_id))


@routeur_presences_academiques.post("/surveillant/seances/{seance_id}/fermer")
def fermer_seance(
    seance_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Seance academique fermee", service.fermer_seance(session, contexte.utilisateur.id, seance_id))


@routeur_presences_academiques.get("/surveillant/seances/{seance_id}/presences")
def lister_presences(
    seance_id: int,
    _contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Presences academiques recuperees",
        {"elements": service.lister_presences(session, seance_id, inclure_financier=True)},
    )


@routeur_presences_academiques.get("/surveillant/seances/{seance_id}/resume")
def resume_seance(
    seance_id: int,
    _contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Resume de seance recupere", service.resume_seance(session, seance_id))


@routeur_presences_academiques.patch("/surveillant/seances/{seance_id}/presences/{presence_id}")
def corriger_presence(
    seance_id: int,
    presence_id: int,
    donnees: CorrectionPresence,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("surveillant", "appariteur")),
    session: Session = Depends(obtenir_session),
):
    presence = service.corriger_presence(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        seance_id,
        presence_id,
        donnees,
    )
    return reponse_succes("Presence corrigee", presence)


@routeur_presences_academiques.get("/surveillant/seances/{seance_id}/etudiants")
def lister_etudiants(
    seance_id: int,
    _contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etudiants autorises recuperes", {"elements": service.lister_etudiants_seance(session, seance_id)})


@routeur_presences_academiques.post("/surveillant/seances/{seance_id}/controle-acces")
def controler_acces(
    seance_id: int,
    donnees: ControleAccesPresence,
    contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Controle d acces traite",
        service.controler_acces(session, contexte.utilisateur.id, seance_id, donnees),
    )


@routeur_presences_academiques.post("/chef-promotion/seances/{seance_id}/confirmer-cours-2")
def confirmer_cours_2(
    seance_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_role("chef_promotion")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Deuxieme cours confirme",
        service.confirmer_cours_2(session, contexte.utilisateur.id, seance_id),
    )


@routeur_presences_academiques.get("/chef-promotion/seances")
def lister_seances_chef(
    date_seance: date | None = Query(default=None),
    contexte: ContexteUtilisateur = Depends(exiger_role("chef_promotion")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Seances de la promotion recuperees",
        {"elements": service.lister_seances_chef(session, contexte.utilisateur.id, date_seance)},
    )


@routeur_presences_academiques.get("/chef-promotion/seances/{seance_id}/presences")
def lister_presences_chef(
    seance_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_role("chef_promotion")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Presences de la promotion recuperees",
        {"elements": service.lister_presences_chef(session, contexte.utilisateur.id, seance_id)},
    )


@routeur_presences_academiques.get("/enseignants/moi/seances")
def lister_seances_enseignant(
    date_seance: date | None = Query(default=None),
    statut: str | None = Query(default=None, max_length=20),
    annee_academique_id: int | None = Query(default=None, gt=0),
    contexte: ContexteUtilisateur = Depends(exiger_role("enseignant")),
    session: Session = Depends(obtenir_session),
):
    elements = service.lister_seances_enseignant(
        session,
        contexte.utilisateur.id,
        date_seance=date_seance,
        statut=statut,
        annee_academique_id=annee_academique_id,
    )
    return reponse_succes("Seances des cours enseignant recuperees", {"elements": elements, "total": len(elements)})


@routeur_presences_academiques.get("/enseignants/moi/seances/{seance_id}/presences")
def lister_presences_enseignant(
    seance_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_role("enseignant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Presences du cours recuperees",
        {"elements": service.lister_presences_enseignant(session, contexte.utilisateur.id, seance_id)},
    )


@routeur_presences_academiques.get("/etudiants/moi/presences")
def lister_presences_etudiant(
    annee_academique_id: int | None = Query(default=None, gt=0),
    semestre_id: int | None = Query(default=None, gt=0),
    cours_id: int | None = Query(default=None, gt=0),
    statut: str | None = Query(default=None, max_length=20),
    contexte: ContexteUtilisateur = Depends(exiger_role("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes(
        "Presences etudiant recuperees",
        service.lister_presences_etudiant(
            session,
            contexte.utilisateur.id,
            annee_academique_id=annee_academique_id,
            semestre_id=semestre_id,
            cours_id=cours_id,
            statut=statut,
        ),
    )
