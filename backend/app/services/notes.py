from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from fastapi import status
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.configuration.parametres import obtenir_parametres
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import Cours, CoursEnseignant, Enseignant, Etudiant, InscriptionCours
from app.modeles.audit import JournalAudit
from app.modeles.notes import Evaluation, Note, ResultatCours, TypeEvaluation
from app.modeles.notifications import Notification
from app.modeles.valve import PublicationValve
from app.schemas.notes import (
    EvaluationCreation,
    EvaluationModification,
    NotesEvaluationModification,
    PublicationEvaluationRequete,
)
from app.services.calcul_academique import calculer_resultat_cours
from app.services.notifications import creer_notification
from app.services.risques import recalculer_risque_etudiant_cours


def _maintenant() -> datetime:
    return datetime.utcnow()


def _enseignant_connecte(session: Session, utilisateur_id: int) -> Enseignant:
    enseignant = session.scalar(select(Enseignant).where(Enseignant.utilisateur_id == utilisateur_id))
    if enseignant is None:
        raise AccesInterdit("Profil enseignant introuvable")
    return enseignant


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if etudiant is None:
        raise AccesInterdit("Profil etudiant introuvable")
    return etudiant


def _verifier_enseignant_du_cours(session: Session, utilisateur_id: int, cours_id: int) -> Enseignant:
    enseignant = _enseignant_connecte(session, utilisateur_id)
    affectation = session.scalar(
        select(CoursEnseignant).where(
            CoursEnseignant.cours_id == cours_id,
            CoursEnseignant.enseignant_id == enseignant.id,
        )
    )
    if affectation is None:
        raise AccesInterdit("Enseignant non affecte a ce cours")
    return enseignant


def _evaluation_enseignant(session: Session, utilisateur_id: int, evaluation_id: int) -> tuple[Evaluation, Enseignant]:
    evaluation = session.scalar(
        select(Evaluation)
        .options(selectinload(Evaluation.notes))
        .where(Evaluation.id == evaluation_id)
    )
    if evaluation is None:
        raise RessourceIntrouvable("Evaluation introuvable")
    enseignant = _verifier_enseignant_du_cours(session, utilisateur_id, evaluation.cours_id)
    return evaluation, enseignant


def _verifier_etudiant_inscrit(session: Session, etudiant_id: int, cours_id: int) -> None:
    inscription = session.scalar(
        select(InscriptionCours).where(
            InscriptionCours.etudiant_id == etudiant_id,
            InscriptionCours.cours_id == cours_id,
            InscriptionCours.statut == "active",
        )
    )
    if inscription is None:
        raise ErreurApplication("Etudiant non inscrit a ce cours", status.HTTP_400_BAD_REQUEST)


def _ids_etudiants_inscrits(session: Session, cours_id: int) -> list[int]:
    return list(
        session.scalars(
            select(InscriptionCours.etudiant_id).where(
                InscriptionCours.cours_id == cours_id,
                InscriptionCours.statut == "active",
            )
        ).all()
    )


def _serialiser_evaluation(evaluation: Evaluation) -> dict:
    return {
        "id": evaluation.id,
        "cours_id": evaluation.cours_id,
        "type_evaluation_id": evaluation.type_evaluation_id,
        "titre": evaluation.titre,
        "note_maximale": evaluation.note_maximale,
        "ponderation": evaluation.ponderation,
        "statut": evaluation.statut,
        "cree_par": evaluation.cree_par,
        "date_evaluation": evaluation.date_evaluation,
        "date_publication": evaluation.date_publication,
        "est_verrouillee": evaluation.est_verrouillee,
        "cree_le": evaluation.cree_le,
        "modifie_le": evaluation.modifie_le,
    }


def _serialiser_note(note: Note) -> dict:
    return {
        "id": note.id,
        "evaluation_id": note.evaluation_id,
        "etudiant_id": note.etudiant_id,
        "note_obtenue": note.note_obtenue,
        "commentaire": note.commentaire,
        "encodee_par": note.encodee_par,
        "cree_le": note.cree_le,
        "modifie_le": note.modifie_le,
    }


