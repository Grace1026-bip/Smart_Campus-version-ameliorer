from __future__ import annotations

from datetime import datetime
from decimal import Decimal

from sqlalchemy import func, select
from sqlalchemy.orm import Session, selectinload

from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Cours, Etudiant, Promotion, Semestre
from app.modeles.audit import JournalAudit
from app.modeles.deliberations import DecisionJury, MembreJury, ResultatSemestrielOfficiel, SessionDeliberation
from app.modeles.securite import Utilisateur
from app.services import resultats_academiques
from app.services.notifications import creer_notification


ROLES_ORGANISATION = {"doyen", "vice_doyen"}
ROLES_PUBLICATION = {"appariteur", "doyen", "vice_doyen"}
ROLES_CONSULTATION = ROLES_PUBLICATION | {"administrateur"}
DECISIONS = {"ADM", "COMP", "DEF", "AJ"}


def _maintenant() -> datetime:
    return datetime.utcnow()


def _exiger_role(role_actif: str, roles: set[str]) -> None:
    if role_actif not in roles:
        raise AccesInterdit("Role non autorise pour cette operation de deliberation")


def _obtenir_session(session: Session, session_id: int, verrouiller: bool = False) -> SessionDeliberation:
    requete = (
        select(SessionDeliberation)
        .options(selectinload(SessionDeliberation.membres), selectinload(SessionDeliberation.decisions), selectinload(SessionDeliberation.snapshots))
        .where(SessionDeliberation.id == session_id)
        .execution_options(populate_existing=True)
    )
    if verrouiller:
        requete = requete.with_for_update()
    objet = session.scalar(requete)
    if objet is None:
        raise RessourceIntrouvable("Session de deliberation introuvable")
    return objet


def _journaliser(session: Session, utilisateur_id: int, action: str, entite: str, entite_id: int | None, details: dict | None = None) -> None:
    session.add(JournalAudit(utilisateur_id=utilisateur_id, action=action, entite=entite, entite_id=entite_id, details_json=details))


def _serialiser_session(objet: SessionDeliberation) -> dict:
    return {
        "id": objet.id,
        "promotion_id": objet.promotion_id,
        "annee_academique_id": objet.annee_academique_id,
        "semestre_id": objet.semestre_id,
        "statut": objet.statut,
        "cree_par_utilisateur_id": objet.cree_par_utilisateur_id,
        "president_utilisateur_id": objet.president_utilisateur_id,
        "date_ouverture": objet.date_ouverture,
        "date_cloture": objet.date_cloture,
        "version": objet.version,
        "motif_reouverture": objet.motif_reouverture,
        "membres": [
            {
                "id": membre.id,
                "utilisateur_id": membre.utilisateur_id,
                "qualite": membre.qualite,
                "present": membre.present,
            }
            for membre in objet.membres
        ],
        "decisions_enregistrees": len(objet.decisions),
        "snapshots": len(objet.snapshots),
    }


def creer_session(session: Session, utilisateur_id: int, role_actif: str, promotion_id: int, annee_academique_id: int, semestre_id: int) -> dict:
    _exiger_role(role_actif, ROLES_ORGANISATION)
    promotion = session.scalar(select(Promotion).where(Promotion.id == promotion_id))
    annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.id == annee_academique_id))
    semestre = session.scalar(select(Semestre).where(Semestre.id == semestre_id))
    if promotion is None or annee is None or semestre is None:
        raise RessourceIntrouvable("Promotion, annee ou semestre introuvable")
    if promotion.annee_academique_id != annee.id or semestre.annee_academique_id != annee.id:
        raise ErreurApplication("Le perimetre academique de la session est incoherent")
    derniere_version = session.scalar(
        select(func.max(SessionDeliberation.version)).where(
            SessionDeliberation.promotion_id == promotion_id,
            SessionDeliberation.annee_academique_id == annee_academique_id,
            SessionDeliberation.semestre_id == semestre_id,
        )
    ) or 0
    derniere = session.scalar(
        select(SessionDeliberation).where(
            SessionDeliberation.promotion_id == promotion_id,
            SessionDeliberation.annee_academique_id == annee_academique_id,
            SessionDeliberation.semestre_id == semestre_id,
            SessionDeliberation.version == derniere_version,
        )
    ) if derniere_version else None
    if derniere is not None and derniere.statut not in {"annulee"}:
        raise ConflitDonnees("Une session active existe deja pour ce perimetre")
    objet = SessionDeliberation(
        promotion_id=promotion_id,
        annee_academique_id=annee_academique_id,
        semestre_id=semestre_id,
        cree_par_utilisateur_id=utilisateur_id,
        version=derniere_version + 1,
        statut="preparation",
    )
    session.add(objet)
    session.flush()
    _journaliser(session, utilisateur_id, "session_deliberation_creee", "SessionDeliberation", objet.id, {"version": objet.version})
    session.commit()
    session.refresh(objet)
    return _serialiser_session(objet)


