from __future__ import annotations

from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.configuration.securite import hacher_mot_de_passe
from app.exceptions.erreurs import ConflitDonnees, RessourceIntrouvable
from app.modeles.academique import (
    AnneeAcademique,
    Cours,
    CoursEnseignant,
    Enseignant,
    Etudiant,
    InscriptionCours,
    Promotion,
    Semestre,
)
from app.modeles.securite import Role, Utilisateur, UtilisateurRole
from app.schemas.academique import (
    AffectationEnseignantCreation,
    AffectationEnseignantModification,
    CoursCreation,
    CoursModification,
    EnseignantCreation,
    EnseignantModification,
    EtudiantCreation,
    EtudiantModification,
    InscriptionCoursCreation,
    InscriptionCoursModification,
    PromotionCreation,
    PromotionModification,
)
from app.schemas.pagination import ParametresPagination, construire_page


def _gerer_integrite(exception: IntegrityError) -> None:
    message = str(exception.orig).lower()
    if "duplicate" in message or "duplicata" in message:
        raise ConflitDonnees("Une donnee unique existe deja") from exception
    raise ConflitDonnees("Operation impossible a cause des contraintes de donnees") from exception


def _obtenir(session: Session, modele, identifiant: int, message: str):
    instance = session.get(modele, identifiant)
    if instance is None:
        raise RessourceIntrouvable(message)
    return instance


def _liste_roles(utilisateur: Utilisateur) -> list[str]:
    return sorted({liaison.role.nom for liaison in utilisateur.roles if liaison.role})


def _serialiser_utilisateur(utilisateur: Utilisateur) -> dict:
    return {
        "id": utilisateur.id,
        "nom": utilisateur.nom,
        "postnom": utilisateur.postnom,
        "prenom": utilisateur.prenom,
        "email": utilisateur.email,
        "telephone": utilisateur.telephone,
        "statut": utilisateur.statut,
        "roles": _liste_roles(utilisateur),
    }


def _attribuer_role(session: Session, utilisateur: Utilisateur, nom_role: str) -> None:
    role = session.scalar(select(Role).where(Role.nom == nom_role))
    if role is None:
        raise RessourceIntrouvable(f"Role {nom_role} introuvable")

    existe = session.scalar(
        select(UtilisateurRole).where(
            UtilisateurRole.utilisateur_id == utilisateur.id,
            UtilisateurRole.role_id == role.id,
        )
    )
    if existe is None:
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))


def _creer_utilisateur(session: Session, donnees, nom_role: str) -> Utilisateur:
    utilisateur_existant = session.scalar(select(Utilisateur).where(Utilisateur.email == donnees.email))
    if utilisateur_existant is not None:
        raise ConflitDonnees("Email deja utilise")

    utilisateur = Utilisateur(
        nom=donnees.nom,
        postnom=donnees.postnom,
        prenom=donnees.prenom,
        email=donnees.email,
        mot_de_passe_hash=hacher_mot_de_passe(donnees.mot_de_passe),
        telephone=donnees.telephone,
        statut="actif",
    )
    session.add(utilisateur)
    session.flush()
    _attribuer_role(session, utilisateur, nom_role)
    return utilisateur


def _appliquer_modifications(instance, donnees) -> None:
    for champ, valeur in donnees.model_dump(exclude_unset=True).items():
        setattr(instance, champ, valeur)


def serialiser_promotion(promotion: Promotion) -> dict:
    return {
        "id": promotion.id,
        "nom": promotion.nom,
        "niveau": promotion.niveau,
        "description": promotion.description,
        "annee_academique_id": promotion.annee_academique_id,
        "est_active": promotion.est_active,
    }


def serialiser_cours(cours: Cours) -> dict:
    return {
        "id": cours.id,
        "code": cours.code,
        "intitule": cours.intitule,
        "description": cours.description,
        "nombre_heures": cours.nombre_heures,
        "nombre_credits": cours.nombre_credits,
        "semestre_id": cours.semestre_id,
        "promotion_id": cours.promotion_id,
        "est_actif": cours.est_actif,
    }


def serialiser_etudiant(etudiant: Etudiant) -> dict:
    return {
        "id": etudiant.id,
        "utilisateur": _serialiser_utilisateur(etudiant.utilisateur),
        "matricule": etudiant.matricule,
        "promotion_id": etudiant.promotion_id,
        "date_inscription": etudiant.date_inscription,
        "statut_academique": etudiant.statut_academique,
    }


