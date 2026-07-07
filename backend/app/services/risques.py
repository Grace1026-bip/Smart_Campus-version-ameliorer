from __future__ import annotations

import json
from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.configuration.parametres import obtenir_parametres
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, RessourceIntrouvable
from app.modeles.academique import Cours, CoursEnseignant, Enseignant, Etudiant, InscriptionCours, Promotion
from app.modeles.audit import JournalAudit
from app.modeles.notes import ResultatCours
from app.modeles.securite import Utilisateur
from app.modeles.suivi import EvaluationRisque, Presence
from app.schemas.pagination import ParametresPagination, construire_page
from app.schemas.risques import PresenceLotCreation, RecalculRisquesRequete
from app.services.notifications import creer_notification


def _maintenant() -> datetime:
    return datetime.utcnow()


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


def _nom_utilisateur(utilisateur: Utilisateur | None) -> str | None:
    if utilisateur is None:
        return None
    morceaux = [utilisateur.prenom, utilisateur.nom]
    nom = " ".join(morceau for morceau in morceaux if morceau)
    return nom or utilisateur.email


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if etudiant is None:
        raise AccesInterdit("Profil etudiant introuvable")
    return etudiant


def _enseignant_connecte(session: Session, utilisateur_id: int) -> Enseignant:
    enseignant = session.scalar(select(Enseignant).where(Enseignant.utilisateur_id == utilisateur_id))
    if enseignant is None:
        raise AccesInterdit("Profil enseignant introuvable")
    return enseignant


def _verifier_enseignant_du_cours(session: Session, utilisateur_id: int, cours_id: int) -> Enseignant:
    enseignant = _enseignant_connecte(session, utilisateur_id)
    affectation = session.scalar(
        select(CoursEnseignant.id).where(
            CoursEnseignant.cours_id == cours_id,
            CoursEnseignant.enseignant_id == enseignant.id,
        )
    )
    if affectation is None:
        raise AccesInterdit("Enseignant non affecte a ce cours")
    return enseignant


def _verifier_etudiant_inscrit(session: Session, etudiant_id: int, cours_id: int) -> None:
    inscription = session.scalar(
        select(InscriptionCours.id).where(
            InscriptionCours.etudiant_id == etudiant_id,
            InscriptionCours.cours_id == cours_id,
            InscriptionCours.statut == "active",
        )
    )
    if inscription is None:
        raise AccesInterdit("Etudiant non inscrit a ce cours")


def _niveau(score: Decimal) -> str:
    parametres = obtenir_parametres()
    if score >= Decimal(str(parametres.seuil_risque_eleve)):
        return "eleve"
    if score >= Decimal(str(parametres.seuil_risque_moyen)):
        return "moyen"
    return "faible"


def _score_absences_retards(presences: list[Presence]) -> tuple[Decimal, list[dict]]:
    if not presences:
        return Decimal("0.00"), []

    total = Decimal(len(presences))
    absences = sum(1 for presence in presences if presence.statut == "absent")
    retards = sum(1 for presence in presences if presence.statut == "retard")
    taux_absence = Decimal(absences) / total
    taux_retard = Decimal(retards) / total
    score = Decimal("0.00")
    raisons: list[dict] = []

    if taux_absence >= Decimal("0.40"):
        score += Decimal("35")
        raisons.append({"critere": "absences", "niveau": "eleve", "valeur": float(taux_absence)})
    elif taux_absence >= Decimal("0.25"):
        score += Decimal("25")
        raisons.append({"critere": "absences", "niveau": "moyen", "valeur": float(taux_absence)})
    elif taux_absence >= Decimal("0.15"):
        score += Decimal("15")
        raisons.append({"critere": "absences", "niveau": "faible", "valeur": float(taux_absence)})

    if taux_retard >= Decimal("0.30"):
        score += Decimal("15")
        raisons.append({"critere": "retards", "niveau": "eleve", "valeur": float(taux_retard)})
    elif taux_retard >= Decimal("0.15"):
        score += Decimal("8")
        raisons.append({"critere": "retards", "niveau": "moyen", "valeur": float(taux_retard)})

    return score, raisons


