from __future__ import annotations

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, RessourceIntrouvable
from app.modeles.academique import Cours, CoursEnseignant, Etudiant, InscriptionCours
from app.modeles.audit import JournalAudit
from app.modeles.enrolements import EnrolementAcademique
from app.modeles.presences_academiques import PresenceAcademique, SeanceAcademique
from app.modeles.securite import Utilisateur
from app.schemas.presences_academiques import ControleAccesPresence, SeanceAcademiqueCreation


SEUIL_PAIEMENT = Decimal("50.00")


def _maintenant() -> datetime:
    return datetime.utcnow()


def _journaliser(session: Session, utilisateur_id: int, action: str, entite: str, entite_id: int, details: dict) -> None:
    session.add(
        JournalAudit(
            utilisateur_id=utilisateur_id,
            action=action,
            entite=entite,
            entite_id=entite_id,
            details_json=details,
        )
    )


def _nom(utilisateur: Utilisateur | None) -> str | None:
    if utilisateur is None:
        return None
    nom = " ".join(partie for partie in (utilisateur.prenom, utilisateur.nom) if partie)
    return nom or utilisateur.email


def _cours(session: Session, cours_id: int) -> Cours:
    cours = session.get(Cours, cours_id)
    if cours is None or not cours.est_actif:
        raise RessourceIntrouvable("Cours introuvable ou inactif")
    return cours


def _seance(session: Session, seance_id: int) -> SeanceAcademique:
    seance = session.get(SeanceAcademique, seance_id)
    if seance is None:
        raise RessourceIntrouvable("Seance academique introuvable")
    return seance


def _serialiser_presence(presence: PresenceAcademique) -> dict:
    etudiant = presence.etudiant
    utilisateur = etudiant.utilisateur if etudiant else None
    return {
        "id": presence.id,
        "seance_id": presence.seance_id,
        "etudiant_id": presence.etudiant_id,
        "etudiant": {
            "matricule": etudiant.matricule,
            "nom": _nom(utilisateur),
            "promotion_id": etudiant.promotion_id,
        }
        if etudiant
        else None,
        "statut": presence.statut,
        "methode_identification": presence.methode_identification,
        "motif_refus": presence.motif_refus,
        "pourcentage_paiement_observe": presence.pourcentage_paiement_observe,
        "heure_identification": presence.heure_identification,
        "heure_enregistrement": presence.heure_enregistrement,
    }


def _serialiser_seance(seance: SeanceAcademique) -> dict:
    cours = seance.cours
    return {
        "id": seance.id,
        "cours_id": seance.cours_id,
        "cours": {"id": cours.id, "code": cours.code, "intitule": cours.intitule} if cours else None,
        "promotion_id": seance.promotion_id,
        "enseignant_id": seance.enseignant_id,
        "annee_academique_id": seance.annee_academique_id,
        "semestre_id": seance.semestre_id,
        "date_seance": seance.date_seance,
        "heure_debut": seance.heure_debut,
        "heure_fin": seance.heure_fin,
        "type_cours": seance.type_cours,
        "statut": seance.statut,
        "ouverte_par_utilisateur_id": seance.ouverte_par_utilisateur_id,
        "date_ouverture": seance.date_ouverture,
        "date_fermeture": seance.date_fermeture,
        "confirme_cours_2": seance.confirme_cours_2_par_utilisateur_id is not None,
        "confirme_cours_2_par_utilisateur_id": seance.confirme_cours_2_par_utilisateur_id,
        "confirme_cours_2_le": seance.confirme_cours_2_le,
    }


def creer_seance(session: Session, utilisateur_id: int, donnees: SeanceAcademiqueCreation) -> dict:
    cours = _cours(session, donnees.cours_id)
    promotion = cours.promotion
    semestre = cours.semestre
    annee = semestre.annee_academique if semestre else None
    if promotion is None or not promotion.est_active or annee is None or not annee.est_active:
        raise AccesInterdit("Le cours, la promotion et l annee doivent etre actifs")
    if promotion.annee_academique_id != annee.id:
        raise ConflitDonnees("Le cours n est pas coherent avec sa promotion et son annee")
    if not (annee.date_debut <= donnees.date_seance <= annee.date_fin):
        raise ConflitDonnees("La date de la seance est hors de l annee academique")

    existe = session.scalar(
        select(SeanceAcademique).where(
            SeanceAcademique.cours_id == cours.id,
            SeanceAcademique.date_seance == donnees.date_seance,
            SeanceAcademique.type_cours == donnees.type_cours,
        )
    )
    if existe is not None:
        raise ConflitDonnees("Une seance identique existe deja pour ce cours et cette date")

    affectation = session.scalar(
        select(CoursEnseignant)
        .where(CoursEnseignant.cours_id == cours.id)
        .order_by(CoursEnseignant.est_responsable.desc(), CoursEnseignant.id)
    )
    enseignant_id = affectation.enseignant_id if affectation else None
    seance = SeanceAcademique(
        cours_id=cours.id,
        promotion_id=promotion.id,
        enseignant_id=enseignant_id,
        annee_academique_id=annee.id,
        semestre_id=semestre.id,
        date_seance=donnees.date_seance,
        heure_debut=donnees.heure_debut,
        heure_fin=donnees.heure_fin,
        type_cours=donnees.type_cours,
        statut="planifiee",
    )
    session.add(seance)
    session.flush()
    _journaliser(session, utilisateur_id, "creation_seance_academique", "seances_academiques", seance.id, {"cours_id": cours.id})
    session.commit()
    return _serialiser_seance(seance)