def serialiser_enseignant(enseignant: Enseignant) -> dict:
    return {
        "id": enseignant.id,
        "utilisateur": _serialiser_utilisateur(enseignant.utilisateur),
        "matricule_agent": enseignant.matricule_agent,
        "grade": enseignant.grade,
        "departement": enseignant.departement,
        "statut": enseignant.statut,
    }


def serialiser_affectation(affectation: CoursEnseignant) -> dict:
    return {
        "id": affectation.id,
        "cours_id": affectation.cours_id,
        "enseignant_id": affectation.enseignant_id,
        "type_intervenant": affectation.type_intervenant,
        "est_responsable": affectation.est_responsable,
        "attribue_le": affectation.attribue_le,
    }


def serialiser_inscription(inscription: InscriptionCours) -> dict:
    return {
        "id": inscription.id,
        "etudiant_id": inscription.etudiant_id,
        "cours_id": inscription.cours_id,
        "annee_academique_id": inscription.annee_academique_id,
        "date_inscription": inscription.date_inscription,
        "statut": inscription.statut,
    }


def lister_promotions(
    session: Session,
    pagination: ParametresPagination,
    annee_academique_id: int | None = None,
    est_active: bool | None = None,
) -> dict:
    requete = select(Promotion)
    total_requete = select(func.count()).select_from(Promotion)
    conditions = []
    if pagination.recherche:
        conditions.append(Promotion.nom.like(f"%{pagination.recherche}%"))
    if annee_academique_id:
        conditions.append(Promotion.annee_academique_id == annee_academique_id)
    if est_active is not None:
        conditions.append(Promotion.est_active.is_(est_active))
    if conditions:
        requete = requete.where(*conditions)
        total_requete = total_requete.where(*conditions)
    total = session.scalar(total_requete) or 0
    elements = session.scalars(requete.order_by(Promotion.nom).offset(pagination.offset).limit(pagination.taille)).all()
    return construire_page([serialiser_promotion(p) for p in elements], total, pagination.page, pagination.taille)


def obtenir_promotion(session: Session, promotion_id: int) -> dict:
    return serialiser_promotion(_obtenir(session, Promotion, promotion_id, "Promotion introuvable"))


def creer_promotion(session: Session, donnees: PromotionCreation) -> dict:
    _obtenir(session, AnneeAcademique, donnees.annee_academique_id, "Annee academique introuvable")
    promotion = Promotion(**donnees.model_dump())
    session.add(promotion)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(promotion)
    return serialiser_promotion(promotion)


def modifier_promotion(session: Session, promotion_id: int, donnees: PromotionModification) -> dict:
    promotion = _obtenir(session, Promotion, promotion_id, "Promotion introuvable")
    if donnees.annee_academique_id:
        _obtenir(session, AnneeAcademique, donnees.annee_academique_id, "Annee academique introuvable")
    _appliquer_modifications(promotion, donnees)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(promotion)
    return serialiser_promotion(promotion)


def desactiver_promotion(session: Session, promotion_id: int) -> None:
    promotion = _obtenir(session, Promotion, promotion_id, "Promotion introuvable")
    promotion.est_active = False
    session.commit()


def lister_cours(
    session: Session,
    pagination: ParametresPagination,
    promotion_id: int | None = None,
    semestre_id: int | None = None,
    est_actif: bool | None = None,
) -> dict:
    requete = select(Cours)
    total_requete = select(func.count()).select_from(Cours)
    conditions = []
    if pagination.recherche:
        conditions.append(or_(Cours.code.like(f"%{pagination.recherche}%"), Cours.intitule.like(f"%{pagination.recherche}%")))
    if promotion_id:
        conditions.append(Cours.promotion_id == promotion_id)
    if semestre_id:
        conditions.append(Cours.semestre_id == semestre_id)
    if est_actif is not None:
        conditions.append(Cours.est_actif.is_(est_actif))
    if conditions:
        requete = requete.where(*conditions)
        total_requete = total_requete.where(*conditions)
    total = session.scalar(total_requete) or 0
    elements = session.scalars(requete.order_by(Cours.code).offset(pagination.offset).limit(pagination.taille)).all()
    return construire_page([serialiser_cours(c) for c in elements], total, pagination.page, pagination.taille)


def obtenir_cours(session: Session, cours_id: int) -> dict:
    return serialiser_cours(_obtenir(session, Cours, cours_id, "Cours introuvable"))