def _score_notes(session: Session, etudiant_id: int, cours_id: int) -> tuple[Decimal, list[dict]]:
    parametres = obtenir_parametres()
    seuil_reussite = Decimal(str(parametres.seuil_reussite_cours))
    score = Decimal("0.00")
    raisons: list[dict] = []

    resultat = session.scalar(
        select(ResultatCours).where(ResultatCours.etudiant_id == etudiant_id, ResultatCours.cours_id == cours_id)
    )
    if resultat is not None:
        moyenne = Decimal(str(resultat.moyenne))
        if resultat.statut_resultat == "echoue" or moyenne < seuil_reussite:
            score += Decimal("45")
            raisons.append({"critere": "moyenne", "niveau": "eleve", "valeur": float(moyenne)})
        elif moyenne < Decimal("60"):
            score += Decimal("20")
            raisons.append({"critere": "moyenne", "niveau": "moyen", "valeur": float(moyenne)})

    echecs = session.scalar(
        select(func.count())
        .select_from(ResultatCours)
        .where(ResultatCours.etudiant_id == etudiant_id, ResultatCours.statut_resultat == "echoue")
    ) or 0
    if echecs >= 3:
        score += Decimal("30")
        raisons.append({"critere": "cours_echoues", "niveau": "eleve", "valeur": int(echecs)})
    elif echecs == 2:
        score += Decimal("20")
        raisons.append({"critere": "cours_echoues", "niveau": "moyen", "valeur": int(echecs)})
    elif echecs == 1:
        score += Decimal("10")
        raisons.append({"critere": "cours_echoues", "niveau": "faible", "valeur": int(echecs)})

    return score, raisons


def _raisons_json(raisons: list[dict]) -> str:
    return json.dumps(raisons, ensure_ascii=True)


def _raisons_parsees(raisons: str) -> list:
    try:
        valeur = json.loads(raisons)
    except json.JSONDecodeError:
        return [{"critere": "resume", "valeur": raisons}]
    return valeur if isinstance(valeur, list) else [{"critere": "resume", "valeur": valeur}]


def _notifier_risque(session: Session, risque: EvaluationRisque, ancien_niveau: str | None) -> None:
    if risque.niveau_risque not in {"moyen", "eleve"} or risque.niveau_risque == ancien_niveau:
        return
    etudiant = session.get(Etudiant, risque.etudiant_id)
    cours = session.get(Cours, risque.cours_id) if risque.cours_id else None
    if etudiant is None:
        return
    titre = "Alerte academique"
    contenu = f"Niveau de risque {risque.niveau_risque}"
    if cours is not None:
        contenu = f"Niveau de risque {risque.niveau_risque} pour le cours {cours.code}"
    creer_notification(
        session,
        etudiant.utilisateur_id,
        "alerte_academique",
        titre,
        contenu,
        {"risque_id": risque.id, "cours_id": risque.cours_id, "niveau": risque.niveau_risque},
    )


def recalculer_risque_etudiant_cours(
    session: Session,
    etudiant_id: int,
    cours_id: int,
    notifier: bool = True,
) -> EvaluationRisque:
    if session.get(Cours, cours_id) is None:
        raise RessourceIntrouvable("Cours introuvable")
    if session.get(Etudiant, etudiant_id) is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    _verifier_etudiant_inscrit(session, etudiant_id, cours_id)

    score_notes, raisons_notes = _score_notes(session, etudiant_id, cours_id)
    presences = session.scalars(
        select(Presence).where(Presence.etudiant_id == etudiant_id, Presence.cours_id == cours_id)
    ).all()
    score_suivi, raisons_suivi = _score_absences_retards(list(presences))
    score = min(score_notes + score_suivi, Decimal("100.00"))
    score = score.quantize(Decimal("0.01"))
    raisons = raisons_notes + raisons_suivi

    anciens = session.scalars(
        select(EvaluationRisque).where(
            EvaluationRisque.etudiant_id == etudiant_id,
            EvaluationRisque.cours_id == cours_id,
            EvaluationRisque.est_active.is_(True),
        )
    ).all()
    ancien_niveau = anciens[0].niveau_risque if anciens else None
    for ancien in anciens:
        ancien.est_active = False

    risque = EvaluationRisque(
        etudiant_id=etudiant_id,
        cours_id=cours_id,
        score_risque=score,
        niveau_risque=_niveau(score),
        raisons=_raisons_json(raisons),
        calcule_le=_maintenant(),
        est_active=True,
    )
    session.add(risque)
    session.flush()
    if notifier:
        _notifier_risque(session, risque, ancien_niveau)
    return risque


