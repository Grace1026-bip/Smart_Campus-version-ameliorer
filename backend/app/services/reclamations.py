from __future__ import annotations

from datetime import datetime

from fastapi import status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import Cours, CoursEnseignant, Enseignant, Etudiant, InscriptionCours
from app.modeles.audit import JournalAudit
from app.modeles.notes import Evaluation, Note
from app.modeles.reclamations import HistoriqueReclamation, MessageReclamation, Reclamation
from app.modeles.securite import Role, Utilisateur, UtilisateurRole
from app.schemas.pagination import ParametresPagination, construire_page
from app.schemas.reclamations import MessageReclamationCreation, ReclamationCreation, TraitementReclamation
from app.services.notifications import creer_notification


STATUTS_FINAUX = {"resolue", "rejetee"}
ROLES_TRAITEMENT_GLOBAL = {"appariteur", "doyen", "administrateur"}


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


def _ids_cours_enseignant(session: Session, utilisateur_id: int) -> list[int]:
    enseignant = _enseignant_connecte(session, utilisateur_id)
    return list(
        session.scalars(
            select(CoursEnseignant.cours_id).where(CoursEnseignant.enseignant_id == enseignant.id)
        ).all()
    )


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


def _charger_reclamation(session: Session, reclamation_id: int) -> Reclamation:
    reclamation = session.scalar(
        select(Reclamation)
        .options(
            selectinload(Reclamation.messages).selectinload(MessageReclamation.auteur),
            selectinload(Reclamation.historiques).selectinload(HistoriqueReclamation.auteur_modification),
        )
        .where(Reclamation.id == reclamation_id)
    )
    if reclamation is None:
        raise RessourceIntrouvable("Reclamation introuvable")
    return reclamation


def _verifier_acces_etudiant(session: Session, utilisateur_id: int, reclamation: Reclamation) -> Etudiant:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    if reclamation.etudiant_id != etudiant.id:
        raise AccesInterdit("Reclamation non autorisee")
    return etudiant


def _verifier_acces_traitement(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    reclamation: Reclamation,
) -> None:
    if role_actif in ROLES_TRAITEMENT_GLOBAL:
        return
    if role_actif != "enseignant":
        raise AccesInterdit("Role insuffisant")
    ids_cours = _ids_cours_enseignant(session, utilisateur_id)
    if reclamation.assignee_a == utilisateur_id:
        return
    if reclamation.cours_id is not None and reclamation.cours_id in ids_cours:
        return
    raise AccesInterdit("Reclamation non autorisee pour cet enseignant")


def _utilisateurs_role(session: Session, role_nom: str) -> list[int]:
    return list(
        session.scalars(
            select(UtilisateurRole.utilisateur_id)
            .join(Role, UtilisateurRole.role_id == Role.id)
            .where(Role.nom == role_nom)
        ).all()
    )


def _enseignants_utilisateurs_du_cours(session: Session, cours_id: int) -> list[int]:
    return list(
        session.scalars(
            select(Enseignant.utilisateur_id)
            .join(CoursEnseignant, CoursEnseignant.enseignant_id == Enseignant.id)
            .where(CoursEnseignant.cours_id == cours_id)
        ).all()
    )


def _notifier_creation(session: Session, reclamation: Reclamation) -> None:
    destinataires = set(_utilisateurs_role(session, "appariteur"))
    if reclamation.cours_id is not None:
        destinataires.update(_enseignants_utilisateurs_du_cours(session, reclamation.cours_id))

    for utilisateur_id in destinataires:
        creer_notification(
            session,
            utilisateur_id,
            "reclamation_mise_a_jour",
            "Nouvelle reclamation academique",
            reclamation.objet,
            {"reclamation_id": reclamation.id, "cours_id": reclamation.cours_id},
        )


def _notifier_etudiant(session: Session, reclamation: Reclamation, titre: str, contenu: str) -> None:
    etudiant = session.get(Etudiant, reclamation.etudiant_id)
    if etudiant is None:
        return
    creer_notification(
        session,
        etudiant.utilisateur_id,
        "reclamation_mise_a_jour",
        titre,
        contenu,
        {"reclamation_id": reclamation.id, "statut": reclamation.statut},
    )