def creer_cours(session: Session, donnees: CoursCreation) -> dict:
    _obtenir(session, Semestre, donnees.semestre_id, "Semestre introuvable")
    _obtenir(session, Promotion, donnees.promotion_id, "Promotion introuvable")
    cours = Cours(**donnees.model_dump())
    session.add(cours)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(cours)
    return serialiser_cours(cours)


def modifier_cours(session: Session, cours_id: int, donnees: CoursModification) -> dict:
    cours = _obtenir(session, Cours, cours_id, "Cours introuvable")
    if donnees.semestre_id:
        _obtenir(session, Semestre, donnees.semestre_id, "Semestre introuvable")
    if donnees.promotion_id:
        _obtenir(session, Promotion, donnees.promotion_id, "Promotion introuvable")
    _appliquer_modifications(cours, donnees)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(cours)
    return serialiser_cours(cours)


def desactiver_cours(session: Session, cours_id: int) -> None:
    cours = _obtenir(session, Cours, cours_id, "Cours introuvable")
    cours.est_actif = False
    session.commit()


def lister_etudiants(session: Session, pagination: ParametresPagination, promotion_id: int | None = None) -> dict:
    requete = select(Etudiant).options(selectinload(Etudiant.utilisateur))
    total_requete = select(func.count()).select_from(Etudiant)
    conditions = []
    if promotion_id:
        conditions.append(Etudiant.promotion_id == promotion_id)
    if pagination.recherche:
        requete = requete.join(Utilisateur)
        total_requete = total_requete.join(Utilisateur, Etudiant.utilisateur_id == Utilisateur.id)
        conditions.append(
            or_(
                Etudiant.matricule.like(f"%{pagination.recherche}%"),
                Utilisateur.nom.like(f"%{pagination.recherche}%"),
                Utilisateur.prenom.like(f"%{pagination.recherche}%"),
                Utilisateur.email.like(f"%{pagination.recherche}%"),
            )
        )
    if conditions:
        requete = requete.where(*conditions)
        total_requete = total_requete.where(*conditions)
    total = session.scalar(total_requete) or 0
    elements = session.scalars(requete.order_by(Etudiant.id.desc()).offset(pagination.offset).limit(pagination.taille)).all()
    return construire_page([serialiser_etudiant(e) for e in elements], total, pagination.page, pagination.taille)


def obtenir_etudiant(session: Session, etudiant_id: int) -> dict:
    etudiant = session.scalar(select(Etudiant).options(selectinload(Etudiant.utilisateur)).where(Etudiant.id == etudiant_id))
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    return serialiser_etudiant(etudiant)


def creer_etudiant(session: Session, donnees: EtudiantCreation) -> dict:
    _obtenir(session, Promotion, donnees.promotion_id, "Promotion introuvable")
    utilisateur = _creer_utilisateur(session, donnees.utilisateur, "etudiant")
    etudiant = Etudiant(
        utilisateur_id=utilisateur.id,
        matricule=donnees.matricule,
        promotion_id=donnees.promotion_id,
        date_inscription=donnees.date_inscription,
        statut_academique=donnees.statut_academique,
    )
    session.add(etudiant)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    return obtenir_etudiant(session, etudiant.id)


def modifier_etudiant(session: Session, etudiant_id: int, donnees: EtudiantModification) -> dict:
    etudiant = session.scalar(select(Etudiant).options(selectinload(Etudiant.utilisateur)).where(Etudiant.id == etudiant_id))
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    if donnees.promotion_id:
        _obtenir(session, Promotion, donnees.promotion_id, "Promotion introuvable")

    valeurs = donnees.model_dump(exclude_unset=True)
    for champ in ["nom", "postnom", "prenom", "telephone"]:
        if champ in valeurs:
            setattr(etudiant.utilisateur, champ, valeurs.pop(champ))
    for champ, valeur in valeurs.items():
        setattr(etudiant, champ, valeur)

    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    return obtenir_etudiant(session, etudiant_id)


def lister_enseignants(session: Session, pagination: ParametresPagination, departement: str | None = None) -> dict:
    requete = select(Enseignant).options(selectinload(Enseignant.utilisateur))
    total_requete = select(func.count()).select_from(Enseignant)
    conditions = []
    if departement:
        conditions.append(Enseignant.departement == departement)
    if pagination.recherche:
        requete = requete.join(Utilisateur)
        total_requete = total_requete.join(Utilisateur, Enseignant.utilisateur_id == Utilisateur.id)
        conditions.append(
            or_(
                Enseignant.matricule_agent.like(f"%{pagination.recherche}%"),
                Utilisateur.nom.like(f"%{pagination.recherche}%"),
                Utilisateur.prenom.like(f"%{pagination.recherche}%"),
                Utilisateur.email.like(f"%{pagination.recherche}%"),
            )
        )
    if conditions:
        requete = requete.where(*conditions)
        total_requete = total_requete.where(*conditions)
    total = session.scalar(total_requete) or 0
    elements = session.scalars(requete.order_by(Enseignant.id.desc()).offset(pagination.offset).limit(pagination.taille)).all()
    return construire_page([serialiser_enseignant(e) for e in elements], total, pagination.page, pagination.taille)


