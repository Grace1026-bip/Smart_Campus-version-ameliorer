from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.modeles.academique import Cours, Enseignant, Etudiant, InscriptionCours, Promotion
from app.modeles.notes import ResultatCours
from app.modeles.reclamations import Reclamation
from app.modeles.suivi import EvaluationRisque
from app.modeles.valve import PublicationValve
from app.schemas.pagination import ParametresPagination, construire_page


def _compter(session: Session, requete) -> int:
    return int(session.scalar(requete) or 0)


def _decimal(valeur) -> Decimal:
    return Decimal(str(valeur or 0))


def _pourcentage(partie: int | Decimal, total: int | Decimal) -> Decimal:
    total_decimal = _decimal(total)
    if total_decimal <= 0:
        return Decimal("0.00")
    valeur = (_decimal(partie) / total_decimal) * Decimal("100")
    return valeur.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _moyenne(session: Session, requete) -> Decimal:
    valeur = session.scalar(requete)
    if valeur is None:
        return Decimal("0.00")
    return Decimal(str(valeur)).quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _serialiser_cours(cours: Cours) -> dict:
    return {
        "id": cours.id,
        "code": cours.code,
        "intitule": cours.intitule,
        "promotion_id": cours.promotion_id,
        "nombre_credits": cours.nombre_credits,
    }


def _serialiser_promotion(promotion: Promotion) -> dict:
    return {
        "id": promotion.id,
        "nom": promotion.nom,
        "niveau": promotion.niveau,
        "annee_academique_id": promotion.annee_academique_id,
        "est_active": promotion.est_active,
    }


def _compter_resultats(session: Session, statut: str | None = None, cours_id: int | None = None, promotion_id: int | None = None) -> int:
    requete = select(func.count()).select_from(ResultatCours)
    if promotion_id is not None:
        requete = requete.join(Cours, ResultatCours.cours_id == Cours.id).where(Cours.promotion_id == promotion_id)
    if statut is not None:
        requete = requete.where(ResultatCours.statut_resultat == statut)
    if cours_id is not None:
        requete = requete.where(ResultatCours.cours_id == cours_id)
    return _compter(session, requete)


def _compter_reclamations(session: Session, statut: str | None = None, promotion_id: int | None = None) -> int:
    requete = select(func.count()).select_from(Reclamation)
    if promotion_id is not None:
        requete = requete.join(Etudiant, Reclamation.etudiant_id == Etudiant.id).where(Etudiant.promotion_id == promotion_id)
    if statut is not None:
        requete = requete.where(Reclamation.statut == statut)
    return _compter(session, requete)


def _compter_risques(session: Session, niveau: str | None = None, promotion_id: int | None = None, cours_id: int | None = None) -> int:
    requete = select(func.count()).select_from(EvaluationRisque).where(EvaluationRisque.est_active.is_(True))
    if promotion_id is not None:
        requete = requete.join(Cours, EvaluationRisque.cours_id == Cours.id).where(Cours.promotion_id == promotion_id)
    if cours_id is not None:
        requete = requete.where(EvaluationRisque.cours_id == cours_id)
    if niveau is not None:
        requete = requete.where(EvaluationRisque.niveau_risque == niveau)
    return _compter(session, requete)


def obtenir_resume(session: Session) -> dict:
    reussis = _compter_resultats(session, "reussi")
    echoues = _compter_resultats(session, "echoue")
    en_attente = _compter_resultats(session, "en_attente")
    resultats_evalues = reussis + echoues

    return {
        "effectifs": {
            "etudiants": _compter(session, select(func.count()).select_from(Etudiant)),
            "enseignants": _compter(session, select(func.count()).select_from(Enseignant)),
            "promotions": _compter(session, select(func.count()).select_from(Promotion).where(Promotion.est_active.is_(True))),
            "cours": _compter(session, select(func.count()).select_from(Cours).where(Cours.est_actif.is_(True))),
        },
        "resultats": {
            "total": reussis + echoues + en_attente,
            "reussis": reussis,
            "echoues": echoues,
            "en_attente": en_attente,
            "taux_reussite": _pourcentage(reussis, resultats_evalues),
            "taux_echec": _pourcentage(echoues, resultats_evalues),
        },
        "risques": {
            "total_actifs": _compter_risques(session),
            "faible": _compter_risques(session, "faible"),
            "moyen": _compter_risques(session, "moyen"),
            "eleve": _compter_risques(session, "eleve"),
        },
        "reclamations": {
            "total": _compter_reclamations(session),
            "en_attente": _compter_reclamations(session, "en_attente"),
            "en_cours": _compter_reclamations(session, "en_cours"),
            "resolues": _compter_reclamations(session, "resolue"),
            "rejetees": _compter_reclamations(session, "rejetee"),
        },
        "valve": {
            "publications_publiees": _compter(
                session,
                select(func.count()).select_from(PublicationValve).where(PublicationValve.statut == "publiee"),
            )
        },
    }


