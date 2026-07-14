from __future__ import annotations

from datetime import datetime
from uuid import uuid4

from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, joinedload, selectinload

from app.exceptions.erreurs import ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Cours, Etudiant, Promotion, Semestre
from app.modeles.enrolements import EnrolementAcademique, STATUTS_ENROLEMENT
from app.modeles.securite import Utilisateur
from app.schemas.academique import EnrolementAnnulation, EnrolementCreation, EnrolementModification


def _nom(utilisateur: Utilisateur | None) -> str:
    if utilisateur is None:
        return ""
    return " ".join(
        partie
        for partie in (utilisateur.prenom, utilisateur.nom, utilisateur.postnom)
        if partie and partie.strip()
    )


def _obtenir_etudiant(session: Session, etudiant_id: int) -> Etudiant:
    etudiant = session.scalar(
        select(Etudiant)
        .options(joinedload(Etudiant.utilisateur), joinedload(Etudiant.promotion))
        .where(Etudiant.id == etudiant_id)
    )
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    if etudiant.utilisateur.statut != "actif":
        raise ErreurApplication("Le compte etudiant doit etre actif")
    if etudiant.statut_academique != "actif":
        raise ErreurApplication("L etudiant n est pas academiquement actif")
    return etudiant


def _obtenir_references(
    session: Session,
    etudiant_id: int,
    promotion_id: int,
    annee_academique_id: int,
) -> tuple[Etudiant, Promotion, AnneeAcademique]:
    etudiant = _obtenir_etudiant(session, etudiant_id)
    promotion = session.scalar(
        select(Promotion)
        .options(joinedload(Promotion.annee_academique))
        .where(Promotion.id == promotion_id)
    )
    if promotion is None:
        raise RessourceIntrouvable("Promotion introuvable")
    if not promotion.est_active:
        raise ErreurApplication("La promotion n est pas active")
    if etudiant.promotion_id != promotion.id:
        raise ErreurApplication("L etudiant n appartient pas a cette promotion")

    annee = session.get(AnneeAcademique, annee_academique_id)
    if annee is None:
        raise RessourceIntrouvable("Annee academique introuvable")
    if promotion.annee_academique_id != annee.id:
        raise ErreurApplication("La promotion ne correspond pas a l annee academique")
    return etudiant, promotion, annee


def _cle_active(etudiant_id: int, promotion_id: int, annee_academique_id: int) -> str:
    return f"{etudiant_id}:{promotion_id}:{annee_academique_id}"


def _verifier_doublon(
    session: Session,
    cle: str,
    enrolement_id: int | None = None,
) -> None:
    requete = select(EnrolementAcademique.id).where(
        EnrolementAcademique.cle_doublon_actif == cle,
    )
    if enrolement_id is not None:
        requete = requete.where(EnrolementAcademique.id != enrolement_id)
    if session.scalar(requete) is not None:
        raise ConflitDonnees("Un enrolement actif existe deja pour cet etudiant")


def _reference_unique(annee: AnneeAcademique) -> str:
    return f"ENR-{annee.id:04d}-{uuid4().hex[:12].upper()}"


def _cours_programme(session: Session, promotion_id: int) -> list[dict]:
    cours = session.scalars(
        select(Cours)
        .options(joinedload(Cours.semestre))
        .where(Cours.promotion_id == promotion_id, Cours.est_actif.is_(True))
        .order_by(Cours.semestre_id, Cours.code)
    ).all()
    return [
        {
            "id": cours_item.id,
            "code": cours_item.code,
            "intitule": cours_item.intitule,
            "credits": cours_item.nombre_credits,
            "heures": cours_item.nombre_heures,
            "semestre": {
                "id": cours_item.semestre.id,
                "nom": cours_item.semestre.nom,
                "numero": cours_item.semestre.numero,
            },
        }
        for cours_item in cours
    ]