def lister_seances(session: Session, date_seance: date | None = None) -> list[dict]:
    requete = select(SeanceAcademique).order_by(SeanceAcademique.date_seance.desc(), SeanceAcademique.id.desc())
    if date_seance is not None:
        requete = requete.where(SeanceAcademique.date_seance == date_seance)
    return [_serialiser_seance(seance) for seance in session.scalars(requete).all()]


def lister_seances_chef(session: Session, utilisateur_id: int, date_seance: date | None = None) -> list[dict]:
    chef = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if chef is None or chef.statut_academique != "actif":
        raise AccesInterdit("Profil chef de promotion introuvable")
    requete = select(SeanceAcademique).where(SeanceAcademique.promotion_id == chef.promotion_id)
    if date_seance is not None:
        requete = requete.where(SeanceAcademique.date_seance == date_seance)
    requete = requete.order_by(SeanceAcademique.date_seance.desc(), SeanceAcademique.id.desc())
    return [_serialiser_seance(seance) for seance in session.scalars(requete).all()]


def lister_presences_chef(session: Session, utilisateur_id: int, seance_id: int) -> list[dict]:
    chef = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    seance = _seance(session, seance_id)
    if chef is None or chef.statut_academique != "actif" or chef.promotion_id != seance.promotion_id:
        raise AccesInterdit("Seance hors du perimetre de la promotion")
    return lister_presences(session, seance_id)


def obtenir_seance(session: Session, seance_id: int) -> dict:
    return _serialiser_seance(_seance(session, seance_id))


def ouvrir_seance(session: Session, utilisateur_id: int, seance_id: int) -> dict:
    seance = _seance(session, seance_id)
    if seance.statut == "ouverte":
        return _serialiser_seance(seance)
    if seance.statut != "planifiee":
        raise ConflitDonnees("Seule une seance planifiee peut etre ouverte")
    seance.statut = "ouverte"
    seance.ouverte_par_utilisateur_id = utilisateur_id
    seance.date_ouverture = _maintenant()
    _journaliser(session, utilisateur_id, "ouverture_seance_academique", "seances_academiques", seance.id, {})
    session.commit()
    return _serialiser_seance(seance)


def fermer_seance(session: Session, utilisateur_id: int, seance_id: int) -> dict:
    seance = _seance(session, seance_id)
    if seance.statut == "fermee":
        return _serialiser_seance(seance)
    if seance.statut != "ouverte":
        raise ConflitDonnees("Seule une seance ouverte peut etre fermee")
    seance.statut = "fermee"
    seance.fermee_par_utilisateur_id = utilisateur_id
    seance.date_fermeture = _maintenant()
    _journaliser(session, utilisateur_id, "fermeture_seance_academique", "seances_academiques", seance.id, {})
    session.commit()
    return _serialiser_seance(seance)


def lister_etudiants_seance(session: Session, seance_id: int) -> list[dict]:
    seance = _seance(session, seance_id)
    requete = (
        select(Etudiant, EnrolementAcademique)
        .join(
            EnrolementAcademique,
            (EnrolementAcademique.etudiant_id == Etudiant.id)
            & (EnrolementAcademique.annee_academique_id == seance.annee_academique_id)
            & (EnrolementAcademique.promotion_id == seance.promotion_id)
            & (EnrolementAcademique.statut == "valide"),
        )
        .join(
            InscriptionCours,
            (InscriptionCours.etudiant_id == Etudiant.id)
            & (InscriptionCours.cours_id == seance.cours_id)
            & (InscriptionCours.annee_academique_id == seance.annee_academique_id)
            & (InscriptionCours.statut.in_(["active", "validee"])),
        )
        .where(Etudiant.promotion_id == seance.promotion_id, Etudiant.statut_academique == "actif")
        .order_by(Etudiant.matricule)
    )
    return [
        {
            "id": etudiant.id,
            "matricule": etudiant.matricule,
            "nom": _nom(etudiant.utilisateur),
            "promotion_id": etudiant.promotion_id,
            "pourcentage_paiement": enrolement.pourcentage_paiement,
            "acces_financier": enrolement.pourcentage_paiement >= SEUIL_PAIEMENT,
        }
        for etudiant, enrolement in session.execute(requete).all()
    ]