def _indicateur_cours(session: Session, cours: Cours) -> dict:
    reussis = _compter_resultats(session, "reussi", cours_id=cours.id)
    echoues = _compter_resultats(session, "echoue", cours_id=cours.id)
    en_attente = _compter_resultats(session, "en_attente", cours_id=cours.id)
    evalues = reussis + echoues
    moyenne = _moyenne(session, select(func.avg(ResultatCours.moyenne)).where(ResultatCours.cours_id == cours.id))
    return {
        "cours": _serialiser_cours(cours),
        "inscrits": _compter(
            session,
            select(func.count()).select_from(InscriptionCours).where(
                InscriptionCours.cours_id == cours.id,
                InscriptionCours.statut == "active",
            ),
        ),
        "resultats": {
            "reussis": reussis,
            "echoues": echoues,
            "en_attente": en_attente,
            "moyenne": moyenne,
            "taux_reussite": _pourcentage(reussis, evalues),
            "taux_echec": _pourcentage(echoues, evalues),
        },
        "risques_actifs": {
            "total": _compter_risques(session, cours_id=cours.id),
            "moyen": _compter_risques(session, "moyen", cours_id=cours.id),
            "eleve": _compter_risques(session, "eleve", cours_id=cours.id),
        },
        "reclamations": _compter(
            session,
            select(func.count()).select_from(Reclamation).where(Reclamation.cours_id == cours.id),
        ),
    }


def lister_cours_difficiles(
    session: Session,
    pagination: ParametresPagination,
    promotion_id: int | None = None,
) -> dict:
    requete = select(Cours).where(Cours.est_actif.is_(True))
    if promotion_id is not None:
        requete = requete.where(Cours.promotion_id == promotion_id)
    cours = session.scalars(requete).all()
    indicateurs = [_indicateur_cours(session, item) for item in cours]
    indicateurs.sort(
        key=lambda item: (
            item["resultats"]["echoues"],
            item["resultats"]["taux_echec"],
            item["risques_actifs"]["eleve"],
            item["risques_actifs"]["moyen"],
        ),
        reverse=True,
    )
    debut = pagination.offset
    fin = pagination.offset + pagination.taille
    return construire_page(indicateurs[debut:fin], len(indicateurs), pagination.page, pagination.taille)


def lister_performances_promotions(session: Session, pagination: ParametresPagination) -> dict:
    promotions = session.scalars(select(Promotion).where(Promotion.est_active.is_(True))).all()
    indicateurs = []
    for promotion in promotions:
        reussis = _compter_resultats(session, "reussi", promotion_id=promotion.id)
        echoues = _compter_resultats(session, "echoue", promotion_id=promotion.id)
        en_attente = _compter_resultats(session, "en_attente", promotion_id=promotion.id)
        evalues = reussis + echoues
        indicateurs.append(
            {
                "promotion": _serialiser_promotion(promotion),
                "effectifs": {
                    "etudiants": _compter(
                        session,
                        select(func.count()).select_from(Etudiant).where(Etudiant.promotion_id == promotion.id),
                    ),
                    "cours": _compter(
                        session,
                        select(func.count()).select_from(Cours).where(
                            Cours.promotion_id == promotion.id,
                            Cours.est_actif.is_(True),
                        ),
                    ),
                },
                "resultats": {
                    "reussis": reussis,
                    "echoues": echoues,
                    "en_attente": en_attente,
                    "taux_reussite": _pourcentage(reussis, evalues),
                    "taux_echec": _pourcentage(echoues, evalues),
                },
                "risques_actifs": {
                    "total": _compter_risques(session, promotion_id=promotion.id),
                    "moyen": _compter_risques(session, "moyen", promotion_id=promotion.id),
                    "eleve": _compter_risques(session, "eleve", promotion_id=promotion.id),
                },
                "reclamations": {
                    "total": _compter_reclamations(session, promotion_id=promotion.id),
                    "en_attente": _compter_reclamations(session, "en_attente", promotion_id=promotion.id),
                },
            }
        )
    indicateurs.sort(
        key=lambda item: (
            item["resultats"]["taux_echec"],
            item["risques_actifs"]["eleve"],
            item["risques_actifs"]["moyen"],
        ),
        reverse=True,
    )
    debut = pagination.offset
    fin = pagination.offset + pagination.taille
    return construire_page(indicateurs[debut:fin], len(indicateurs), pagination.page, pagination.taille)


def obtenir_reclamations_dashboard(session: Session) -> dict:
    par_categorie = {
        categorie: _compter(session, select(func.count()).select_from(Reclamation).where(Reclamation.categorie == categorie))
        for categorie in ["erreur_note", "inscription", "cours", "document_academique", "autre"]
    }
    recentes = session.scalars(select(Reclamation).order_by(Reclamation.modifie_le.desc()).limit(10)).all()
    return {
        "par_statut": obtenir_resume(session)["reclamations"],
        "par_categorie": par_categorie,
        "recentes": [
            {
                "id": reclamation.id,
                "objet": reclamation.objet,
                "categorie": reclamation.categorie,
                "statut": reclamation.statut,
                "priorite": reclamation.priorite,
                "cours_id": reclamation.cours_id,
                "etudiant_id": reclamation.etudiant_id,
                "modifie_le": reclamation.modifie_le,
            }
            for reclamation in recentes
        ],
    }


def obtenir_risques_dashboard(session: Session, niveau: str | None = None) -> dict:
    conditions = [EvaluationRisque.est_active.is_(True)]
    if niveau:
        conditions.append(EvaluationRisque.niveau_risque == niveau)
    risques = session.scalars(
        select(EvaluationRisque)
        .where(*conditions)
        .order_by(EvaluationRisque.score_risque.desc(), EvaluationRisque.calcule_le.desc())
        .limit(10)
    ).all()
    return {
        "par_niveau": obtenir_resume(session)["risques"],
        "top_risques": [
            {
                "id": risque.id,
                "etudiant_id": risque.etudiant_id,
                "cours_id": risque.cours_id,
                "score_risque": risque.score_risque,
                "niveau_risque": risque.niveau_risque,
                "raisons": risque.raisons,
                "calcule_le": risque.calcule_le,
            }
            for risque in risques
        ],
    }