def _notifier_assignee(session: Session, reclamation: Reclamation, acteur_id: int) -> None:
    if reclamation.assignee_a is None or reclamation.assignee_a == acteur_id:
        return
    creer_notification(
        session,
        reclamation.assignee_a,
        "reclamation_mise_a_jour",
        "Reclamation assignee",
        reclamation.objet,
        {"reclamation_id": reclamation.id},
    )


def _serialiser_utilisateur(session: Session, utilisateur_id: int | None) -> dict | None:
    if utilisateur_id is None:
        return None
    utilisateur = session.get(Utilisateur, utilisateur_id)
    if utilisateur is None:
        return None
    return {"id": utilisateur.id, "nom": _nom_utilisateur(utilisateur), "email": utilisateur.email}


def _serialiser_etudiant(session: Session, etudiant_id: int) -> dict | None:
    etudiant = session.get(Etudiant, etudiant_id)
    if etudiant is None:
        return None
    utilisateur = session.get(Utilisateur, etudiant.utilisateur_id)
    return {
        "id": etudiant.id,
        "matricule": etudiant.matricule,
        "utilisateur_id": etudiant.utilisateur_id,
        "nom": _nom_utilisateur(utilisateur),
        "email": utilisateur.email if utilisateur else None,
        "promotion_id": etudiant.promotion_id,
    }


def _serialiser_cours(session: Session, cours_id: int | None) -> dict | None:
    if cours_id is None:
        return None
    cours = session.get(Cours, cours_id)
    if cours is None:
        return None
    return {"id": cours.id, "code": cours.code, "intitule": cours.intitule}


def _serialiser_message(message: MessageReclamation) -> dict:
    return {
        "id": message.id,
        "reclamation_id": message.reclamation_id,
        "auteur_id": message.auteur_id,
        "auteur": _nom_utilisateur(message.auteur),
        "message": message.message,
        "est_interne": message.est_interne,
        "cree_le": message.cree_le,
    }


def _serialiser_historique(historique: HistoriqueReclamation) -> dict:
    return {
        "id": historique.id,
        "ancien_statut": historique.ancien_statut,
        "nouveau_statut": historique.nouveau_statut,
        "modifie_par": historique.modifie_par,
        "auteur": _nom_utilisateur(historique.auteur_modification),
        "commentaire": historique.commentaire,
        "modifie_le": historique.modifie_le,
    }


def _serialiser_reclamation(
    session: Session,
    reclamation: Reclamation,
    detail: bool = False,
    inclure_messages_internes: bool = False,
) -> dict:
    donnees = {
        "id": reclamation.id,
        "etudiant_id": reclamation.etudiant_id,
        "etudiant": _serialiser_etudiant(session, reclamation.etudiant_id),
        "cours_id": reclamation.cours_id,
        "cours": _serialiser_cours(session, reclamation.cours_id),
        "note_id": reclamation.note_id,
        "categorie": reclamation.categorie,
        "objet": reclamation.objet,
        "description": reclamation.description,
        "statut": reclamation.statut,
        "priorite": reclamation.priorite,
        "assignee_a": reclamation.assignee_a,
        "assignee": _serialiser_utilisateur(session, reclamation.assignee_a),
        "cree_le": reclamation.cree_le,
        "modifie_le": reclamation.modifie_le,
        "resolue_le": reclamation.resolue_le,
    }
    if detail:
        messages = sorted(reclamation.messages, key=lambda message: message.cree_le)
        if not inclure_messages_internes:
            messages = [message for message in messages if not message.est_interne]
        donnees["messages"] = [_serialiser_message(message) for message in messages]
        donnees["historiques"] = [
            _serialiser_historique(historique)
            for historique in sorted(reclamation.historiques, key=lambda item: item.modifie_le)
        ]
    return donnees


def _appliquer_filtres(
    requete,
    recherche: str | None,
    statut_reclamation: str | None,
    categorie: str | None,
    cours_id: int | None,
    etudiant_id: int | None,
):
    if recherche:
        motif = f"%{recherche}%"
        requete = requete.where(or_(Reclamation.objet.like(motif), Reclamation.description.like(motif)))
    if statut_reclamation:
        requete = requete.where(Reclamation.statut == statut_reclamation)
    if categorie:
        requete = requete.where(Reclamation.categorie == categorie)
    if cours_id:
        requete = requete.where(Reclamation.cours_id == cours_id)
    if etudiant_id:
        requete = requete.where(Reclamation.etudiant_id == etudiant_id)
    return requete