def obtenir_enseignant(session: Session, enseignant_id: int) -> dict:
    enseignant = session.scalar(
        select(Enseignant).options(selectinload(Enseignant.utilisateur)).where(Enseignant.id == enseignant_id)
    )
    if enseignant is None:
        raise RessourceIntrouvable("Enseignant introuvable")
    return serialiser_enseignant(enseignant)


def creer_enseignant(session: Session, donnees: EnseignantCreation) -> dict:
    utilisateur = _creer_utilisateur(session, donnees.utilisateur, "enseignant")
    enseignant = Enseignant(
        utilisateur_id=utilisateur.id,
        matricule_agent=donnees.matricule_agent,
        grade=donnees.grade,
        departement=donnees.departement,
        statut=donnees.statut,
    )
    session.add(enseignant)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    return obtenir_enseignant(session, enseignant.id)


def modifier_enseignant(session: Session, enseignant_id: int, donnees: EnseignantModification) -> dict:
    enseignant = session.scalar(
        select(Enseignant).options(selectinload(Enseignant.utilisateur)).where(Enseignant.id == enseignant_id)
    )
    if enseignant is None:
        raise RessourceIntrouvable("Enseignant introuvable")
    valeurs = donnees.model_dump(exclude_unset=True)
    for champ in ["nom", "postnom", "prenom", "telephone"]:
        if champ in valeurs:
            setattr(enseignant.utilisateur, champ, valeurs.pop(champ))
    for champ, valeur in valeurs.items():
        setattr(enseignant, champ, valeur)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    return obtenir_enseignant(session, enseignant_id)


def affecter_enseignant(session: Session, cours_id: int, donnees: AffectationEnseignantCreation) -> dict:
    _obtenir(session, Cours, cours_id, "Cours introuvable")
    _obtenir(session, Enseignant, donnees.enseignant_id, "Enseignant introuvable")
    affectation = CoursEnseignant(
        cours_id=cours_id,
        enseignant_id=donnees.enseignant_id,
        type_intervenant=donnees.type_intervenant,
        est_responsable=donnees.est_responsable,
    )
    session.add(affectation)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(affectation)
    return serialiser_affectation(affectation)


def modifier_affectation(session: Session, affectation_id: int, donnees: AffectationEnseignantModification) -> dict:
    affectation = _obtenir(session, CoursEnseignant, affectation_id, "Affectation introuvable")
    _appliquer_modifications(affectation, donnees)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(affectation)
    return serialiser_affectation(affectation)


def retirer_affectation(session: Session, affectation_id: int) -> None:
    affectation = _obtenir(session, CoursEnseignant, affectation_id, "Affectation introuvable")
    session.delete(affectation)
    session.commit()


def inscrire_etudiant_cours(session: Session, donnees: InscriptionCoursCreation) -> dict:
    _obtenir(session, Etudiant, donnees.etudiant_id, "Etudiant introuvable")
    _obtenir(session, Cours, donnees.cours_id, "Cours introuvable")
    _obtenir(session, AnneeAcademique, donnees.annee_academique_id, "Annee academique introuvable")
    inscription = InscriptionCours(**donnees.model_dump())
    session.add(inscription)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        _gerer_integrite(exc)
    session.refresh(inscription)
    return serialiser_inscription(inscription)


def modifier_inscription(session: Session, inscription_id: int, donnees: InscriptionCoursModification) -> dict:
    inscription = _obtenir(session, InscriptionCours, inscription_id, "Inscription introuvable")
    inscription.statut = donnees.statut
    session.commit()
    session.refresh(inscription)
    return serialiser_inscription(inscription)


def retirer_inscription(session: Session, inscription_id: int) -> dict:
    inscription = _obtenir(session, InscriptionCours, inscription_id, "Inscription introuvable")
    inscription.statut = "retiree"
    session.commit()
    session.refresh(inscription)
    return serialiser_inscription(inscription)
