from __future__ import annotations

from fastapi import APIRouter, Depends, Response
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role
from app.services import enrolements, espace_etudiant, notes, projets
from app.services.fiches_pdf import generer_fiche_enrolement_pdf


routeur_etudiants = APIRouter(prefix="/etudiants", tags=["espace etudiant"])
lecture_etudiant = Depends(exiger_role("etudiant"))


@routeur_etudiants.get("/moi/tableau-de-bord")
def route_tableau_de_bord_etudiant(
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Tableau de bord etudiant recupere", "donnees": espace_etudiant.tableau_de_bord(session, contexte.utilisateur.id)}


@routeur_etudiants.get("/moi/cours")
def route_lister_mes_cours(
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Cours etudiant recuperes", "donnees": espace_etudiant.lister_cours(session, contexte.utilisateur.id)}


@routeur_etudiants.get("/moi/cours/{cours_id}/notes")
def route_notes_de_mon_cours(
    cours_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Notes du cours recuperees", "donnees": notes.notes_etudiant(session, contexte.utilisateur.id, cours_id)}


@routeur_etudiants.get("/moi/cours/{cours_id}")
def route_obtenir_mon_cours(
    cours_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Cours etudiant recupere", "donnees": espace_etudiant.obtenir_cours(session, contexte.utilisateur.id, cours_id)}


@routeur_etudiants.get("/moi/historique-academique")
def route_historique_academique(
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Historique academique recupere", "donnees": espace_etudiant.historique_academique(session, contexte.utilisateur.id)}


@routeur_etudiants.get("/moi/enrolements")
def route_lister_mes_enrolements(
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Enrolements etudiant recuperes", "donnees": enrolements.lister_pour_etudiant(session, contexte.utilisateur.id)}


@routeur_etudiants.get("/moi/enrolements/{enrolement_id}")
def route_obtenir_mon_enrolement(
    enrolement_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Enrolement etudiant recupere", "donnees": enrolements.obtenir_pour_etudiant(session, contexte.utilisateur.id, enrolement_id)}


@routeur_etudiants.get("/moi/enrolements/{enrolement_id}/fiche")
def route_telecharger_ma_fiche(
    enrolement_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    donnees = enrolements.donnees_fiche_pour_etudiant(session, contexte.utilisateur.id, enrolement_id)
    contenu = generer_fiche_enrolement_pdf(donnees)
    reference = donnees["reference_fiche"]
    return Response(
        content=contenu,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="fiche_enrolement_{reference}.pdf"',
            "Cache-Control": "private, no-store",
        },
    )


@routeur_etudiants.get("/moi/projets")
def route_lister_mes_projets(
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Projets etudiant recuperes", "donnees": projets.lister_projets_etudiant(session, contexte.utilisateur.id)}


@routeur_etudiants.get("/moi/projets/{projet_id}")
def route_obtenir_mon_projet(
    projet_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Projet etudiant recupere", "donnees": projets.obtenir_projet_etudiant(session, contexte.utilisateur.id, projet_id)}


@routeur_etudiants.get("/moi/projets/{projet_id}/encadreurs")
def route_lister_mes_encadreurs(
    projet_id: int,
    contexte: ContexteUtilisateur = lecture_etudiant,
    session: Session = Depends(obtenir_session),
):
    return {"succes": True, "message": "Encadreurs etudiant recuperes", "donnees": projets.lister_encadreurs_etudiant(session, contexte.utilisateur.id, projet_id)}
