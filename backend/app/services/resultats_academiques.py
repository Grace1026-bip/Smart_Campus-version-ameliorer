from __future__ import annotations

from decimal import Decimal, ROUND_HALF_UP

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.exceptions.erreurs import AccesInterdit, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import Cours, Etudiant, InscriptionCours, Semestre
from app.modeles.notes import Evaluation, ResultatCours


ROLES_RESPONSABLES = {"appariteur", "doyen", "administrateur"}
STATUTS_RESULTAT_PUBLIE = {"reussi", "echoue"}
FORMULE_LMD_VERSION = "LMD-RDC-20-CREDITS-V1"
SEUIL_COURS_SUR_100 = Decimal("50")
SEUIL_SEMESTRE_SUR_20 = Decimal("10")


def _arrondir(valeur: Decimal | None) -> Decimal | None:
    if valeur is None:
        return None
    return valeur.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _obtenir_etudiant(session: Session, etudiant_id: int) -> Etudiant:
    etudiant = session.scalar(
        select(Etudiant)
        .options(
            selectinload(Etudiant.utilisateur),
            selectinload(Etudiant.promotion),
        )
        .where(Etudiant.id == etudiant_id)
    )
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    return etudiant


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if etudiant is None:
        raise AccesInterdit("Profil etudiant introuvable")
    return etudiant


def _obtenir_semestre_actif(session: Session, semestre_id: int) -> Semestre:
    semestre = session.scalar(
        select(Semestre)
        .options(selectinload(Semestre.annee_academique))
        .where(Semestre.id == semestre_id)
    )
    if semestre is None:
        raise RessourceIntrouvable("Semestre introuvable")
    if not semestre.annee_academique.est_active:
        raise ErreurApplication("Le semestre ne depend pas de l annee academique active")
    return semestre


def _verifier_acces(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    etudiant_id: int,
) -> None:
    if role_actif in ROLES_RESPONSABLES:
        return
    if role_actif != "etudiant":
        raise AccesInterdit("Role non autorise pour les resultats academiques")
    etudiant = session.scalar(select(Etudiant).where(Etudiant.id == etudiant_id))
    if etudiant is None or etudiant.utilisateur_id != utilisateur_id:
        raise AccesInterdit("Un etudiant ne peut consulter que ses propres resultats")


def lister_semestres(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    etudiant_id: int,
) -> list[dict]:
    _verifier_acces(session, utilisateur_id, role_actif, etudiant_id)
    etudiant = _obtenir_etudiant(session, etudiant_id)
    if etudiant.statut_academique != "actif":
        raise AccesInterdit("Le compte academique de cet etudiant n est pas actif")

    semestres = session.scalars(
        select(Semestre)
        .options(selectinload(Semestre.annee_academique))
        .where(Semestre.annee_academique.has(est_active=True))
        .order_by(Semestre.numero)
    ).all()
    compteurs: dict[int, int] = {}
    for semestre_id, _cours_id in session.execute(
        select(Cours.semestre_id, Cours.id).where(
            Cours.promotion_id == etudiant.promotion_id,
            Cours.est_actif.is_(True),
        )
    ).all():
        compteurs[semestre_id] = compteurs.get(semestre_id, 0) + 1

    return [
        {
            "id": semestre.id,
            "nom": semestre.nom,
            "numero": semestre.numero,
            "annee_academique": {
                "id": semestre.annee_academique.id,
                "libelle": semestre.annee_academique.libelle,
            },
            "nombre_cours": compteurs.get(semestre.id, 0),
        }
        for semestre in semestres
    ]


def lister_etudiants_responsable(session: Session) -> list[dict]:
    etudiants = session.scalars(
        select(Etudiant)
        .options(selectinload(Etudiant.utilisateur), selectinload(Etudiant.promotion))
        .where(Etudiant.statut_academique == "actif")
        .order_by(Etudiant.matricule)
    ).all()
    return [
        {
            "id": etudiant.id,
            "matricule": etudiant.matricule,
            "nom": " ".join(
                value
                for value in (
                    etudiant.utilisateur.nom,
                    etudiant.utilisateur.postnom,
                    etudiant.utilisateur.prenom,
                )
                if value
            ),
            "promotion": etudiant.promotion.nom,
        }
        for etudiant in etudiants
    ]