def _serialiser(enrolement: EnrolementAcademique, programme: list[dict] | None = None) -> dict:
    etudiant = enrolement.etudiant
    promotion = enrolement.promotion
    annee = enrolement.annee_academique
    donnees = {
        "id": enrolement.id,
        "reference_fiche": enrolement.reference_fiche,
        "statut": enrolement.statut,
        "date_enrolement": enrolement.date_enrolement,
        "date_validation": enrolement.date_validation,
        "date_annulation": enrolement.date_annulation,
        "motif_annulation": enrolement.motif_annulation,
        "etudiant": {
            "id": etudiant.id,
            "matricule": etudiant.matricule,
            "nom": _nom(etudiant.utilisateur),
            "promotion_id": etudiant.promotion_id,
        },
        "promotion": {
            "id": promotion.id,
            "nom": promotion.nom,
            "niveau": promotion.niveau,
            "est_active": promotion.est_active,
        },
        "annee_academique": {
            "id": annee.id,
            "libelle": annee.libelle,
            "est_active": annee.est_active,
        },
        "appariteur_responsable_id": enrolement.cree_par_utilisateur_id,
        "valide_par_utilisateur_id": enrolement.valide_par_utilisateur_id,
        "annule_par_utilisateur_id": enrolement.annule_par_utilisateur_id,
        "nombre_cours": len(programme) if programme is not None else None,
    }
    if programme is not None:
        donnees["programme"] = programme
        donnees["credits_prevus"] = sum(item["credits"] for item in programme)
    return donnees


def _charger(session: Session, enrolement_id: int) -> EnrolementAcademique:
    enrolement = session.scalar(
        select(EnrolementAcademique)
        .options(
            joinedload(EnrolementAcademique.etudiant).joinedload(Etudiant.utilisateur),
            joinedload(EnrolementAcademique.promotion),
            joinedload(EnrolementAcademique.annee_academique),
        )
        .where(EnrolementAcademique.id == enrolement_id)
    )
    if enrolement is None:
        raise RessourceIntrouvable("Enrolement introuvable")
    return enrolement


def lister(
    session: Session,
    page: int = 1,
    taille: int = 20,
    recherche: str | None = None,
    annee_academique_id: int | None = None,
    promotion_id: int | None = None,
    statut: str | None = None,
) -> dict:
    if statut is not None and statut not in STATUTS_ENROLEMENT:
        raise ErreurApplication("Statut d enrolement invalide")
    requete = (
        select(EnrolementAcademique)
        .join(EnrolementAcademique.etudiant)
        .join(Etudiant.utilisateur)
        .options(
            joinedload(EnrolementAcademique.etudiant).joinedload(Etudiant.utilisateur),
            joinedload(EnrolementAcademique.promotion),
            joinedload(EnrolementAcademique.annee_academique),
        )
    )
    total_requete = select(func.count(EnrolementAcademique.id)).join(EnrolementAcademique.etudiant).join(Etudiant.utilisateur)
    conditions = []
    if recherche and recherche.strip():
        terme = f"%{recherche.strip()}%"
        conditions.append(
            or_(
                EnrolementAcademique.reference_fiche.like(terme),
                Etudiant.matricule.like(terme),
                Utilisateur.nom.like(terme),
                Utilisateur.postnom.like(terme),
                Utilisateur.prenom.like(terme),
            )
        )
    if annee_academique_id is not None:
        conditions.append(EnrolementAcademique.annee_academique_id == annee_academique_id)
    if promotion_id is not None:
        conditions.append(EnrolementAcademique.promotion_id == promotion_id)
    if statut is not None:
        conditions.append(EnrolementAcademique.statut == statut)
    if conditions:
        requete = requete.where(*conditions)
        total_requete = total_requete.where(*conditions)
    total = session.scalar(total_requete) or 0
    elements = session.scalars(
        requete.order_by(EnrolementAcademique.id.desc())
        .offset((page - 1) * taille)
        .limit(taille)
    ).unique().all()
    return {
        "elements": [_serialiser(item) for item in elements],
        "total": total,
        "page": page,
        "taille": taille,
    }


