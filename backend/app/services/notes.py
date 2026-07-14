from __future__ import annotations

from datetime import datetime
from decimal import Decimal, ROUND_HALF_UP

from fastapi import status
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.configuration.parametres import obtenir_parametres
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Cours, CoursEnseignant, Enseignant, Etudiant, InscriptionCours, Promotion, Semestre
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
    etudiant = session.scalar(
        select(Etudiant).join(Etudiant.utilisateur).where(
            Etudiant.utilisateur_id == utilisateur_id,
            Etudiant.statut_academique == "actif",
            Etudiant.utilisateur.has(statut="actif"),
        )
    )
    if etudiant is None:
        raise AccesInterdit("Profil etudiant indisponible")
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


def _evaluation_auteur(session: Session, utilisateur_id: int, evaluation_id: int) -> Evaluation:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    if evaluation.cree_par != utilisateur_id:
        raise AccesInterdit("Cette evaluation appartient a un autre enseignant")
    return evaluation


def _verifier_etudiant_inscrit(session: Session, etudiant_id: int, cours_id: int) -> None:
    inscription = session.scalar(
        select(InscriptionCours)
        .join(InscriptionCours.etudiant)
        .join(InscriptionCours.annee_academique)
        .join(InscriptionCours.cours)
        .join(Cours.promotion)
        .join(Semestre, Cours.semestre_id == Semestre.id)
        .where(
            InscriptionCours.etudiant_id == etudiant_id,
            InscriptionCours.cours_id == cours_id,
            InscriptionCours.statut == "active",
            InscriptionCours.annee_academique_id == Semestre.annee_academique_id,
            Etudiant.statut_academique == "actif",
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Cours.promotion_id == Etudiant.promotion_id,
            Promotion.est_active.is_(True),
        )
    )
    if inscription is None:
        raise ErreurApplication("Etudiant non inscrit a ce cours", status.HTTP_400_BAD_REQUEST)


def _inscriptions_actives(session: Session, cours_id: int) -> list[InscriptionCours]:
    return list(
        session.scalars(
            select(InscriptionCours)
            .options(
                selectinload(InscriptionCours.etudiant).selectinload(Etudiant.utilisateur),
                selectinload(InscriptionCours.etudiant).selectinload(Etudiant.promotion),
            )
            .where(
                InscriptionCours.cours_id == cours_id,
                InscriptionCours.statut == "active",
                Etudiant.statut_academique == "actif",
                AnneeAcademique.est_active.is_(True),
            )
            .join(InscriptionCours.etudiant)
            .join(InscriptionCours.annee_academique)
        ).all()
    )


def _ids_etudiants_inscrits(session: Session, cours_id: int) -> list[int]:
    return [inscription.etudiant_id for inscription in _inscriptions_actives(session, cours_id)]


def _serialiser_etudiant(etudiant: Etudiant) -> dict:
    utilisateur = etudiant.utilisateur
    nom = " ".join(
        morceau
        for morceau in (utilisateur.prenom, utilisateur.nom, utilisateur.postnom)
        if morceau
    )
    return {
        "id": etudiant.id,
        "matricule": etudiant.matricule,
        "nom": nom,
        "promotion": etudiant.promotion.nom if etudiant.promotion else None,
    }