def _serialiser_resultat(resultat: ResultatCours) -> dict:
    return {
        "id": resultat.id,
        "etudiant_id": resultat.etudiant_id,
        "cours_id": resultat.cours_id,
        "moyenne": resultat.moyenne,
        "credits_obtenus": resultat.credits_obtenus,
        "statut_resultat": resultat.statut_resultat,
        "calcule_le": resultat.calcule_le,
    }


def _ponderation_future(session: Session, cours_id: int, ponderation: Decimal, evaluation_id: int | None = None) -> Decimal:
    requete = select(func.coalesce(func.sum(Evaluation.ponderation), 0)).where(
        Evaluation.cours_id == cours_id,
        Evaluation.statut != "archivee",
    )
    if evaluation_id is not None:
        requete = requete.where(Evaluation.id != evaluation_id)
    total = session.scalar(requete) or Decimal("0")
    return Decimal(str(total)) + ponderation


def _verifier_ponderation(session: Session, cours_id: int, ponderation: Decimal, evaluation_id: int | None = None) -> None:
    parametres = obtenir_parametres()
    total_futur = _ponderation_future(session, cours_id, ponderation, evaluation_id=evaluation_id)
    maximum = Decimal(str(parametres.ponderation_max_cours))
    if total_futur > maximum:
        raise ErreurApplication(
            f"La somme des ponderations du cours ne peut pas depasser {maximum}%",
            status.HTTP_400_BAD_REQUEST,
            erreurs=[{"ponderation_totale": str(total_futur)}],
        )


def _journaliser(
    session: Session,
    utilisateur_id: int,
    action: str,
    entite: str,
    entite_id: int | None,
    details: dict | None = None,
) -> None:
    session.add(
        JournalAudit(
            utilisateur_id=utilisateur_id,
            action=action,
            entite=entite,
            entite_id=entite_id,
            details_json=details,
        )
    )


def lister_evaluations_enseignant(session: Session, utilisateur_id: int, cours_id: int) -> list[dict]:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    evaluations = session.scalars(
        select(Evaluation)
        .where(Evaluation.cours_id == cours_id, Evaluation.statut != "archivee")
        .order_by(Evaluation.cree_le.desc())
    ).all()
    return [_serialiser_evaluation(evaluation) for evaluation in evaluations]


def creer_evaluation(session: Session, utilisateur_id: int, cours_id: int, donnees: EvaluationCreation) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    if session.get(Cours, cours_id) is None:
        raise RessourceIntrouvable("Cours introuvable")
    if session.get(TypeEvaluation, donnees.type_evaluation_id) is None:
        raise RessourceIntrouvable("Type d'evaluation introuvable")
    _verifier_ponderation(session, cours_id, donnees.ponderation)

    evaluation = Evaluation(
        cours_id=cours_id,
        type_evaluation_id=donnees.type_evaluation_id,
        titre=donnees.titre,
        note_maximale=donnees.note_maximale,
        ponderation=donnees.ponderation,
        statut="brouillon",
        cree_par=utilisateur_id,
        date_evaluation=donnees.date_evaluation,
        est_verrouillee=False,
    )
    session.add(evaluation)
    try:
        session.flush()
        _journaliser(session, utilisateur_id, "creation_evaluation", "evaluations", evaluation.id)
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Evaluation impossible a creer") from exc

    session.refresh(evaluation)
    return _serialiser_evaluation(evaluation)


def obtenir_evaluation_enseignant(session: Session, utilisateur_id: int, evaluation_id: int) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    return _serialiser_evaluation(evaluation)


