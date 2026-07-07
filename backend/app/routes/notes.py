from fastapi import APIRouter, Depends, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_un_des_roles
from app.schemas.notes import (
    EvaluationCreation,
    EvaluationModification,
    NotesEvaluationModification,
    PublicationEvaluationRequete,
)
from app.services import notes as service
from app.utilitaires.reponses import reponse_succes


routeur_notes = APIRouter(tags=["evaluations et notes"])


@routeur_notes.get("/enseignant/cours/{cours_id}/evaluations")
def route_lister_evaluations_enseignant(
    cours_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_evaluations_enseignant(session, contexte.utilisateur.id, cours_id)
    return reponse_succes("Evaluations recuperees", {"evaluations": donnees})


@routeur_notes.post("/enseignant/cours/{cours_id}/evaluations", status_code=status.HTTP_201_CREATED)
def route_creer_evaluation(
    cours_id: int,
    donnees: EvaluationCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    evaluation = service.creer_evaluation(session, contexte.utilisateur.id, cours_id, donnees)
    return reponse_succes("Evaluation creee", {"evaluation": evaluation}, status.HTTP_201_CREATED)


@routeur_notes.get("/enseignant/evaluations/{evaluation_id}")
def route_obtenir_evaluation(
    evaluation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    evaluation = service.obtenir_evaluation_enseignant(session, contexte.utilisateur.id, evaluation_id)
    return reponse_succes("Evaluation recuperee", {"evaluation": evaluation})


@routeur_notes.put("/enseignant/evaluations/{evaluation_id}")
def route_modifier_evaluation(
    evaluation_id: int,
    donnees: EvaluationModification,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    evaluation = service.modifier_evaluation(session, contexte.utilisateur.id, evaluation_id, donnees)
    return reponse_succes("Evaluation modifiee", {"evaluation": evaluation})


@routeur_notes.delete("/enseignant/evaluations/{evaluation_id}")
def route_archiver_evaluation(
    evaluation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    service.archiver_evaluation(session, contexte.utilisateur.id, evaluation_id)
    return reponse_succes("Evaluation archivee")


@routeur_notes.get("/enseignant/evaluations/{evaluation_id}/notes")
def route_lister_notes_evaluation(
    evaluation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_notes_evaluation(session, contexte.utilisateur.id, evaluation_id)
    return reponse_succes("Notes recuperees", donnees)


@routeur_notes.put("/enseignant/evaluations/{evaluation_id}/notes")
def route_enregistrer_notes_evaluation(
    evaluation_id: int,
    donnees: NotesEvaluationModification,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    notes = service.enregistrer_notes_evaluation(session, contexte.utilisateur.id, evaluation_id, donnees)
    return reponse_succes("Notes enregistrees", notes)


@routeur_notes.post("/enseignant/evaluations/{evaluation_id}/publier")
def route_publier_evaluation(
    evaluation_id: int,
    donnees: PublicationEvaluationRequete | None = None,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    evaluation = service.publier_evaluation(
        session,
        contexte.utilisateur.id,
        evaluation_id,
        donnees or PublicationEvaluationRequete(),
    )
    return reponse_succes("Evaluation publiee", {"evaluation": evaluation})


@routeur_notes.post("/enseignant/evaluations/{evaluation_id}/verrouiller")
def route_verrouiller_evaluation(
    evaluation_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    evaluation = service.verrouiller_evaluation(session, contexte.utilisateur.id, evaluation_id)
    return reponse_succes("Evaluation verrouillee", {"evaluation": evaluation})


@routeur_notes.get("/etudiant/notes")
def route_notes_etudiant(
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Notes recuperees", service.notes_etudiant(session, contexte.utilisateur.id))


@routeur_notes.get("/etudiant/cours/{cours_id}/notes")
def route_notes_etudiant_cours(
    cours_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Notes du cours recuperees", service.notes_etudiant(session, contexte.utilisateur.id, cours_id))


@routeur_notes.get("/etudiant/resultats")
def route_resultats_etudiant(
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Resultats recuperes", service.resultats_etudiant(session, contexte.utilisateur.id))