def _serialiser_evaluation(evaluation: Evaluation) -> dict:
    return {
        "id": evaluation.id,
        "cours_id": evaluation.cours_id,
        "type_evaluation_id": evaluation.type_evaluation_id,
        "type_evaluation": {
            "id": evaluation.type_evaluation.id,
            "nom": evaluation.type_evaluation.nom,
            "description": evaluation.type_evaluation.description,
        }
        if evaluation.type_evaluation
        else None,
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


def _serialiser_note_etudiant(note: Note) -> dict:
    return {
        "id": note.id,
        "evaluation_id": note.evaluation_id,
        "note_obtenue": note.note_obtenue,
        "commentaire": note.commentaire,
        "cree_le": note.cree_le,
        "modifie_le": note.modifie_le,
    }


def _serialiser_evaluation_etudiant(evaluation: Evaluation) -> dict:
    return {
        "id": evaluation.id,
        "cours_id": evaluation.cours_id,
        "type_evaluation_id": evaluation.type_evaluation_id,
        "type_evaluation": {
            "id": evaluation.type_evaluation.id,
            "nom": evaluation.type_evaluation.nom,
            "description": evaluation.type_evaluation.description,
        } if evaluation.type_evaluation else None,
        "titre": evaluation.titre,
        "note_maximale": evaluation.note_maximale,
        "ponderation": evaluation.ponderation,
        "statut": evaluation.statut,
        "date_evaluation": evaluation.date_evaluation,
        "date_publication": evaluation.date_publication,
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
    requete = select(Evaluation.ponderation).where(
        Evaluation.cours_id == cours_id,
        Evaluation.statut != "archivee",
    ).with_for_update()
    if evaluation_id is not None:
        requete = requete.where(Evaluation.id != evaluation_id)
    total = sum((Decimal(str(valeur)) for (valeur,) in session.execute(requete)), Decimal("0"))
    return total + ponderation


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
        .options(selectinload(Evaluation.type_evaluation))
        .where(Evaluation.cours_id == cours_id, Evaluation.statut != "archivee")
        .order_by(Evaluation.cree_le.desc())
    ).all()
    return [_serialiser_evaluation(evaluation) for evaluation in evaluations]


def lister_types_evaluation(session: Session) -> list[dict]:
    types = session.scalars(select(TypeEvaluation).order_by(TypeEvaluation.id)).all()
    return [
        {
            "id": type_evaluation.id,
            "nom": type_evaluation.nom,
            "description": type_evaluation.description,
        }
        for type_evaluation in types
    ]


def _evaluations_actives(session: Session, cours_id: int) -> list[Evaluation]:
    return list(
        session.scalars(
            select(Evaluation)
            .options(selectinload(Evaluation.type_evaluation))
            .where(Evaluation.cours_id == cours_id, Evaluation.statut != "archivee")
            .order_by(Evaluation.id)
        ).all()
    )


def _arrondir_resultat(valeur: Decimal) -> Decimal:
    return valeur.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _apercu_resultats(
    session: Session,
    utilisateur_id: int,
    cours_id: int,
) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    evaluations = _evaluations_actives(session, cours_id)
    inscriptions = _inscriptions_actives(session, cours_id)
    evaluation_ids = [evaluation.id for evaluation in evaluations]
    notes = (
        session.scalars(select(Note).where(Note.evaluation_id.in_(evaluation_ids))).all()
        if evaluation_ids
        else []
    )
    notes_par_cle = {(note.etudiant_id, note.evaluation_id): note for note in notes}
    total_ponderation = sum(
        (Decimal(str(evaluation.ponderation)) for evaluation in evaluations),
        Decimal("0"),
    )
    poids_complet = total_ponderation == Decimal("100")
    evaluations_publiees = bool(evaluations) and all(
        evaluation.statut == "publiee" for evaluation in evaluations
    )
    evaluations_verrouillees = evaluations_publiees and all(
        evaluation.est_verrouillee for evaluation in evaluations
    )

    etudiants = []
    total_notes_manquantes = 0
    for inscription in inscriptions:
        etudiant = inscription.etudiant
        contributions = []
        manquantes = []
        provisoire = Decimal("0")
        for evaluation in evaluations:
            note = notes_par_cle.get((etudiant.id, evaluation.id))
            contribution = None
            if note is None:
                manquantes.append(
                    {
                        "evaluation_id": evaluation.id,
                        "titre": evaluation.titre,
                    }
                )
            else:
                contribution = (
                    Decimal(str(note.note_obtenue))
                    / Decimal(str(evaluation.note_maximale))
                    * Decimal(str(evaluation.ponderation))
                )
                provisoire += contribution
            contributions.append(
                {
                    "evaluation_id": evaluation.id,
                    "note_obtenue": note.note_obtenue if note else None,
                    "contribution_sur_100": _arrondir_resultat(contribution)
                    if contribution is not None
                    else None,
                }
            )

        total_notes_manquantes += len(manquantes)
        complet = poids_complet and evaluations_publiees and not manquantes
        etudiants.append(
            {
                **_serialiser_etudiant(etudiant),
                "contributions": contributions,
                "notes_manquantes": manquantes,
                "resultat_provisoire_sur_100": _arrondir_resultat(provisoire),
                "resultat_officiel_sur_100": _arrondir_resultat(provisoire)
                if complet
                else None,
                "etat": "verrouille"
                if complet and evaluations_verrouillees
                else "publie"
                if complet
                else "incomplet",
            }
        )

    completude = (
        bool(evaluations)
        and poids_complet
        and evaluations_publiees
        and total_notes_manquantes == 0
    )
    etat = "verrouille" if completude and evaluations_verrouillees else "publie" if completude else "incomplet"
    return {
        "cours_id": cours_id,
        "etat": etat,
        "total_ponderation": total_ponderation,
        "ponderation_restante": max(Decimal("0"), Decimal("100") - total_ponderation),
        "evaluations": [_serialiser_evaluation(evaluation) for evaluation in evaluations],
        "etudiants": etudiants,
        "notes_manquantes": total_notes_manquantes,
        "peut_publier": bool(evaluations) and poids_complet and total_notes_manquantes == 0,
        "evaluations_publiees": evaluations_publiees,
        "evaluations_verrouillees": evaluations_verrouillees,
    }


def apercu_resultats_cours(session: Session, utilisateur_id: int, cours_id: int) -> dict:
    return _apercu_resultats(session, utilisateur_id, cours_id)


def publier_resultats_cours(session: Session, utilisateur_id: int, cours_id: int) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    evaluations = list(
        session.scalars(
            select(Evaluation)
            .where(Evaluation.cours_id == cours_id, Evaluation.statut != "archivee")
            .with_for_update()
        ).all()
    )
    apercu = _apercu_resultats(session, utilisateur_id, cours_id)
    if apercu["etat"] == "verrouille":
        return apercu
    if not apercu["peut_publier"]:
        raise ErreurApplication(
            "Les resultats du cours sont incomplets et ne peuvent pas etre publies",
            status.HTTP_400_BAD_REQUEST,
            erreurs=[
                {
                    "etat": apercu["etat"],
                    "total_ponderation": str(apercu["total_ponderation"]),
                    "notes_manquantes": apercu["notes_manquantes"],
                }
            ],
        )

    moment = _maintenant()
    try:
        for evaluation in evaluations:
            evaluation.statut = "publiee"
            evaluation.date_publication = evaluation.date_publication or moment
            evaluation.est_verrouillee = True
        for inscription in _inscriptions_actives(session, cours_id):
            calculer_resultat_cours(session, inscription.etudiant_id, cours_id)
        publication = PublicationValve(
            cours_id=cours_id,
            auteur_id=utilisateur_id,
            type_publication="publication_notes",
            titre="Resultats du cours disponibles",
            contenu="Les resultats du cours sont disponibles dans l'espace academique.",
            est_importante=True,
            statut="publiee",
            publie_le=moment,
        )
        session.add(publication)
        _journaliser(session, utilisateur_id, "publication_resultats_cours", "cours", cours_id)
        session.commit()
    except Exception:
        session.rollback()
        raise

    return _apercu_resultats(session, utilisateur_id, cours_id)


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
    evaluation = _evaluation_auteur(session, utilisateur_id, evaluation_id)
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
    evaluation = _evaluation_auteur(session, utilisateur_id, evaluation_id)
    if evaluation.est_verrouillee:
        raise AccesInterdit("Une evaluation verrouillee ne peut pas etre archivee")
    evaluation.statut = "archivee"
    _journaliser(session, utilisateur_id, "archivage_evaluation", "evaluations", evaluation.id)
    session.commit()


def lister_notes_evaluation(session: Session, utilisateur_id: int, evaluation_id: int) -> dict:
    evaluation, _enseignant = _evaluation_enseignant(session, utilisateur_id, evaluation_id)
    notes = session.scalars(select(Note).where(Note.evaluation_id == evaluation.id)).all()
    ids_notes = {note.etudiant_id for note in notes}
    inscriptions = _inscriptions_actives(session, evaluation.cours_id)
    inscrits = [inscription.etudiant_id for inscription in inscriptions]
    return {
        "evaluation": _serialiser_evaluation(evaluation),
        "notes": [_serialiser_note(note) for note in notes],
        "etudiants": [_serialiser_etudiant(inscription.etudiant) for inscription in inscriptions],
        "etudiants_sans_note": [etudiant_id for etudiant_id in inscrits if etudiant_id not in ids_notes],
    }


def enregistrer_notes_evaluation(
    session: Session,
    utilisateur_id: int,
    evaluation_id: int,
    donnees: NotesEvaluationModification,
) -> dict:
    evaluation = _evaluation_auteur(session, utilisateur_id, evaluation_id)
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
    evaluation = _evaluation_auteur(session, utilisateur_id, evaluation_id)
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
    evaluation = _evaluation_auteur(session, utilisateur_id, evaluation_id)
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
        .join(InscriptionCours, InscriptionCours.cours_id == Cours.id)
        .join(AnneeAcademique, InscriptionCours.annee_academique_id == AnneeAcademique.id)
        .join(Promotion, Cours.promotion_id == Promotion.id)
        .join(Semestre, Cours.semestre_id == Semestre.id)
        .where(Note.etudiant_id == etudiant.id, Evaluation.statut == "publiee")
        .where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.statut == "active",
            InscriptionCours.annee_academique_id == Semestre.annee_academique_id,
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Cours.promotion_id == etudiant.promotion_id,
            Promotion.est_active.is_(True),
        )
        .order_by(Evaluation.date_publication.desc())
    )
    if cours_id is not None:
        _verifier_etudiant_inscrit(session, etudiant.id, cours_id)
        requete = requete.where(Evaluation.cours_id == cours_id)

    lignes = session.execute(requete).all()
    return {
        "notes": [
            {
                "note": _serialiser_note_etudiant(note),
                "evaluation": _serialiser_evaluation_etudiant(evaluation),
                "cours": {"id": cours.id, "code": cours.code, "intitule": cours.intitule},
            }
            for note, evaluation, cours in lignes
        ]
    }


