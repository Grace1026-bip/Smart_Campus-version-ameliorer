from __future__ import annotations

from secrets import token_urlsafe

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.configuration.securite import hacher_mot_de_passe, maintenant_utc
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, RessourceIntrouvable
from app.modeles.academique import Enseignant, Etudiant, Promotion
from app.modeles.inscriptions import DemandeInscription
from app.modeles.securite import Role, Utilisateur, UtilisateurRole
from app.schemas.inscriptions import DemandeInscriptionCreation, RejetDemandeInscription


ROLES_APPROBATION_ETUDIANT = {"appariteur", "chef_promotion"}
ROLES_APPROBATION_ENSEIGNANT = {"appariteur", "doyen"}


def _reference() -> str:
    return "SF-" + token_urlsafe(12).replace("-", "").replace("_", "")[:16].upper()


def _serialiser_demande(demande: DemandeInscription, interne: bool = False) -> dict:
    donnees = {
        "id": demande.id,
        "reference": demande.reference,
        "type_demande": demande.type_demande,
        "email": demande.email,
        "nom": demande.nom,
        "postnom": demande.postnom,
        "prenom": demande.prenom,
        "telephone": demande.telephone,
        "matricule": demande.matricule,
        "promotion_id": demande.promotion_id,
        "matricule_agent": demande.matricule_agent,
        "grade": demande.grade,
        "departement": demande.departement,
        "statut": demande.statut,
        "motif_rejet": demande.motif_rejet,
        "utilisateur_id": demande.utilisateur_id,
        "cree_le": demande.cree_le.isoformat() if demande.cree_le else None,
        "traite_le": demande.traite_le.isoformat() if demande.traite_le else None,
    }
    return donnees


def _role(session: Session, nom: str) -> Role:
    role = session.scalar(select(Role).where(Role.nom == nom))
    if role is None:
        raise RessourceIntrouvable(f"Role {nom} introuvable")
    return role


def _attribuer_role(session: Session, utilisateur: Utilisateur, nom_role: str, attribue_par: int | None) -> None:
    role = _role(session, nom_role)
    existe = session.scalar(
        select(UtilisateurRole).where(
            UtilisateurRole.utilisateur_id == utilisateur.id,
            UtilisateurRole.role_id == role.id,
        )
    )
    if existe is None:
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id, attribue_par=attribue_par))


def _verifier_doublons(session: Session, donnees: DemandeInscriptionCreation) -> None:
    if session.scalar(select(Utilisateur.id).where(Utilisateur.email == donnees.email)) is not None:
        raise ConflitDonnees("Email deja utilise par un compte")
    if (
        session.scalar(
            select(DemandeInscription.id).where(
                DemandeInscription.email == donnees.email,
                DemandeInscription.statut == "en_attente",
            )
        )
        is not None
    ):
        raise ConflitDonnees("Une demande en attente existe deja pour cet email")
    if donnees.type_demande == "etudiant":
        if session.scalar(select(Etudiant.id).where(Etudiant.matricule == donnees.matricule)) is not None:
            raise ConflitDonnees("Matricule deja utilise")
        promotion = session.get(Promotion, donnees.promotion_id)
        if promotion is None or not promotion.est_active:
            raise RessourceIntrouvable("Promotion introuvable ou inactive")
    if donnees.type_demande == "enseignant" and donnees.matricule_agent:
        if session.scalar(select(Enseignant.id).where(Enseignant.matricule_agent == donnees.matricule_agent)) is not None:
            raise ConflitDonnees("Matricule agent deja utilise")


def creer_demande(session: Session, donnees: DemandeInscriptionCreation) -> dict:
    _verifier_doublons(session, donnees)
    demande = DemandeInscription(
        reference=_reference(),
        type_demande=donnees.type_demande,
        email=donnees.email,
        nom=donnees.nom.strip(),
        postnom=donnees.postnom,
        prenom=donnees.prenom,
        telephone=donnees.telephone,
        mot_de_passe_hash=hacher_mot_de_passe(donnees.mot_de_passe),
        matricule=donnees.matricule,
        promotion_id=donnees.promotion_id,
        matricule_agent=donnees.matricule_agent,
        grade=donnees.grade,
        departement=donnees.departement,
        statut="en_attente",
    )
    session.add(demande)
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Demande impossible a creer") from exc
    session.refresh(demande)
    return _serialiser_demande(demande)


def consulter_statut(session: Session, reference: str, email: str) -> dict:
    demande = session.scalar(
        select(DemandeInscription).where(
            DemandeInscription.reference == reference,
            DemandeInscription.email == email,
        )
    )
    if demande is None:
        raise RessourceIntrouvable("Demande introuvable")
    return {
        "reference": demande.reference,
        "type_demande": demande.type_demande,
        "statut": demande.statut,
        "motif_rejet": demande.motif_rejet,
        "cree_le": demande.cree_le.isoformat() if demande.cree_le else None,
        "traite_le": demande.traite_le.isoformat() if demande.traite_le else None,
    }


