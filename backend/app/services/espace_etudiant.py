from __future__ import annotations

from sqlalchemy import func, select
from sqlalchemy.orm import Session, joinedload

from app.exceptions.erreurs import AccesInterdit, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Cours, Etudiant, InscriptionCours, Promotion, Semestre
from app.modeles.enrolements import EnrolementAcademique
from app.modeles.notes import Evaluation, ResultatCours
from app.modeles.valve import PublicationValve
from app.services import projets


STATUTS_RESULTAT_OFFICIEL = {"reussi", "echoue"}


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(
        select(Etudiant)
        .options(
            joinedload(Etudiant.utilisateur),
            joinedload(Etudiant.promotion).joinedload(Promotion.annee_academique),
        )
        .where(Etudiant.utilisateur_id == utilisateur_id)
    )
    if (
        etudiant is None
        or etudiant.statut_academique != "actif"
        or etudiant.utilisateur.statut != "actif"
    ):
        raise AccesInterdit("Profil etudiant indisponible")
    return etudiant


def _nom_etudiant(etudiant: Etudiant) -> str:
    utilisateur = etudiant.utilisateur
    return " ".join(
        morceau
        for morceau in (utilisateur.nom, utilisateur.postnom, utilisateur.prenom)
        if morceau
    )


def _inscriptions_courantes(session: Session, etudiant: Etudiant) -> list[tuple[InscriptionCours, Cours]]:
    lignes = session.execute(
        select(InscriptionCours, Cours)
        .join(Cours, Cours.id == InscriptionCours.cours_id)
        .join(Promotion, Promotion.id == Cours.promotion_id)
        .join(Semestre, Semestre.id == Cours.semestre_id)
        .join(AnneeAcademique, AnneeAcademique.id == Semestre.annee_academique_id)
        .where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.statut == "active",
            InscriptionCours.annee_academique_id == Semestre.annee_academique_id,
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Cours.promotion_id == etudiant.promotion_id,
            Promotion.est_active.is_(True),
        )
        .order_by(Semestre.numero, Cours.code)
    ).all()
    return list(lignes)


def _cours_detail(cours: Cours) -> dict:
    semestre = cours.semestre
    annee = semestre.annee_academique if semestre else None
    promotion = cours.promotion
    return {
        "id": cours.id,
        "code": cours.code,
        "intitule": cours.intitule,
        "description": cours.description,
        "nombre_heures": cours.nombre_heures,
        "nombre_credits": cours.nombre_credits,
        "promotion_id": cours.promotion_id,
        "promotion": promotion.nom if promotion else None,
        "niveau": promotion.niveau if promotion else None,
        "semestre_id": cours.semestre_id,
        "semestre": semestre.nom if semestre else None,
        "numero_semestre": semestre.numero if semestre else None,
        "annee_academique_id": annee.id if annee else None,
        "annee_academique": annee.libelle if annee else None,
    }


def _resultat_officiel_cours(session: Session, etudiant_id: int, cours_id: int) -> dict | None:
    resultat = session.scalar(
        select(ResultatCours).where(
            ResultatCours.etudiant_id == etudiant_id,
            ResultatCours.cours_id == cours_id,
        )
    )
    evaluations = session.scalars(
        select(Evaluation).where(
            Evaluation.cours_id == cours_id,
            Evaluation.statut != "archivee",
        )
    ).all()
    if (
        resultat is None
        or resultat.statut_resultat not in STATUTS_RESULTAT_OFFICIEL
        or not evaluations
        or not all(evaluation.statut == "publiee" for evaluation in evaluations)
    ):
        return None
    return {
        "id": resultat.id,
        "cours_id": resultat.cours_id,
        "moyenne": resultat.moyenne,
        "credits_obtenus": resultat.credits_obtenus,
        "statut_resultat": resultat.statut_resultat,
        "statut_affichage": "publie",
        "calcule_le": resultat.calcule_le,
    }


def _serialiser_carte_cours(session: Session, etudiant_id: int, cours: Cours) -> dict:
    publications = session.scalars(
        select(PublicationValve)
        .where(PublicationValve.cours_id == cours.id, PublicationValve.statut == "publiee")
        .order_by(PublicationValve.publie_le.desc())
        .limit(1)
    ).all()
    return {
        "cours": _cours_detail(cours),
        "resultat": _resultat_officiel_cours(session, etudiant_id, cours.id),
        "nombre_publications": session.scalar(
            select(func.count(PublicationValve.id)).where(
                PublicationValve.cours_id == cours.id,
                PublicationValve.statut == "publiee",
            )
        ) or 0,
        "derniere_publication": (
            {
                "id": publication.id,
                "cours_id": publication.cours_id,
                "titre": publication.titre,
                "type_publication": publication.type_publication,
                "publie_le": publication.publie_le,
                "est_importante": publication.est_importante,
            }
            if (publication := (publications[0] if publications else None)) is not None
            else None
        ),
    }