def _serialiser_etudiant(session: Session, etudiant_id: int) -> dict | None:
    etudiant = session.get(Etudiant, etudiant_id)
    if etudiant is None:
        return None
    utilisateur = session.get(Utilisateur, etudiant.utilisateur_id)
    return {
        "id": etudiant.id,
        "matricule": etudiant.matricule,
        "nom": _nom_utilisateur(utilisateur),
        "promotion_id": etudiant.promotion_id,
    }


def _serialiser_cours(session: Session, cours_id: int | None) -> dict | None:
    if cours_id is None:
        return None
    cours = session.get(Cours, cours_id)
    if cours is None:
        return None
    return {"id": cours.id, "code": cours.code, "intitule": cours.intitule, "promotion_id": cours.promotion_id}


def _serialiser_presence(presence: Presence) -> dict:
    return {
        "id": presence.id,
        "etudiant_id": presence.etudiant_id,
        "cours_id": presence.cours_id,
        "date_seance": presence.date_seance,
        "statut": presence.statut,
        "enregistre_par": presence.enregistre_par,
        "cree_le": presence.cree_le,
    }


def _serialiser_risque(session: Session, risque: EvaluationRisque) -> dict:
    return {
        "id": risque.id,
        "etudiant_id": risque.etudiant_id,
        "etudiant": _serialiser_etudiant(session, risque.etudiant_id),
        "cours_id": risque.cours_id,
        "cours": _serialiser_cours(session, risque.cours_id),
        "score_risque": risque.score_risque,
        "niveau_risque": risque.niveau_risque,
        "raisons": risque.raisons,
        "raisons_detaillees": _raisons_parsees(risque.raisons),
        "calcule_le": risque.calcule_le,
        "est_active": risque.est_active,
    }


def enregistrer_presences_cours(
    session: Session,
    utilisateur_id: int,
    cours_id: int,
    donnees: PresenceLotCreation,
) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    if session.get(Cours, cours_id) is None:
        raise RessourceIntrouvable("Cours introuvable")

    presences: list[Presence] = []
    try:
        for item in donnees.presences:
            _verifier_etudiant_inscrit(session, item.etudiant_id, cours_id)
            presence = session.scalar(
                select(Presence).where(
                    Presence.etudiant_id == item.etudiant_id,
                    Presence.cours_id == cours_id,
                    Presence.date_seance == donnees.date_seance,
                )
            )
            if presence is None:
                presence = Presence(
                    etudiant_id=item.etudiant_id,
                    cours_id=cours_id,
                    date_seance=donnees.date_seance,
                    statut=item.statut,
                    enregistre_par=utilisateur_id,
                )
                session.add(presence)
            else:
                presence.statut = item.statut
                presence.enregistre_par = utilisateur_id
            presences.append(presence)

        session.flush()
        risques = [
            recalculer_risque_etudiant_cours(session, item.etudiant_id, cours_id, notifier=True)
            for item in donnees.presences
        ]
        _journaliser(
            session,
            utilisateur_id,
            "enregistrement_presences",
            "presences",
            None,
            {"cours_id": cours_id, "date_seance": str(donnees.date_seance), "nombre": len(presences)},
        )
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Presences impossibles a enregistrer") from exc

    return {
        "presences": [_serialiser_presence(presence) for presence in presences],
        "risques": [_serialiser_risque(session, risque) for risque in risques],
    }


def lister_risques_etudiant(session: Session, utilisateur_id: int, cours_id: int | None = None) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    conditions = [EvaluationRisque.etudiant_id == etudiant.id, EvaluationRisque.est_active.is_(True)]
    if cours_id is not None:
        _verifier_etudiant_inscrit(session, etudiant.id, cours_id)
        conditions.append(EvaluationRisque.cours_id == cours_id)
    risques = session.scalars(
        select(EvaluationRisque).where(*conditions).order_by(EvaluationRisque.calcule_le.desc())
    ).all()
    return {"risques": [_serialiser_risque(session, risque) for risque in risques]}