def lister_sessions(session: Session, role_actif: str, utilisateur_id: int | None = None) -> list[dict]:
    if role_actif not in ROLES_CONSULTATION and utilisateur_id is None:
        raise AccesInterdit("Role non autorise pour la liste des deliberations")
    objets = session.scalars(select(SessionDeliberation).options(selectinload(SessionDeliberation.membres)).order_by(SessionDeliberation.cree_le.desc())).all()
    if role_actif not in ROLES_CONSULTATION:
        objets = [objet for objet in objets if any(membre.utilisateur_id == utilisateur_id for membre in objet.membres)]
    return [_serialiser_session(objet) for objet in objets]


def obtenir_session(session: Session, session_id: int, role_actif: str, utilisateur_id: int | None = None) -> dict:
    objet = _obtenir_session(session, session_id)
    if role_actif not in ROLES_CONSULTATION:
        if utilisateur_id is None or not any(membre.utilisateur_id == utilisateur_id for membre in objet.membres):
            raise AccesInterdit("Utilisateur non membre de cette deliberation")
    return _serialiser_session(objet)


def ajouter_membre(session: Session, session_id: int, utilisateur_id: int, role_actif: str, membre_utilisateur_id: int, qualite: str, present: bool = True) -> dict:
    _exiger_role(role_actif, ROLES_ORGANISATION)
    if qualite not in {"president", "membre", "secretaire"}:
        raise ErreurApplication("Qualite de jury invalide")
    objet = _obtenir_session(session, session_id, verrouiller=True)
    if objet.statut != "preparation":
        raise ConflitDonnees("Les membres ne peuvent etre modifies qu'en preparation")
    membre_utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.id == membre_utilisateur_id))
    if membre_utilisateur is None or membre_utilisateur.statut != "actif":
        raise AccesInterdit("Le membre du jury doit etre un compte actif")
    if qualite in {"president", "membre"}:
        from app.modeles.academique import Enseignant
        enseignant = session.scalar(select(Enseignant).where(Enseignant.utilisateur_id == membre_utilisateur_id, Enseignant.statut == "actif"))
        if enseignant is None:
            raise AccesInterdit("Le president et les membres enseignants doivent avoir un profil enseignant actif")
    existant = session.scalar(select(MembreJury).where(MembreJury.session_id == session_id, MembreJury.utilisateur_id == membre_utilisateur_id))
    if existant is None:
        existant = MembreJury(session_id=session_id, utilisateur_id=membre_utilisateur_id, qualite=qualite, present=present)
        session.add(existant)
    else:
        existant.qualite = qualite
        existant.present = present
    if qualite == "president":
        for autre in objet.membres:
            if autre.utilisateur_id != membre_utilisateur_id and autre.qualite == "president":
                autre.qualite = "membre"
        objet.president_utilisateur_id = membre_utilisateur_id
    session.flush()
    _journaliser(session, utilisateur_id, "membre_jury_ajoute", "SessionDeliberation", session_id, {"membre_utilisateur_id": membre_utilisateur_id, "qualite": qualite})
    session.commit()
    return _serialiser_session(_obtenir_session(session, session_id))