def modifier_evaluation(session: Session, utilisateur_id: int, evaluation_id: int, donnees: EvaluationModification) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.statut != "brouillon" or evaluation.est_verrouillee:
        raise AccesInterdit("Seule une evaluation en brouillon non verrouillee peut etre modifiee")

    valeurs = donnees.model_dump(exclude_unset=True)
    if "type_evaluation_id" in valeurs and session.get(TypeEvaluation, valeurs["type_evaluation_id"]) is None:
        raise RessourceIntrouvable("Type d'evaluation introuvable")
    ponderation = valeurs.get("ponderation", evaluation.ponderation)
    _verifier_ponderation(session, evaluation.cours_id, ponderation, evaluation_id=evaluation.id)

    for champ, valeur in valeurs.items():
        setattr(evaluation, champ, valeur)

    try:
        _journaliser(session, utilisateur_id, "modification_evaluation", "evaluations", evaluation.id)
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Evaluation impossible a modifier") from exc
    session.refresh(evaluation)
    return _serialiser_evaluation(evaluation)


def archiver_evaluation(session: Session, utilisateur_id: int, evaluation_id: int) -> None:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.est_verrouillee:
        raise AccesInterdit("Une evaluation verrouillee ne peut pas etre archivee")
    evaluation.statut = "archivee"
    _journaliser(session, utilisateur_id, "archivage_evaluation", "evaluations", evaluation.id)
    session.commit()


def lister_notes_evaluation(session: Session, utilisateur_id: int, evaluation_id: int) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    notes = session.scalars(select(Note).where(Note.evaluation_id == evaluation.id)).all()
    ids_notes = {note.etudiant_id for note in notes}
    inscrits = _ids_etudiants_inscrits(session, evaluation.cours_id)
    return {
        "evaluation": _serialiser_evaluation(evaluation),
        "notes": [_serialiser_note(note) for note in notes],
        "etudiants_sans_note": [etudiant_id for etudiant_id in inscrits if etudiant_id not in ids_notes],
    }


def enregistrer_notes_evaluation(
    session: Session,
    utilisateur_id: int,
    evaluation_id: int,
    donnees: NotesEvaluationModification,
) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.statut != "brouillon" or evaluation.est_verrouillee:
        raise AccesInterdit("Les notes d'une evaluation publiee ou verrouillee ne peuvent pas etre modifiees")

    try:
        for item in donnees.notes:
            if item.note_obtenue > evaluation.note_maximale:
                raise ErreurApplication(
                    "Une note ne peut pas depasser la note maximale",
                    status.HTTP_400_BAD_REQUEST,
                    erreurs=[{"etudiant_id": item.etudiant_id, "note_maximale": str(evaluation.note_maximale)}],
                )
            _verifier_etudiant_inscrit(session, item.etudiant_id, evaluation.cours_id)
            note = session.scalar(
                select(Note).where(
                    Note.evaluation_id == evaluation.id,
                    Note.etudiant_id == item.etudiant_id,
                )
            )
            if note is None:
                note = Note(
                    evaluation_id=evaluation.id,
                    etudiant_id=item.etudiant_id,
                    note_obtenue=item.note_obtenue,
                    commentaire=item.commentaire,
                    encodee_par=utilisateur_id,
                )
                session.add(note)
            else:
                note.note_obtenue = item.note_obtenue
                note.commentaire = item.commentaire
                note.encodee_par = utilisateur_id

        _journaliser(
            session,
            utilisateur_id,
            "encodage_notes",
            "evaluations",
            evaluation.id,
            {"nombre_notes": len(donnees.notes)},
        )
        session.commit()
    except Exception:
        session.rollback()
        raise

    return lister_notes_evaluation(session, utilisateur_id, evaluation_id)