def lister_risques_cours_enseignant(
    session: Session,
    utilisateur_id: int,
    cours_id: int,
    pagination: ParametresPagination,
    niveau: str | None = None,
) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    conditions = [EvaluationRisque.cours_id == cours_id, EvaluationRisque.est_active.is_(True)]
    if niveau:
        conditions.append(EvaluationRisque.niveau_risque == niveau)
    total = session.scalar(select(func.count()).select_from(EvaluationRisque).where(*conditions)) or 0
    risques = session.scalars(
        select(EvaluationRisque)
        .where(*conditions)
        .order_by(EvaluationRisque.score_risque.desc(), EvaluationRisque.calcule_le.desc())
        .offset(pagination.offset)
        .limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_risque(session, risque) for risque in risques],
        total,
        pagination.page,
        pagination.taille,
    )


def _requete_risques_global(
    promotion_id: int | None,
    cours_id: int | None,
    niveau: str | None,
    est_active: bool | None,
):
    requete = select(EvaluationRisque)
    conditions = []
    if promotion_id is not None:
        requete = requete.join(Cours, EvaluationRisque.cours_id == Cours.id)
        conditions.append(Cours.promotion_id == promotion_id)
    if cours_id is not None:
        conditions.append(EvaluationRisque.cours_id == cours_id)
    if niveau:
        conditions.append(EvaluationRisque.niveau_risque == niveau)
    if est_active is not None:
        conditions.append(EvaluationRisque.est_active.is_(est_active))
    return requete.where(*conditions), conditions, promotion_id is not None


def lister_risques_global(
    session: Session,
    pagination: ParametresPagination,
    promotion_id: int | None = None,
    cours_id: int | None = None,
    niveau: str | None = None,
    est_active: bool | None = True,
) -> dict:
    requete, conditions, avec_join = _requete_risques_global(promotion_id, cours_id, niveau, est_active)
    total_requete = select(func.count()).select_from(EvaluationRisque)
    if avec_join:
        total_requete = total_requete.join(Cours, EvaluationRisque.cours_id == Cours.id)
    total = session.scalar(total_requete.where(*conditions)) or 0
    risques = session.scalars(
        requete.order_by(EvaluationRisque.score_risque.desc(), EvaluationRisque.calcule_le.desc())
        .offset(pagination.offset)
        .limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_risque(session, risque) for risque in risques],
        total,
        pagination.page,
        pagination.taille,
    )


def recalculer_risques_cours(session: Session, utilisateur_id: int, cours_id: int) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, cours_id)
    risques = _recalculer_risques_par_cours(session, cours_id)
    _journaliser(session, utilisateur_id, "recalcul_risques_cours", "evaluations_risque", None, {"cours_id": cours_id})
    session.commit()
    return {"nombre": len(risques), "risques": [_serialiser_risque(session, risque) for risque in risques]}


def _recalculer_risques_par_cours(session: Session, cours_id: int) -> list[EvaluationRisque]:
    if session.get(Cours, cours_id) is None:
        raise RessourceIntrouvable("Cours introuvable")
    inscriptions = session.scalars(
        select(InscriptionCours).where(InscriptionCours.cours_id == cours_id, InscriptionCours.statut == "active")
    ).all()
    return [
        recalculer_risque_etudiant_cours(session, inscription.etudiant_id, cours_id, notifier=True)
        for inscription in inscriptions
    ]


def recalculer_risques_global(session: Session, utilisateur_id: int, donnees: RecalculRisquesRequete) -> dict:
    if donnees.cours_id is not None:
        risques = _recalculer_risques_par_cours(session, donnees.cours_id)
        portee = {"cours_id": donnees.cours_id}
    elif donnees.promotion_id is not None:
        if session.get(Promotion, donnees.promotion_id) is None:
            raise RessourceIntrouvable("Promotion introuvable")
        cours_ids = list(session.scalars(select(Cours.id).where(Cours.promotion_id == donnees.promotion_id)).all())
        risques = []
        for cours_id in cours_ids:
            risques.extend(_recalculer_risques_par_cours(session, cours_id))
        portee = {"promotion_id": donnees.promotion_id}
    else:
        lignes = session.execute(
            select(InscriptionCours.etudiant_id, InscriptionCours.cours_id).where(InscriptionCours.statut == "active")
        ).all()
        risques = [
            recalculer_risque_etudiant_cours(session, etudiant_id, cours_id, notifier=True)
            for etudiant_id, cours_id in lignes
        ]
        portee = {"global": True}

    _journaliser(session, utilisateur_id, "recalcul_risques_global", "evaluations_risque", None, portee)
    session.commit()
    return {"nombre": len(risques), "risques": [_serialiser_risque(session, risque) for risque in risques]}