def ouvrir_session(session: Session, session_id: int, utilisateur_id: int, role_actif: str) -> dict:
    _exiger_role(role_actif, ROLES_ORGANISATION)
    objet = _obtenir_session(session, session_id, verrouiller=True)
    if objet.statut == "ouverte":
        return _serialiser_session(objet)
    if objet.statut != "preparation":
        raise ConflitDonnees("La session n'est pas en preparation")
    president = next((membre for membre in objet.membres if membre.qualite == "president" and membre.present), None)
    if president is None or objet.president_utilisateur_id is None:
        raise ErreurApplication("Un president present doit etre designe avant l'ouverture")
    if not any(membre.present for membre in objet.membres):
        raise ErreurApplication("Le jury doit avoir au moins un membre present")
    objet.statut = "ouverte"
    objet.date_ouverture = _maintenant()
    _journaliser(session, utilisateur_id, "session_deliberation_ouverte", "SessionDeliberation", session_id)
    session.commit()
    return _serialiser_session(_obtenir_session(session, session_id))


def _verifier_acces_consultation(session: SessionDeliberation, utilisateur_id: int, role_actif: str) -> None:
    if role_actif in ROLES_CONSULTATION:
        return
    if any(membre.utilisateur_id == utilisateur_id for membre in session.membres):
        return
    raise AccesInterdit("Utilisateur non membre de cette deliberation")


def _grille_ligne(session: Session, objet: SessionDeliberation, etudiant: Etudiant) -> dict:
    apercu = resultats_academiques.consolider_semestre(session, etudiant.id, objet.semestre_id)
    anomalies = list(apercu["raisons_incompletude"])
    if apercu["credits_prevus"] != 30:
        anomalies.append("credits_semestre_incoherents")
    decision_enregistree = next((decision for decision in objet.decisions if decision.etudiant_id == etudiant.id), None)
    return {
        "etudiant": apercu["etudiant"],
        "moyenne_ponderee_sur_20": apercu["moyenne_ponderee_sur_20"],
        "credits_prevus": apercu["credits_prevus"],
        "credits_capitalises": apercu["credits_acquis"],
        "credits_non_capitalises": apercu["credits_non_acquis"],
        "cours": apercu["cours"],
        "cours_non_acquis": [cours for cours in apercu["cours"] if cours["statut_validation"] == "non_acquis"],
        "notes_manquantes": anomalies,
        "complet": apercu["etat"] == "provisoire" and not anomalies,
        "proposition_decision": "DEF" if anomalies else apercu["proposition_decision"],
        "decision_enregistree": decision_enregistree.decision if decision_enregistree else None,
    }


def obtenir_grille(session: Session, session_id: int, utilisateur_id: int, role_actif: str) -> dict:
    objet = _obtenir_session(session, session_id)
    _verifier_acces_consultation(objet, utilisateur_id, role_actif)
    etudiants = session.scalars(select(Etudiant).where(Etudiant.promotion_id == objet.promotion_id, Etudiant.statut_academique == "actif").order_by(Etudiant.matricule)).all()
    return {"session": _serialiser_session(objet), "etudiants": [_grille_ligne(session, objet, etudiant) for etudiant in etudiants]}


def _ligne_pour_decision(session: Session, objet: SessionDeliberation, etudiant_id: int) -> dict:
    etudiant = session.scalar(select(Etudiant).where(Etudiant.id == etudiant_id, Etudiant.promotion_id == objet.promotion_id))
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant hors du perimetre de la session")
    return _grille_ligne(session, objet, etudiant)


def enregistrer_decision(session: Session, session_id: int, etudiant_id: int, utilisateur_id: int, decision: str, motif: str | None = None) -> dict:
    objet = _obtenir_session(session, session_id, verrouiller=True)
    membre = session.scalar(select(MembreJury).where(MembreJury.session_id == session_id, MembreJury.utilisateur_id == utilisateur_id, MembreJury.qualite == "president", MembreJury.present.is_(True)))
    if membre is None:
        raise AccesInterdit("Seul le president present du jury peut enregistrer une decision")
    if objet.statut != "ouverte":
        raise ConflitDonnees("La decision ne peut etre enregistree que dans une session ouverte")
    if decision not in DECISIONS:
        raise ErreurApplication("Decision de jury invalide")
    ligne = _ligne_pour_decision(session, objet, etudiant_id)
    proposition = ligne["proposition_decision"]
    if decision != proposition:
        raise ErreurApplication("La decision choisie est incompatible avec la grille calculee")
    existante = session.scalar(select(DecisionJury).where(DecisionJury.session_id == session_id, DecisionJury.etudiant_id == etudiant_id))
    if existante is None:
        existante = DecisionJury(session_id=session_id, etudiant_id=etudiant_id, decision=decision, motif=motif, enregistre_par_utilisateur_id=utilisateur_id)
        session.add(existante)
    else:
        existante.decision = decision
        existante.motif = motif
        existante.enregistre_par_utilisateur_id = utilisateur_id
    _journaliser(session, utilisateur_id, "decision_jury_enregistree", "DecisionJury", existante.id, {"session_id": session_id, "etudiant_id": etudiant_id, "decision": decision})
    session.commit()
    return {"etudiant_id": etudiant_id, "decision": decision, "proposition_decision": proposition}