def creer_reclamation(session: Session, utilisateur_id: int, donnees: ReclamationCreation) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    cours_id = donnees.cours_id

    if donnees.note_id is not None:
        ligne = session.execute(
            select(Note, Evaluation).join(Evaluation, Note.evaluation_id == Evaluation.id).where(Note.id == donnees.note_id)
        ).one_or_none()
        if ligne is None:
            raise RessourceIntrouvable("Note introuvable")
        note, evaluation = ligne
        if note.etudiant_id != etudiant.id or evaluation.statut != "publiee":
            raise AccesInterdit("Note non autorisee")
        if cours_id is not None and cours_id != evaluation.cours_id:
            raise ErreurApplication("Le cours ne correspond pas a la note", status.HTTP_400_BAD_REQUEST)
        cours_id = evaluation.cours_id

    if cours_id is not None:
        _verifier_etudiant_inscrit(session, etudiant.id, cours_id)

    reclamation = Reclamation(
        etudiant_id=etudiant.id,
        cours_id=cours_id,
        note_id=donnees.note_id,
        categorie=donnees.categorie,
        objet=donnees.objet,
        description=donnees.description,
        statut="en_attente",
        priorite=donnees.priorite,
    )
    session.add(reclamation)
    try:
        session.flush()
        session.add(
            HistoriqueReclamation(
                reclamation_id=reclamation.id,
                ancien_statut=None,
                nouveau_statut="en_attente",
                modifie_par=utilisateur_id,
                commentaire="Creation de la reclamation",
            )
        )
        _notifier_creation(session, reclamation)
        _journaliser(session, utilisateur_id, "creation_reclamation", "reclamations", reclamation.id)
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Reclamation impossible a creer") from exc

    return obtenir_reclamation_etudiant(session, utilisateur_id, reclamation.id)


def lister_reclamations_etudiant(session: Session, utilisateur_id: int, pagination: ParametresPagination) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    conditions = [Reclamation.etudiant_id == etudiant.id]
    requete = select(Reclamation).where(*conditions)
    total = session.scalar(select(func.count()).select_from(Reclamation).where(*conditions)) or 0
    reclamations = session.scalars(
        requete.order_by(Reclamation.modifie_le.desc()).offset(pagination.offset).limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_reclamation(session, reclamation) for reclamation in reclamations],
        total,
        pagination.page,
        pagination.taille,
    )


def obtenir_reclamation_etudiant(session: Session, utilisateur_id: int, reclamation_id: int) -> dict:
    reclamation = _charger_reclamation(session, reclamation_id)
    _verifier_acces_etudiant(session, utilisateur_id, reclamation)
    return _serialiser_reclamation(session, reclamation, detail=True, inclure_messages_internes=False)


def ajouter_message_etudiant(
    session: Session,
    utilisateur_id: int,
    reclamation_id: int,
    donnees: MessageReclamationCreation,
) -> dict:
    reclamation = _charger_reclamation(session, reclamation_id)
    _verifier_acces_etudiant(session, utilisateur_id, reclamation)
    if reclamation.statut in STATUTS_FINAUX:
        raise AccesInterdit("Une reclamation cloturee ne peut plus recevoir de message")

    message = MessageReclamation(
        reclamation_id=reclamation.id,
        auteur_id=utilisateur_id,
        message=donnees.message,
        est_interne=False,
    )
    session.add(message)
    _journaliser(session, utilisateur_id, "message_reclamation_etudiant", "reclamations", reclamation.id)
    session.commit()
    session.refresh(message)
    return _serialiser_message(message)