def obtenir(session: Session, enrolement_id: int, avec_programme: bool = False) -> dict:
    enrolement = _charger(session, enrolement_id)
    programme = _cours_programme(session, enrolement.promotion_id) if avec_programme else None
    return _serialiser(enrolement, programme)


def creer(session: Session, utilisateur_id: int, donnees: EnrolementCreation) -> dict:
    _etudiant, _promotion, annee = _obtenir_references(
        session,
        donnees.etudiant_id,
        donnees.promotion_id,
        donnees.annee_academique_id,
    )
    cle = _cle_active(donnees.etudiant_id, donnees.promotion_id, donnees.annee_academique_id)
    _verifier_doublon(session, cle)
    enrolement = EnrolementAcademique(
        etudiant_id=donnees.etudiant_id,
        promotion_id=donnees.promotion_id,
        annee_academique_id=donnees.annee_academique_id,
        date_enrolement=donnees.date_enrolement,
        statut="en_attente",
        cree_par_utilisateur_id=utilisateur_id,
        reference_fiche=_reference_unique(annee),
        cle_doublon_actif=cle,
    )
    session.add(enrolement)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Un enrolement actif ou une reference existe deja") from exc
    return obtenir(session, enrolement.id)


def modifier(session: Session, enrolement_id: int, donnees: EnrolementModification) -> dict:
    enrolement = _charger(session, enrolement_id)
    if enrolement.statut != "en_attente":
        raise ConflitDonnees("Un enrolement valide ou annule ne peut plus etre modifie")
    valeurs = donnees.model_dump(exclude_unset=True)
    etudiant_id = valeurs.get("etudiant_id", enrolement.etudiant_id)
    promotion_id = valeurs.get("promotion_id", enrolement.promotion_id)
    annee_id = valeurs.get("annee_academique_id", enrolement.annee_academique_id)
    _obtenir_references(session, etudiant_id, promotion_id, annee_id)
    cle = _cle_active(etudiant_id, promotion_id, annee_id)
    _verifier_doublon(session, cle, enrolement.id)
    enrolement.etudiant_id = etudiant_id
    enrolement.promotion_id = promotion_id
    enrolement.annee_academique_id = annee_id
    enrolement.date_enrolement = valeurs.get("date_enrolement", enrolement.date_enrolement)
    enrolement.cle_doublon_actif = cle
    session.commit()
    return obtenir(session, enrolement.id)


def valider(session: Session, utilisateur_id: int, enrolement_id: int) -> dict:
    enrolement = _charger(session, enrolement_id)
    if enrolement.statut == "annule":
        raise ConflitDonnees("Un enrolement annule ne peut pas etre valide")
    if enrolement.statut == "valide":
        return obtenir(session, enrolement.id, avec_programme=True)
    _obtenir_references(
        session,
        enrolement.etudiant_id,
        enrolement.promotion_id,
        enrolement.annee_academique_id,
    )
    _verifier_doublon(session, enrolement.cle_doublon_actif or "", enrolement.id)
    enrolement.statut = "valide"
    enrolement.valide_par_utilisateur_id = utilisateur_id
    enrolement.date_validation = datetime.now()
    session.commit()
    return obtenir(session, enrolement.id, avec_programme=True)


def annuler(session: Session, utilisateur_id: int, enrolement_id: int, donnees: EnrolementAnnulation) -> dict:
    enrolement = _charger(session, enrolement_id)
    if enrolement.statut == "annule":
        return obtenir(session, enrolement.id)
    enrolement.statut = "annule"
    enrolement.annule_par_utilisateur_id = utilisateur_id
    enrolement.date_annulation = datetime.now()
    enrolement.motif_annulation = donnees.motif.strip() if donnees.motif else None
    enrolement.cle_doublon_actif = None
    session.commit()
    return obtenir(session, enrolement.id)


