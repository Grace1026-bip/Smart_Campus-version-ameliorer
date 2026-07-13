from __future__ import annotations

from sqlalchemy import select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.exceptions.erreurs import AccesInterdit, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Enseignant, Etudiant, Promotion
from app.modeles.projets import EncadrementProjet, ProjetAcademique, ROLES_ENCADREMENT, STATUTS_PROJET, TYPES_PROJET
from app.modeles.securite import Utilisateur


LIBELLES_TYPES_PROJET = {
    "reseaux": "Reseaux",
    "systemes_embarques": "Systemes embarques",
    "intelligence_artificielle": "Intelligence artificielle",
    "genie_logiciel": "Genie logiciel",
}


def _enseignant_actif(session: Session, utilisateur_id: int) -> Enseignant:
    enseignant = session.scalar(
        select(Enseignant)
        .join(Enseignant.utilisateur)
        .options(joinedload(Enseignant.utilisateur))
        .where(
            Enseignant.utilisateur_id == utilisateur_id,
            Enseignant.statut == "actif",
            Utilisateur.statut == "actif",
        )
    )
    if enseignant is None:
        raise AccesInterdit("Profil enseignant indisponible")
    return enseignant


def _nom(utilisateur: Utilisateur | None) -> str:
    if utilisateur is None:
        return ""
    return " ".join(partie for partie in (utilisateur.prenom, utilisateur.nom, utilisateur.postnom) if partie)


def _annee(annee: AnneeAcademique | None) -> dict | None:
    if annee is None:
        return None
    return {"id": annee.id, "libelle": annee.libelle, "est_active": annee.est_active}


def _student(etudiant: Etudiant) -> dict:
    return {
        "id": etudiant.id,
        "matricule": etudiant.matricule,
        "nom": _nom(etudiant.utilisateur),
        "promotion": {
            "id": etudiant.promotion.id,
            "nom": etudiant.promotion.nom,
            "niveau": etudiant.promotion.niveau,
        },
    }


def _other_supervisors(encadrement: EncadrementProjet) -> list[dict]:
    result: list[dict] = []
    for other in encadrement.projet.encadrements:
        if not other.actif or other.enseignant_id == encadrement.enseignant_id:
            continue
        result.append(
            {
                "enseignant_id": other.enseignant_id,
                "nom": _nom(other.enseignant.utilisateur),
                "role_encadrement": other.role_encadrement,
            }
        )
    return result


def _serialiser(encadrement: EncadrementProjet) -> dict:
    projet = encadrement.projet
    return {
        "id": encadrement.id,
        "encadrement_id": encadrement.id,
        "projet": {
            "id": projet.id,
            "titre": projet.titre,
            "description": projet.description,
            "type_projet": projet.type_projet,
            "type_projet_libelle": LIBELLES_TYPES_PROJET[projet.type_projet],
            "statut": projet.statut,
            "promotion": {
                "id": projet.promotion.id,
                "nom": projet.promotion.nom,
                "niveau": projet.promotion.niveau,
            },
            "annee_academique": _annee(projet.annee_academique),
        },
        "etudiant": _student(projet.etudiant),
        "type_projet": projet.type_projet,
        "type_projet_libelle": LIBELLES_TYPES_PROJET[projet.type_projet],
        "statut": projet.statut,
        "role_encadrement": encadrement.role_encadrement,
        "date_attribution": encadrement.date_attribution,
        "date_fin": encadrement.date_fin,
        "autres_encadreurs": _other_supervisors(encadrement),
    }


def _requete_encadrements(enseignant_id: int):
    return (
        select(EncadrementProjet)
        .join(EncadrementProjet.projet)
        .options(
            joinedload(EncadrementProjet.projet)
            .joinedload(ProjetAcademique.etudiant)
            .joinedload(Etudiant.utilisateur),
            joinedload(EncadrementProjet.projet)
            .joinedload(ProjetAcademique.etudiant)
            .joinedload(Etudiant.promotion),
            joinedload(EncadrementProjet.projet)
            .joinedload(ProjetAcademique.promotion),
            joinedload(EncadrementProjet.projet)
            .joinedload(ProjetAcademique.annee_academique),
            joinedload(EncadrementProjet.projet)
            .selectinload(ProjetAcademique.encadrements)
            .joinedload(EncadrementProjet.enseignant)
            .joinedload(Enseignant.utilisateur),
        )
        .where(
            EncadrementProjet.enseignant_id == enseignant_id,
            EncadrementProjet.actif.is_(True),
            ProjetAcademique.statut != "archive",
        )
        .order_by(ProjetAcademique.titre, EncadrementProjet.id)
    )


def lister_encadrements(
    session: Session,
    utilisateur_id: int,
    type_projet: str | None = None,
    statut: str | None = None,
    annee_academique_id: int | None = None,
    recherche: str | None = None,
) -> list[dict]:
    enseignant = _enseignant_actif(session, utilisateur_id)
    if type_projet is not None and type_projet not in TYPES_PROJET:
        raise ErreurApplication("Type de projet invalide")
    if statut is not None and statut not in STATUTS_PROJET:
        raise ErreurApplication("Statut de projet invalide")
    encadrements = list(session.scalars(_requete_encadrements(enseignant.id)).all())
    terme = recherche.strip().lower() if recherche else None
    resultats = []
    for encadrement in encadrements:
        projet = encadrement.projet
        if type_projet is not None and projet.type_projet != type_projet:
            continue
        if statut is not None and projet.statut != statut:
            continue
        if annee_academique_id is not None and projet.annee_academique_id != annee_academique_id:
            continue
        if terme:
            haystack = " ".join(
                (
                    projet.titre,
                    projet.type_projet,
                    projet.etudiant.matricule,
                    _nom(projet.etudiant.utilisateur),
                )
            ).lower()
            if terme not in haystack:
                continue
        resultats.append(_serialiser(encadrement))
    return resultats


def obtenir_encadrement(session: Session, utilisateur_id: int, encadrement_id: int) -> dict:
    enseignant = _enseignant_actif(session, utilisateur_id)
    encadrement = session.scalar(_requete_encadrements(enseignant.id).where(EncadrementProjet.id == encadrement_id))
    if encadrement is None:
        raise RessourceIntrouvable("Encadrement non attribue a cet enseignant")
    return _serialiser(encadrement)