def resultats_etudiant(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    resultats = session.scalars(
        select(ResultatCours)
        .join(InscriptionCours, InscriptionCours.cours_id == ResultatCours.cours_id)
        .join(Cours, Cours.id == ResultatCours.cours_id)
        .join(AnneeAcademique, InscriptionCours.annee_academique_id == AnneeAcademique.id)
        .join(Promotion, Cours.promotion_id == Promotion.id)
        .where(
            ResultatCours.etudiant_id == etudiant.id,
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.statut == "active",
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Cours.promotion_id == etudiant.promotion_id,
            Promotion.est_active.is_(True),
            ResultatCours.statut_resultat.in_({"reussi", "echoue"}),
        )
        .order_by(ResultatCours.cours_id)
    ).all()
    resultats_officiels = []
    for resultat in resultats:
        evaluations = session.scalars(
            select(Evaluation).where(
                Evaluation.cours_id == resultat.cours_id,
                Evaluation.statut != "archivee",
            )
        ).all()
        if evaluations and all(item.statut == "publiee" for item in evaluations):
            resultats_officiels.append(resultat)
    total_credits = sum(resultat.credits_obtenus for resultat in resultats_officiels)
    moyenne_generale = None
    if resultats_officiels:
        moyenne_generale = sum(Decimal(str(resultat.moyenne)) for resultat in resultats_officiels) / Decimal(len(resultats_officiels))

    return {
        "resultats": [_serialiser_resultat(resultat) for resultat in resultats_officiels],
        "moyenne_generale": moyenne_generale,
        "credits_valides": total_credits,
        "cours_reussis": sum(1 for resultat in resultats_officiels if resultat.statut_resultat == "reussi"),
        "cours_echoues": sum(1 for resultat in resultats_officiels if resultat.statut_resultat == "echoue"),
        "etat": "publie" if resultats_officiels else "en_attente",
    }