def lister_etudiant(session: Session, etudiant_id: int) -> list[dict]:
    _obtenir_etudiant(session, etudiant_id)
    elements = session.scalars(
        select(EnrolementAcademique)
        .options(
            joinedload(EnrolementAcademique.etudiant).joinedload(Etudiant.utilisateur),
            joinedload(EnrolementAcademique.promotion),
            joinedload(EnrolementAcademique.annee_academique),
        )
        .where(EnrolementAcademique.etudiant_id == etudiant_id)
        .order_by(EnrolementAcademique.id.desc())
    ).unique().all()
    return [_serialiser(item) for item in elements]


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if etudiant is None:
        raise RessourceIntrouvable("Profil etudiant introuvable")
    return _obtenir_etudiant(session, etudiant.id)


def _serialiser_pour_etudiant(enrolement: EnrolementAcademique, programme: list[dict]) -> dict:
    promotion = enrolement.promotion
    annee = enrolement.annee_academique
    return {
        "id": enrolement.id,
        "reference_fiche": enrolement.reference_fiche,
        "statut": enrolement.statut,
        "etudiant": {
            "matricule": enrolement.etudiant.matricule,
            "nom": _nom(enrolement.etudiant.utilisateur),
        },
        "date_enrolement": enrolement.date_enrolement,
        "date_validation": enrolement.date_validation,
        "date_annulation": enrolement.date_annulation,
        "promotion": {
            "id": promotion.id,
            "nom": promotion.nom,
            "niveau": promotion.niveau,
        },
        "annee_academique": {
            "id": annee.id,
            "libelle": annee.libelle,
            "est_active": annee.est_active,
        },
        "nombre_cours": len(programme),
        "credits_prevus": sum(item["credits"] for item in programme),
        "fiche_disponible": enrolement.statut == "valide",
        "programme": programme,
    }


def _charger_pour_etudiant(session: Session, utilisateur_id: int, enrolement_id: int) -> EnrolementAcademique:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    enrolement = session.scalar(
        select(EnrolementAcademique)
        .options(
            joinedload(EnrolementAcademique.promotion),
            joinedload(EnrolementAcademique.annee_academique),
        )
        .where(
            EnrolementAcademique.id == enrolement_id,
            EnrolementAcademique.etudiant_id == etudiant.id,
        )
    )
    if enrolement is None:
        raise RessourceIntrouvable("Enrolement introuvable")
    return enrolement


def lister_pour_etudiant(session: Session, utilisateur_id: int) -> list[dict]:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    elements = session.scalars(
        select(EnrolementAcademique)
        .options(
            joinedload(EnrolementAcademique.promotion),
            joinedload(EnrolementAcademique.annee_academique),
        )
        .where(EnrolementAcademique.etudiant_id == etudiant.id)
        .order_by(EnrolementAcademique.id.desc())
    ).all()
    return [_serialiser_pour_etudiant(item, _cours_programme(session, item.promotion_id)) for item in elements]


def obtenir_pour_etudiant(session: Session, utilisateur_id: int, enrolement_id: int) -> dict:
    enrolement = _charger_pour_etudiant(session, utilisateur_id, enrolement_id)
    return _serialiser_pour_etudiant(enrolement, _cours_programme(session, enrolement.promotion_id))


def donnees_fiche(session: Session, enrolement_id: int) -> dict:
    enrolement = _charger(session, enrolement_id)
    if enrolement.statut != "valide":
        raise ConflitDonnees("La fiche n est disponible que pour un enrolement valide")
    programme = _cours_programme(session, enrolement.promotion_id)
    return _serialiser(enrolement, programme)


def donnees_fiche_pour_etudiant(session: Session, utilisateur_id: int, enrolement_id: int) -> dict:
    enrolement = _charger_pour_etudiant(session, utilisateur_id, enrolement_id)
    if enrolement.statut != "valide":
        raise ConflitDonnees("La fiche n est disponible que pour un enrolement valide")
    return obtenir_pour_etudiant(session, utilisateur_id, enrolement_id)