def publier_evaluation(
    session: Session,
    utilisateur_id: int,
    evaluation_id: int,
    donnees: PublicationEvaluationRequete,
) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.statut == "archivee":
        raise AccesInterdit("Une evaluation archivee ne peut pas etre publiee")
    if evaluation.statut == "publiee":
        return _serialiser_evaluation(evaluation)

    inscrits = _ids_etudiants_inscrits(session, evaluation.cours_id)
    notes = session.scalars(select(Note).where(Note.evaluation_id == evaluation.id)).all()
    ids_notes = {note.etudiant_id for note in notes}
    manquants = [etudiant_id for etudiant_id in inscrits if etudiant_id not in ids_notes]
    if manquants and not donnees.confirmer_notes_manquantes:
        raise ErreurApplication(
            "Certaines notes sont manquantes",
            status.HTTP_400_BAD_REQUEST,
            erreurs=[{"etudiants_sans_note": manquants}],
        )

    try:
        evaluation.statut = "publiee"
        evaluation.date_publication = _maintenant()
        session.flush()

        for etudiant_id in inscrits:
            calculer_resultat_cours(session, etudiant_id, evaluation.cours_id)
            recalculer_risque_etudiant_cours(session, etudiant_id, evaluation.cours_id, notifier=True)

        cours = session.get(Cours, evaluation.cours_id)
        titre = f"Resultats publies - {evaluation.titre}"
        contenu = f"Les resultats de l'evaluation \"{evaluation.titre}\" du cours {cours.intitule if cours else ''} ont ete publies."
        session.add(
            PublicationValve(
                cours_id=evaluation.cours_id,
                auteur_id=utilisateur_id,
                type_publication="publication_notes",
                titre=titre,
                contenu=contenu,
                est_importante=True,
                statut="publiee",
                publie_le=_maintenant(),
            )
        )

        for inscription in session.scalars(
            select(InscriptionCours).where(
                InscriptionCours.cours_id == evaluation.cours_id,
                InscriptionCours.statut == "active",
            )
        ):
            etudiant = session.get(Etudiant, inscription.etudiant_id)
            if etudiant:
                creer_notification(
                    session,
                    etudiant.utilisateur_id,
                    "nouvelle_note",
                    titre,
                    contenu,
                    {"evaluation_id": evaluation.id, "cours_id": evaluation.cours_id},
                )

        _journaliser(session, utilisateur_id, "publication_evaluation", "evaluations", evaluation.id)
        session.commit()
    except Exception:
        session.rollback()
        raise

    session.refresh(evaluation)
    return _serialiser_evaluation(evaluation)


def verrouiller_evaluation(session: Session, utilisateur_id: int, evaluation_id: int) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.statut != "publiee":
        raise AccesInterdit("Seule une evaluation publiee peut etre verrouillee")
    evaluation.est_verrouillee = True
    _journaliser(session, utilisateur_id, "verrouillage_evaluation", "evaluations", evaluation.id)
    session.commit()
    session.refresh(evaluation)
    return _serialiser_evaluation(evaluation)


def notes_etudiant(session: Session, utilisateur_id: int, cours_id: int | None = None) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    requete = (
        select(Note, Evaluation, Cours)
        .join(Evaluation, Note.evaluation_id == Evaluation.id)
        .join(Cours, Evaluation.cours_id == Cours.id)
        .where(Note.etudiant_id == etudiant.id, Evaluation.statut == "publiee")
        .order_by(Evaluation.date_publication.desc())
    )
    if cours_id is not None:
        _verifier_etudiant_inscrit(session, etudiant.id, cours_id)
        requete = requete.where(Evaluation.cours_id == cours_id)

    lignes = session.execute(requete).all()
    return {
        "notes": [
            {
                "note": _serialiser_note(note),
                "evaluation": _serialiser_evaluation(evaluation),
                "cours": {"id": cours.id, "code": cours.code, "intitule": cours.intitule},
            }
            for note, evaluation, cours in lignes
        ]
    }


def resultats_etudiant(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    resultats = session.scalars(
        select(ResultatCours)
        .where(ResultatCours.etudiant_id == etudiant.id)
        .order_by(ResultatCours.cours_id)
    ).all()
    total_credits = sum(resultat.credits_obtenus for resultat in resultats)
    moyenne_generale = None
    if resultats:
        moyenne_generale = sum(Decimal(str(resultat.moyenne)) for resultat in resultats) / Decimal(len(resultats))

    return {
        "resultats": [_serialiser_resultat(resultat) for resultat in resultats],
        "moyenne_generale": moyenne_generale,
        "credits_valides": total_credits,
        "cours_reussis": sum(1 for resultat in resultats if resultat.statut_resultat == "reussi"),
        "cours_echoues": sum(1 for resultat in resultats if resultat.statut_resultat == "echoue"),
    }