def _refus(motif: str, seance: SeanceAcademique, etudiant: Etudiant | None = None, paiement: Decimal | None = None) -> dict:
    return {
        "acces_autorise": False,
        "motif": motif,
        "etudiant": {
            "id": etudiant.id,
            "matricule": etudiant.matricule,
            "nom": _nom(etudiant.utilisateur),
        }
        if etudiant
        else None,
        "seance": _serialiser_seance(seance),
        "presence": None,
        "pourcentage_paiement_utilise": paiement,
        "heure_decision": _maintenant(),
    }


def controler_acces(session: Session, utilisateur_id: int, seance_id: int, donnees: ControleAccesPresence) -> dict:
    seance = _seance(session, seance_id)
    etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == donnees.matricule.strip()))
    if etudiant is None:
        return _refus("etudiant_introuvable", seance)
    if seance.statut != "ouverte":
        return _refus("seance_fermee", seance, etudiant)
    if etudiant.statut_academique != "actif" or etudiant.utilisateur is None or etudiant.utilisateur.statut != "actif":
        return _refus("etudiant_inactif", seance, etudiant)
    if etudiant.promotion_id != seance.promotion_id:
        return _refus("mauvaise_promotion", seance, etudiant)

    enrolement = session.scalar(
        select(EnrolementAcademique).where(
            EnrolementAcademique.etudiant_id == etudiant.id,
            EnrolementAcademique.promotion_id == seance.promotion_id,
            EnrolementAcademique.annee_academique_id == seance.annee_academique_id,
            EnrolementAcademique.statut == "valide",
        )
    )
    if enrolement is None:
        return _refus("non_enrole", seance, etudiant)

    inscription = session.scalar(
        select(InscriptionCours.id).where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.cours_id == seance.cours_id,
            InscriptionCours.annee_academique_id == seance.annee_academique_id,
            InscriptionCours.statut.in_(["active", "validee"]),
        )
    )
    if inscription is None:
        return _refus("non_enrole", seance, etudiant, enrolement.pourcentage_paiement)

    paiement = Decimal(enrolement.pourcentage_paiement or 0).quantize(Decimal("0.01"))
    existante = session.scalar(
        select(PresenceAcademique).where(
            PresenceAcademique.seance_id == seance.id, PresenceAcademique.etudiant_id == etudiant.id
        )
    )
    if existante is not None:
        resultat = _refus("deja_enregistre", seance, etudiant, existante.pourcentage_paiement_observe)
        resultat["presence"] = _serialiser_presence(existante)
        resultat["acces_autorise"] = existante.statut in {"present", "retard"}
        return resultat

    motif = "autorise" if paiement >= SEUIL_PAIEMENT else "paiement_insuffisant"
    presence = PresenceAcademique(
        seance_id=seance.id,
        etudiant_id=etudiant.id,
        statut=donnees.statut if motif == "autorise" else "refuse",
        methode_identification="matricule",
        enregistre_par_utilisateur_id=utilisateur_id,
        motif_refus=None if motif == "autorise" else motif,
        pourcentage_paiement_observe=paiement,
    )
    session.add(presence)
    try:
        session.flush()
        _journaliser(
            session,
            utilisateur_id,
            "controle_acces_presence",
            "presences_academiques",
            presence.id,
            {"seance_id": seance.id, "motif": motif, "methode": "matricule"},
        )
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Presence deja enregistree pour cette seance") from exc

    return {
        "acces_autorise": motif == "autorise",
        "motif": motif,
        "etudiant": {"id": etudiant.id, "matricule": etudiant.matricule, "nom": _nom(etudiant.utilisateur)},
        "seance": _serialiser_seance(seance),
        "presence": _serialiser_presence(presence),
        "pourcentage_paiement_utilise": paiement,
        "heure_decision": presence.heure_enregistrement,
    }


def lister_presences(session: Session, seance_id: int) -> list[dict]:
    _seance(session, seance_id)
    return [
        _serialiser_presence(presence)
        for presence in session.scalars(
            select(PresenceAcademique)
            .where(PresenceAcademique.seance_id == seance_id)
            .order_by(PresenceAcademique.heure_enregistrement)
        ).all()
    ]


def confirmer_cours_2(session: Session, utilisateur_id: int, seance_id: int) -> dict:
    seance = _seance(session, seance_id)
    if seance.type_cours != "cours_2":
        raise ConflitDonnees("La confirmation est reservee au deuxieme cours")
    if seance.statut != "ouverte":
        raise ConflitDonnees("Une seance fermee ou annulee ne peut pas etre confirmee")
    chef = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if chef is None or chef.statut_academique != "actif" or chef.promotion_id != seance.promotion_id:
        raise AccesInterdit("Chef de promotion hors du perimetre de la seance")
    seance.confirme_cours_2_par_utilisateur_id = utilisateur_id
    seance.confirme_cours_2_le = _maintenant()
    _journaliser(session, utilisateur_id, "confirmation_cours_2", "seances_academiques", seance.id, {"promotion_id": seance.promotion_id})
    session.commit()
    return _serialiser_seance(seance)