def _raison_unique(raisons: list[str], raison: str) -> None:
    if raison not in raisons:
        raisons.append(raison)


def determiner_decision(
    *,
    complet: bool,
    moyenne_sur_20: Decimal | None,
    credits_acquis: int,
    credits_prevus: int,
    raisons: list[str] | None = None,
) -> str | None:
    if not complet or moyenne_sur_20 is None or raisons:
        return "DEF" if credits_prevus > 0 else None
    if moyenne_sur_20 < SEUIL_SEMESTRE_SUR_20:
        return "AJ"
    return "ADM" if credits_acquis == credits_prevus else "COMP"


def _consolider_semestre(session: Session, etudiant_id: int, semestre_id: int) -> dict:
    etudiant = _obtenir_etudiant(session, etudiant_id)
    semestre = _obtenir_semestre_actif(session, semestre_id)
    annee = semestre.annee_academique

    if etudiant.statut_academique != "actif":
        raise AccesInterdit("Le compte academique de cet etudiant n est pas actif")
    if etudiant.promotion.annee_academique_id != annee.id:
        raise ErreurApplication("L etudiant et le semestre ne dependent pas de la meme annee academique")
    if not etudiant.promotion.est_active:
        raise ErreurApplication("La promotion de l etudiant n est pas active")

    cours = session.scalars(
        select(Cours)
        .where(
            Cours.promotion_id == etudiant.promotion_id,
            Cours.semestre_id == semestre.id,
            Cours.est_actif.is_(True),
        )
        .order_by(Cours.code)
    ).all()
    inscriptions = session.scalars(
        select(InscriptionCours).where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.annee_academique_id == annee.id,
            InscriptionCours.statut == "active",
        )
    ).all()
    cours_inscrits = {inscription.cours_id for inscription in inscriptions}
    cours_ids = [cours_item.id for cours_item in cours]
    resultats = (
        session.scalars(
            select(ResultatCours).where(
                ResultatCours.etudiant_id == etudiant.id,
                ResultatCours.cours_id.in_(cours_ids),
            )
        ).all()
        if cours_ids
        else []
    )
    resultats_par_cours = {resultat.cours_id: resultat for resultat in resultats}
    evaluations = (
        session.scalars(
            select(Evaluation).where(
                Evaluation.cours_id.in_(cours_ids),
                Evaluation.statut != "archivee",
            )
        ).all()
        if cours_ids
        else []
    )
    evaluations_par_cours: dict[int, list[Evaluation]] = {}
    for evaluation in evaluations:
        evaluations_par_cours.setdefault(evaluation.cours_id, []).append(evaluation)

    raisons: list[str] = []
    cours_resultats: list[dict] = []
    contributions: list[tuple[Decimal, int]] = []
    credits_prevus = sum(cours_item.nombre_credits for cours_item in cours)
    credits_acquis = 0

    if etudiant.promotion.annee_academique_id != annee.id:
        _raison_unique(raisons, "annee_academique_incoherente")
    if not cours:
        _raison_unique(raisons, "cours_manquant")

    for cours_item in cours:
        resultat = resultats_par_cours.get(cours_item.id)
        raison: str | None = None
        statut_validation = "en_attente"
        credits_cours_acquis = 0
        moyenne = None

        if cours_item.id not in cours_inscrits:
            raison = "inscription_cours_invalide"
        elif resultat is None or resultat.statut_resultat not in STATUTS_RESULTAT_PUBLIE:
            raison = "resultat_non_publie"
        elif not evaluations_par_cours.get(cours_item.id) or not all(
            evaluation.statut == "publiee" and evaluation.est_verrouillee
            for evaluation in evaluations_par_cours[cours_item.id]
        ):
            raison = "resultat_non_publie"
        elif resultat.statut_resultat == "reussi":
            moyenne = Decimal(str(resultat.moyenne))
            if resultat.credits_obtenus != cours_item.nombre_credits:
                raison = "credits_incoherents"
            else:
                statut_validation = "acquis"
                credits_cours_acquis = cours_item.nombre_credits
        else:
            moyenne = Decimal(str(resultat.moyenne))
            if resultat.credits_obtenus != 0:
                raison = "credits_incoherents"
            else:
                statut_validation = "non_acquis"
                raison = "seuil_non_atteint"

        if raison is not None and raison != "seuil_non_atteint":
            _raison_unique(raisons, raison)
        if moyenne is not None and raison not in {"credits_incoherents"}:
            note_sur_20 = moyenne / Decimal("5")
            contributions.append((note_sur_20, cours_item.nombre_credits))
        credits_acquis += credits_cours_acquis
        cours_resultats.append(
            {
                "cours_id": cours_item.id,
                "code": cours_item.code,
                "intitule": cours_item.intitule,
                "credits_prevus": cours_item.nombre_credits,
                "resultat_publie_sur_100": _arrondir(moyenne),
                "statut_validation": statut_validation,
                "credits_acquis": credits_cours_acquis,
                "credits_non_acquis": cours_item.nombre_credits - credits_cours_acquis,
                "raison_non_validation": raison,
            }
        )

    complet = bool(cours) and not raisons
    total_credits = sum(credits for _note, credits in contributions)
    somme_ponderee = sum(
        (note * Decimal(credits) for note, credits in contributions),
        Decimal("0"),
    )
    moyenne_semestre_sur_20 = None
    if complet and total_credits > 0:
        moyenne_semestre_sur_20 = _arrondir(somme_ponderee / Decimal(total_credits))
    moyenne_semestre_sur_100 = (
        _arrondir(moyenne_semestre_sur_20 * Decimal("5"))
        if moyenne_semestre_sur_20 is not None
        else None
    )
    decision = determiner_decision(
        complet=complet,
        moyenne_sur_20=moyenne_semestre_sur_20,
        credits_acquis=credits_acquis,
        credits_prevus=credits_prevus,
        raisons=raisons,
    )

    return {
        "etudiant": {
            "id": etudiant.id,
            "matricule": etudiant.matricule,
            "nom": " ".join(
                value
                for value in (
                    etudiant.utilisateur.nom,
                    etudiant.utilisateur.postnom,
                    etudiant.utilisateur.prenom,
                )
                if value
            ),
            "promotion": etudiant.promotion.nom,
        },
        "annee_academique": {"id": annee.id, "libelle": annee.libelle},
        "semestre": {"id": semestre.id, "nom": semestre.nom, "numero": semestre.numero},
        "etat": "aucun_cours" if not cours else "provisoire" if complet else "incomplet",
        "cours": cours_resultats,
        "credits_prevus": credits_prevus,
        "credits_acquis": credits_acquis,
        "credits_non_acquis": credits_prevus - credits_acquis,
        "credits_restants": credits_prevus - credits_acquis,
        "moyenne_semestre_sur_20": moyenne_semestre_sur_20,
        "moyenne_ponderee_sur_20": moyenne_semestre_sur_20,
        "moyenne_semestre_sur_100": moyenne_semestre_sur_100,
        "formule_moyenne": "somme(note_cours_sur_20_x_credits) / somme(credits)",
        "formule_version": FORMULE_LMD_VERSION,
        "decision_provisoire": "en_attente_de_validation" if complet else None,
        "proposition_decision": decision,
        "decision_officielle": False,
        "publie_a_etudiant": False,
        "raisons_incompletude": raisons,
        "mention": "Resultat provisoire - non encore valide officiellement",
    }


def consolider_semestre(session: Session, etudiant_id: int, semestre_id: int) -> dict:
    return _consolider_semestre(session, etudiant_id, semestre_id)


def apercu_semestre(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    etudiant_id: int,
    semestre_id: int,
) -> dict:
    _verifier_acces(session, utilisateur_id, role_actif, etudiant_id)
    return _consolider_semestre(session, etudiant_id, semestre_id)