def lister_reclamations_traitement(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    pagination: ParametresPagination,
    statut_reclamation: str | None = None,
    categorie: str | None = None,
    cours_id: int | None = None,
    etudiant_id: int | None = None,
) -> dict:
    conditions = []
    if role_actif == "enseignant":
        ids_cours = _ids_cours_enseignant(session, utilisateur_id)
        conditions.append(or_(Reclamation.assignee_a == utilisateur_id, Reclamation.cours_id.in_(ids_cours)))
    elif role_actif not in ROLES_TRAITEMENT_GLOBAL:
        raise AccesInterdit("Role insuffisant")

    requete = select(Reclamation).where(*conditions)
    total_requete = select(func.count()).select_from(Reclamation).where(*conditions)
    requete = _appliquer_filtres(requete, pagination.recherche, statut_reclamation, categorie, cours_id, etudiant_id)
    total_requete = _appliquer_filtres(
        total_requete,
        pagination.recherche,
        statut_reclamation,
        categorie,
        cours_id,
        etudiant_id,
    )
    total = session.scalar(total_requete) or 0
    reclamations = session.scalars(
        requete.order_by(Reclamation.modifie_le.desc()).offset(pagination.offset).limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_reclamation(session, reclamation) for reclamation in reclamations],
        total,
        pagination.page,
        pagination.taille,
    )


def obtenir_reclamation_traitement(session: Session, utilisateur_id: int, role_actif: str, reclamation_id: int) -> dict:
    reclamation = _charger_reclamation(session, reclamation_id)
    _verifier_acces_traitement(session, utilisateur_id, role_actif, reclamation)
    return _serialiser_reclamation(session, reclamation, detail=True, inclure_messages_internes=True)


def ajouter_message_traitement(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    reclamation_id: int,
    donnees: MessageReclamationCreation,
) -> dict:
    reclamation = _charger_reclamation(session, reclamation_id)
    _verifier_acces_traitement(session, utilisateur_id, role_actif, reclamation)
    if reclamation.statut in STATUTS_FINAUX and not donnees.est_interne:
        raise AccesInterdit("Une reclamation cloturee ne peut plus recevoir de message public")

    message = MessageReclamation(
        reclamation_id=reclamation.id,
        auteur_id=utilisateur_id,
        message=donnees.message,
        est_interne=donnees.est_interne,
    )
    session.add(message)
    if not donnees.est_interne:
        _notifier_etudiant(session, reclamation, "Reponse a votre reclamation", donnees.message)
    _journaliser(session, utilisateur_id, "message_reclamation_traitement", "reclamations", reclamation.id)
    session.commit()
    session.refresh(message)
    return _serialiser_message(message)


def traiter_reclamation(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    reclamation_id: int,
    donnees: TraitementReclamation,
) -> dict:
    reclamation = _charger_reclamation(session, reclamation_id)
    _verifier_acces_traitement(session, utilisateur_id, role_actif, reclamation)
    ancien_statut = reclamation.statut

    if donnees.assignee_a is not None and session.get(Utilisateur, donnees.assignee_a) is None:
        raise RessourceIntrouvable("Utilisateur assigne introuvable")

    if donnees.priorite is not None:
        reclamation.priorite = donnees.priorite
    if donnees.assignee_a is not None:
        reclamation.assignee_a = donnees.assignee_a
    if donnees.statut is not None:
        reclamation.statut = donnees.statut
        reclamation.resolue_le = _maintenant() if donnees.statut in STATUTS_FINAUX else None

    try:
        if donnees.statut is not None and donnees.statut != ancien_statut:
            session.add(
                HistoriqueReclamation(
                    reclamation_id=reclamation.id,
                    ancien_statut=ancien_statut,
                    nouveau_statut=donnees.statut,
                    modifie_par=utilisateur_id,
                    commentaire=donnees.commentaire,
                )
            )
            _notifier_etudiant(
                session,
                reclamation,
                "Statut de reclamation mis a jour",
                f"Votre reclamation est maintenant: {donnees.statut}",
            )

        if donnees.reponse_etudiant:
            session.add(
                MessageReclamation(
                    reclamation_id=reclamation.id,
                    auteur_id=utilisateur_id,
                    message=donnees.reponse_etudiant,
                    est_interne=False,
                )
            )
            _notifier_etudiant(session, reclamation, "Reponse a votre reclamation", donnees.reponse_etudiant)

        _notifier_assignee(session, reclamation, utilisateur_id)
        _journaliser(
            session,
            utilisateur_id,
            "traitement_reclamation",
            "reclamations",
            reclamation.id,
            donnees.model_dump(exclude_none=True),
        )
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Reclamation impossible a traiter") from exc

    return obtenir_reclamation_traitement(session, utilisateur_id, role_actif, reclamation.id)