def cloturer_session(session: Session, session_id: int, utilisateur_id: int) -> dict:
    objet = _obtenir_session(session, session_id, verrouiller=True)
    membre = session.scalar(select(MembreJury).where(MembreJury.session_id == session_id, MembreJury.utilisateur_id == utilisateur_id, MembreJury.qualite == "president", MembreJury.present.is_(True)))
    if membre is None:
        raise AccesInterdit("Seul le president present peut cloturer le jury")
    if objet.statut == "cloturee" or objet.statut == "publiee":
        return _serialiser_session(objet)
    if objet.statut != "ouverte":
        raise ConflitDonnees("La session doit etre ouverte avant sa cloture")
    etudiants = session.scalars(select(Etudiant).where(Etudiant.promotion_id == objet.promotion_id, Etudiant.statut_academique == "actif")).all()
    decisions = {decision.etudiant_id: decision for decision in objet.decisions}
    lignes = [_grille_ligne(session, objet, etudiant) for etudiant in etudiants]
    if any(etudiant.id not in decisions for etudiant in etudiants):
        raise ErreurApplication("Tous les etudiants du perimetre doivent avoir une decision")
    if any(decisions[etudiant.id].decision != ligne["proposition_decision"] for etudiant, ligne in zip(etudiants, lignes)):
        raise ErreurApplication("Une decision enregistree est devenue incoherente")
    if any(ligne["credits_prevus"] != 30 for ligne in lignes):
        raise ErreurApplication("Un semestre normal doit representer 30 credits")
    try:
        for etudiant, ligne in zip(etudiants, lignes):
            snapshot = ResultatSemestrielOfficiel(
                session_id=session_id,
                etudiant_id=etudiant.id,
                annee_academique_id=objet.annee_academique_id,
                semestre_id=objet.semestre_id,
                moyenne_ponderee=ligne["moyenne_ponderee_sur_20"] or Decimal("0"),
                credits_prevus=ligne["credits_prevus"],
                credits_capitalises=ligne["credits_capitalises"],
                credits_non_capitalises=ligne["credits_non_capitalises"],
                decision=decisions[etudiant.id].decision,
                statut_publication="non_publie",
                formule_version=resultats_academiques.FORMULE_LMD_VERSION,
                valide_par_jury=True,
                president_jury_id=objet.president_utilisateur_id,
                date_validation=_maintenant(),
                version=objet.version,
                est_actif=True,
            )
            session.add(snapshot)
        objet.statut = "cloturee"
        objet.date_cloture = _maintenant()
        _journaliser(session, utilisateur_id, "session_deliberation_cloturee", "SessionDeliberation", session_id, {"snapshots": len(etudiants)})
        session.commit()
    except Exception:
        session.rollback()
        raise
    return _serialiser_session(_obtenir_session(session, session_id))


