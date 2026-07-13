from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.exceptions.erreurs import AccesInterdit, RessourceIntrouvable
from app.modeles.academique import Cours, CoursEnseignant, Enseignant, Promotion, Semestre
from app.modeles.securite import Utilisateur
from app.services.authentification import roles_utilisateur


def _obtenir_enseignant_actif(session: Session, utilisateur_id: int) -> Enseignant:
    enseignant = session.scalar(
        select(Enseignant)
        .options(joinedload(Enseignant.utilisateur))
        .where(Enseignant.utilisateur_id == utilisateur_id)
    )
    if enseignant is None or enseignant.statut != "actif":
        raise AccesInterdit("Profil enseignant indisponible")
    return enseignant


def _annee(annee) -> dict | None:
    if annee is None:
        return None
    return {"id": annee.id, "libelle": annee.libelle, "est_active": annee.est_active}


def _serialiser_cours(affectation: CoursEnseignant) -> dict:
    cours = affectation.cours
    promotion = cours.promotion
    semestre = cours.semestre
    nombre_etudiants = sum(
        1 for inscription in cours.inscriptions if inscription.statut in {"active", "validee"}
    )
    return {
        "id": cours.id,
        "code": cours.code,
        "intitule": cours.intitule,
        "nom": cours.intitule,
        "description": cours.description,
        "nombre_heures": cours.nombre_heures,
        "credits": cours.nombre_credits,
        "nombre_credits": cours.nombre_credits,
        "semestre_id": cours.semestre_id,
        "semestre": {
            "id": semestre.id,
            "nom": semestre.nom,
            "numero": semestre.numero,
            "annee_academique": _annee(semestre.annee_academique),
        },
        "promotion_id": cours.promotion_id,
        "promotion": {
            "id": promotion.id,
            "nom": promotion.nom,
            "niveau": promotion.niveau,
            "annee_academique": _annee(promotion.annee_academique),
        },
        "annee_academique": _annee(semestre.annee_academique),
        "est_actif": cours.est_actif,
        "nombre_etudiants": nombre_etudiants,
        "affectation": {
            "id": affectation.id,
            "type_intervenant": affectation.type_intervenant,
            "est_responsable": affectation.est_responsable,
            "attribue_le": affectation.attribue_le,
        },
    }


def obtenir_profil(session: Session, utilisateur_id: int, role_actif: str) -> dict:
    enseignant = _obtenir_enseignant_actif(session, utilisateur_id)
    utilisateur: Utilisateur = enseignant.utilisateur
    nom_complet = " ".join(
        partie for partie in (utilisateur.nom, utilisateur.postnom, utilisateur.prenom) if partie
    )
    return {
        "id": enseignant.id,
        "utilisateur_id": utilisateur.id,
        "nom": utilisateur.nom,
        "postnom": utilisateur.postnom,
        "prenom": utilisateur.prenom,
        "nom_complet": nom_complet,
        "email": utilisateur.email,
        "telephone": utilisateur.telephone,
        "photo": utilisateur.photo,
        "matricule_agent": enseignant.matricule_agent,
        "grade": enseignant.grade,
        "departement": enseignant.departement,
        "faculte": enseignant.departement,
        "statut": enseignant.statut,
        "statut_compte": utilisateur.statut,
        "roles": roles_utilisateur(utilisateur),
        "role_actif": role_actif,
    }


def _requete_affectations(utilisateur_id: int):
    return (
        select(CoursEnseignant)
        .join(CoursEnseignant.enseignant)
        .join(CoursEnseignant.cours)
        .options(
            selectinload(CoursEnseignant.cours)
            .joinedload(Cours.promotion)
            .joinedload(Promotion.annee_academique),
            selectinload(CoursEnseignant.cours)
            .joinedload(Cours.semestre)
            .joinedload(Semestre.annee_academique),
            selectinload(CoursEnseignant.cours).selectinload(Cours.inscriptions),
        )
        .where(
            Enseignant.utilisateur_id == utilisateur_id,
            Enseignant.statut == "actif",
            Cours.est_actif.is_(True),
        )
        .order_by(Cours.code)
    )


def lister_cours(session: Session, utilisateur_id: int) -> list[dict]:
    affectations = session.scalars(_requete_affectations(utilisateur_id)).all()
    return [_serialiser_cours(affectation) for affectation in affectations]


def obtenir_cours(session: Session, utilisateur_id: int, cours_id: int) -> dict:
    affectation = session.scalar(
        _requete_affectations(utilisateur_id).where(CoursEnseignant.cours_id == cours_id)
    )
    if affectation is None:
        raise RessourceIntrouvable("Cours non attribue a cet enseignant")
    return _serialiser_cours(affectation)