def lister_demandes(session: Session, role_actif: str, statut: str | None = "en_attente") -> list[dict]:
    if role_actif not in {"appariteur", "doyen", "chef_promotion", "administrateur"}:
        raise AccesInterdit("Role insuffisant")
    requete = select(DemandeInscription)
    if statut:
        requete = requete.where(DemandeInscription.statut == statut)
    if role_actif == "doyen":
        requete = requete.where(DemandeInscription.type_demande == "enseignant")
    elif role_actif == "chef_promotion":
        requete = requete.where(DemandeInscription.type_demande == "etudiant")
    return [_serialiser_demande(demande, interne=True) for demande in session.scalars(requete.order_by(DemandeInscription.id.desc())).all()]


def obtenir_demande(session: Session, demande_id: int, role_actif: str) -> dict:
    demande = session.get(DemandeInscription, demande_id)
    if demande is None:
        raise RessourceIntrouvable("Demande introuvable")
    _verifier_autorisation(role_actif, None, demande)
    return _serialiser_demande(demande, interne=True)


def _verifier_autorisation(role_actif: str, utilisateur: Utilisateur | None, demande: DemandeInscription) -> None:
    if role_actif == "administrateur":
        return
    if demande.type_demande == "etudiant":
        if role_actif == "appariteur":
            return
        if role_actif == "chef_promotion" and utilisateur is not None:
            profil = getattr(utilisateur, "_profil_etudiant_cache", None)
            if profil is not None and profil.promotion_id == demande.promotion_id:
                return
        raise AccesInterdit("Role insuffisant pour traiter cette demande etudiant")
    if demande.type_demande == "enseignant" and role_actif in ROLES_APPROBATION_ENSEIGNANT:
        return
    raise AccesInterdit("Role insuffisant pour traiter cette demande")


def _charger_profil_etudiant(session: Session, utilisateur: Utilisateur) -> Etudiant | None:
    return session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur.id))


def approuver_demande(session: Session, demande_id: int, utilisateur: Utilisateur, role_actif: str) -> dict:
    demande = session.scalar(select(DemandeInscription).where(DemandeInscription.id == demande_id).with_for_update())
    if demande is None:
        raise RessourceIntrouvable("Demande introuvable")
    setattr(utilisateur, "_profil_etudiant_cache", _charger_profil_etudiant(session, utilisateur))
    _verifier_autorisation(role_actif, utilisateur, demande)
    if demande.statut != "en_attente":
        raise ConflitDonnees("Demande deja traitee")
    _verifier_doublons_approbation(session, demande)

    utilisateur_cree = Utilisateur(
        nom=demande.nom,
        postnom=demande.postnom,
        prenom=demande.prenom,
        email=demande.email,
        mot_de_passe_hash=demande.mot_de_passe_hash,
        telephone=demande.telephone,
        statut="actif",
    )
    session.add(utilisateur_cree)
    session.flush()
    _attribuer_role(session, utilisateur_cree, demande.type_demande, utilisateur.id)
    if demande.type_demande == "etudiant":
        session.add(
            Etudiant(
                utilisateur_id=utilisateur_cree.id,
                matricule=demande.matricule or "",
                promotion_id=demande.promotion_id or 0,
                date_inscription=maintenant_utc().date(),
                statut_academique="actif",
            )
        )
    else:
        session.add(
            Enseignant(
                utilisateur_id=utilisateur_cree.id,
                matricule_agent=demande.matricule_agent,
                grade=demande.grade,
                departement=demande.departement,
                statut="actif",
            )
        )
    demande.statut = "approuvee"
    demande.utilisateur_id = utilisateur_cree.id
    demande.traite_par_utilisateur_id = utilisateur.id
    demande.traite_le = maintenant_utc()
    try:
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Approbation impossible a cause d'un doublon") from exc
    session.refresh(demande)
    return _serialiser_demande(demande, interne=True)


def _verifier_doublons_approbation(session: Session, demande: DemandeInscription) -> None:
    if session.scalar(select(Utilisateur.id).where(Utilisateur.email == demande.email)) is not None:
        raise ConflitDonnees("Email deja utilise par un compte")
    if demande.type_demande == "etudiant":
        if session.scalar(select(Etudiant.id).where(Etudiant.matricule == demande.matricule)) is not None:
            raise ConflitDonnees("Matricule deja utilise")
    if demande.type_demande == "enseignant" and demande.matricule_agent:
        if session.scalar(select(Enseignant.id).where(Enseignant.matricule_agent == demande.matricule_agent)) is not None:
            raise ConflitDonnees("Matricule agent deja utilise")


def rejeter_demande(session: Session, demande_id: int, donnees: RejetDemandeInscription, utilisateur: Utilisateur, role_actif: str) -> dict:
    demande = session.scalar(select(DemandeInscription).where(DemandeInscription.id == demande_id).with_for_update())
    if demande is None:
        raise RessourceIntrouvable("Demande introuvable")
    setattr(utilisateur, "_profil_etudiant_cache", _charger_profil_etudiant(session, utilisateur))
    _verifier_autorisation(role_actif, utilisateur, demande)
    if demande.statut != "en_attente":
        raise ConflitDonnees("Demande deja traitee")
    demande.statut = "rejetee"
    demande.motif_rejet = donnees.motif
    demande.traite_par_utilisateur_id = utilisateur.id
    demande.traite_le = maintenant_utc()
    session.commit()
    session.refresh(demande)
    return _serialiser_demande(demande, interne=True)