def publier_session(session: Session, session_id: int, utilisateur_id: int, role_actif: str) -> dict:
    _exiger_role(role_actif, ROLES_PUBLICATION)
    objet = _obtenir_session(session, session_id, verrouiller=True)
    if objet.statut == "publiee":
        return _serialiser_session(objet)
    if objet.statut != "cloturee":
        raise ConflitDonnees("Seule une session cloturee peut etre publiee")
    if not objet.snapshots or any(not snapshot.valide_par_jury for snapshot in objet.snapshots):
        raise ErreurApplication("Les snapshots du jury sont incomplets")
    moment = _maintenant()
    try:
        etudiant_ids = [snapshot.etudiant_id for snapshot in objet.snapshots]
        anciens = session.scalars(
            select(ResultatSemestrielOfficiel).where(
                ResultatSemestrielOfficiel.etudiant_id.in_(etudiant_ids),
                ResultatSemestrielOfficiel.annee_academique_id == objet.annee_academique_id,
                ResultatSemestrielOfficiel.semestre_id == objet.semestre_id,
                ResultatSemestrielOfficiel.version < objet.version,
                ResultatSemestrielOfficiel.est_actif.is_(True),
            )
        ).all()
        for ancien in anciens:
            ancien.est_actif = False
            ancien.statut_publication = "remplace"
        for snapshot in objet.snapshots:
            snapshot.statut_publication = "publie"
            snapshot.date_publication = moment
            snapshot.publie_par_utilisateur_id = utilisateur_id
            snapshot.est_actif = True
            creer_notification(session, snapshot.etudiant.utilisateur_id, "information_systeme", "Resultats du semestre disponibles", "Votre resultat officiel est publie.", {"semestre_id": objet.semestre_id, "decision": snapshot.decision})
        objet.statut = "publiee"
        _journaliser(session, utilisateur_id, "session_deliberation_publiee", "SessionDeliberation", session_id)
        session.commit()
    except Exception:
        session.rollback()
        raise
    return _serialiser_session(_obtenir_session(session, session_id))


def demander_reouverture(session: Session, session_id: int, utilisateur_id: int, role_actif: str, motif: str) -> dict:
    _exiger_role(role_actif, ROLES_ORGANISATION)
    motif = motif.strip()
    if not motif:
        raise ErreurApplication("Le motif de reouverture est obligatoire")
    ancienne = _obtenir_session(session, session_id, verrouiller=True)
    if ancienne.statut not in {"cloturee", "publiee"}:
        raise ConflitDonnees("Seule une session cloturee ou publiee peut etre reouverte")
    derniere_version = session.scalar(select(func.max(SessionDeliberation.version)).where(SessionDeliberation.promotion_id == ancienne.promotion_id, SessionDeliberation.annee_academique_id == ancienne.annee_academique_id, SessionDeliberation.semestre_id == ancienne.semestre_id)) or ancienne.version
    nouvelle = SessionDeliberation(promotion_id=ancienne.promotion_id, annee_academique_id=ancienne.annee_academique_id, semestre_id=ancienne.semestre_id, cree_par_utilisateur_id=utilisateur_id, version=derniere_version + 1, statut="preparation", motif_reouverture=motif)
    session.add(nouvelle)
    ancienne.motif_reouverture = motif
    session.flush()
    _journaliser(session, utilisateur_id, "reouverture_deliberation_demandee", "SessionDeliberation", nouvelle.id, {"ancienne_session_id": session_id, "motif": motif})
    session.commit()
    return _serialiser_session(_obtenir_session(session, nouvelle.id))


def resultats_officiels_etudiant(session: Session, utilisateur_id: int, semestre_id: int) -> dict:
    from app.modeles.academique import Etudiant
    etudiant = session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur_id))
    if etudiant is None:
        raise AccesInterdit("Profil etudiant introuvable")
    snapshots = session.scalars(
        select(ResultatSemestrielOfficiel)
        .options(selectinload(ResultatSemestrielOfficiel.session))
        .where(ResultatSemestrielOfficiel.etudiant_id == etudiant.id, ResultatSemestrielOfficiel.semestre_id == semestre_id, ResultatSemestrielOfficiel.est_actif.is_(True), ResultatSemestrielOfficiel.statut_publication == "publie")
        .order_by(ResultatSemestrielOfficiel.version.desc())
    ).all()
    return {
        "resultats": [
            {
                "id": snapshot.id,
                "semestre_id": snapshot.semestre_id,
                "moyenne_ponderee_sur_20": snapshot.moyenne_ponderee,
                "credits_prevus": snapshot.credits_prevus,
                "credits_capitalises": snapshot.credits_capitalises,
                "credits_non_capitalises": snapshot.credits_non_capitalises,
                "decision": snapshot.decision,
                "date_publication": snapshot.date_publication,
                "version": snapshot.version,
                "mention": "Resultat officiel publie",
            }
            for snapshot in snapshots
        ]
    }