def lister_cours(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    lignes = _inscriptions_courantes(session, etudiant)
    return {
        "cours": [_serialiser_carte_cours(session, etudiant.id, cours) for _inscription, cours in lignes],
        "annee_academique": {
            "id": etudiant.promotion.annee_academique.id,
            "libelle": etudiant.promotion.annee_academique.libelle,
        },
        "promotion": {"id": etudiant.promotion.id, "nom": etudiant.promotion.nom, "niveau": etudiant.promotion.niveau},
    }


def obtenir_cours(session: Session, utilisateur_id: int, cours_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    cours = next((cours for _inscription, cours in _inscriptions_courantes(session, etudiant) if cours.id == cours_id), None)
    if cours is None:
        raise RessourceIntrouvable("Cours introuvable dans votre inscription active")
    return _serialiser_carte_cours(session, etudiant.id, cours)


def tableau_de_bord(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    cours = _inscriptions_courantes(session, etudiant)
    projets_etudiant = projets.lister_projets_etudiant(session, utilisateur_id)["elements"]
    enrolement = session.scalar(
        select(EnrolementAcademique)
        .where(
            EnrolementAcademique.etudiant_id == etudiant.id,
            EnrolementAcademique.annee_academique_id == etudiant.promotion.annee_academique_id,
        )
        .order_by(EnrolementAcademique.id.desc())
    )
    cartes = [_serialiser_carte_cours(session, etudiant.id, item[1]) for item in cours]
    publications = [
        carte["derniere_publication"]
        for carte in cartes
        if carte["derniere_publication"] is not None
    ]
    resultats = [carte["resultat"] for carte in cartes if carte["resultat"] is not None]
    utilisateur = etudiant.utilisateur
    return {
        "profil": {
            "id": etudiant.id,
            "nom": utilisateur.nom,
            "postnom": utilisateur.postnom,
            "prenom": utilisateur.prenom,
            "nom_complet": _nom_etudiant(etudiant),
            "email": utilisateur.email,
            "matricule": etudiant.matricule,
            "statut": etudiant.statut_academique,
            "promotion": etudiant.promotion.nom,
            "niveau": etudiant.promotion.niveau,
            "annee_academique": etudiant.promotion.annee_academique.libelle,
        },
        "nombre_cours": len(cartes),
        "cours": cartes,
        "dernieres_annonces": publications[:5],
        "nombre_resultats_officiels": len(resultats),
        "inscription_academique": {
            "statut": enrolement.statut if enrolement else "non_enregistree",
            "reference": enrolement.reference_fiche if enrolement else None,
        },
        "projets": projets_etudiant,
        "etat": "actif" if cartes else "aucune_inscription_active",
    }


def historique_academique(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    lignes = session.execute(
        select(InscriptionCours, Cours, Promotion, Semestre, AnneeAcademique)
        .join(Cours, Cours.id == InscriptionCours.cours_id)
        .join(Promotion, Promotion.id == Cours.promotion_id)
        .join(Semestre, Semestre.id == Cours.semestre_id)
        .join(AnneeAcademique, AnneeAcademique.id == InscriptionCours.annee_academique_id)
        .where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.statut.in_(["active", "validee"]),
        )
        .order_by(AnneeAcademique.libelle.desc(), Promotion.nom, Semestre.numero, Cours.code)
    ).all()
    groupes: dict[tuple[int, int, int], dict] = {}
    for _inscription, cours, promotion, semestre, annee in lignes:
        cle = (annee.id, promotion.id, semestre.id)
        groupe = groupes.setdefault(
            cle,
            {
                "annee_academique": {"id": annee.id, "libelle": annee.libelle},
                "promotion": {"id": promotion.id, "nom": promotion.nom, "niveau": promotion.niveau},
                "semestre": {"id": semestre.id, "nom": semestre.nom, "numero": semestre.numero},
                "cours": [],
            },
        )
        groupe["cours"].append(
            {
                **_cours_detail(cours),
                "resultat": _resultat_officiel_cours(session, etudiant.id, cours.id),
            }
        )
    return {"groupes": list(groupes.values())}
