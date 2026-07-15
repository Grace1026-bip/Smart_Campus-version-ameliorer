from __future__ import annotations

import hashlib
import struct
from datetime import datetime
from typing import Iterable, Sequence

from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.configuration.parametres import obtenir_parametres
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, MoteurBiometriqueIndisponible, RessourceIntrouvable
from app.modeles import AnneeAcademique, EncodageFacial, EnrolementAcademique, Etudiant, ProfilBiometrique
from app.modeles.audit import JournalAudit
from app.services.moteur_faciale import AnalyseVisage, MoteurFaceRecognition, MoteurReconnaissanceFaciale, distance_euclidienne, valider_image_dimensions
from app.schemas.presences_academiques import ControleAccesPresence


MIME_AUTORISES = {"image/jpeg", "image/png"}
MIN_CAPTURES = 3
MAX_CAPTURES = 5
FORMAT_ENCODAGE = "float32-le"


def obtenir_moteur() -> MoteurReconnaissanceFaciale:
    return MoteurFaceRecognition()


def _maintenant() -> datetime:
    return datetime.utcnow()


def _encoder_valeurs(valeurs: Sequence[float]) -> bytes:
    return b"".join(struct.pack("<f", float(valeur)) for valeur in valeurs)


def _decoder_valeurs(encodage: EncodageFacial) -> tuple[float, ...]:
    attendu = encodage.dimension * 4
    if encodage.format != FORMAT_ENCODAGE or len(encodage.encodage_binaire) != attendu:
        raise ValueError("Format d encodage facial invalide")
    return tuple(struct.unpack(f"<{encodage.dimension}f", encodage.encodage_binaire))


def _verifier_moteur(moteur: MoteurReconnaissanceFaciale | None) -> MoteurReconnaissanceFaciale:
    return moteur or obtenir_moteur()


def _verifier_image(image: bytes, content_type: str | None) -> None:
    parametres = obtenir_parametres()
    if not image:
        raise ValueError("Le fichier image est vide")
    if content_type not in MIME_AUTORISES:
        raise ValueError("Le format image doit etre JPEG ou PNG")
    if len(image) > parametres.biometrie_taille_max_image_mb * 1024 * 1024:
        raise ValueError("Le fichier image depasse la taille maximale autorisee")
    valider_image_dimensions(image, parametres.biometrie_dimension_minimale)


def _verifier_captures(captures: list[tuple[bytes, str | None]]) -> None:
    if not MIN_CAPTURES <= len(captures) <= MAX_CAPTURES:
        raise ValueError("Le nombre de captures doit etre compris entre 3 et 5")
    for image, content_type in captures:
        _verifier_image(image, content_type)


def _serialiser_profil(profil: ProfilBiometrique) -> dict:
    return {
        "id": profil.id,
        "etudiant_id": profil.etudiant_id,
        "statut": profil.statut,
        "version_moteur": profil.version_moteur,
        "seuil_utilise": profil.seuil_utilise,
        "consentement_enregistre": profil.consentement_enregistre,
        "date_consentement": profil.date_consentement,
        "date_creation": profil.date_creation,
        "date_revocation": profil.date_revocation,
        "motif_revocation": profil.motif_revocation,
        "nombre_encodages": len(profil.encodages),
    }


def _etudiant_eligible(session: Session, etudiant_id: int) -> Etudiant:
    etudiant = session.get(Etudiant, etudiant_id)
    if etudiant is None or etudiant.statut_academique != "actif" or etudiant.utilisateur is None:
        raise RessourceIntrouvable("Etudiant introuvable ou inactif")
    if etudiant.utilisateur.statut != "actif" or not etudiant.promotion or not etudiant.promotion.est_active:
        raise AccesInterdit("Etudiant non eligible a l enrôlement biometrique")
    enr = session.scalar(
        select(EnrolementAcademique).where(
            EnrolementAcademique.etudiant_id == etudiant.id,
            EnrolementAcademique.promotion_id == etudiant.promotion_id,
            EnrolementAcademique.annee_academique_id == select(AnneeAcademique.id).where(AnneeAcademique.est_active.is_(True)).scalar_subquery(),
            EnrolementAcademique.statut == "valide",
        )
    )
    if enr is None:
        raise AccesInterdit("L etudiant doit posseder un enrolement academique valide")
    return etudiant


def obtenir_profil(session: Session, etudiant_id: int) -> dict:
    profils = session.scalars(
        select(ProfilBiometrique)
        .options(selectinload(ProfilBiometrique.encodages))
        .where(ProfilBiometrique.etudiant_id == etudiant_id)
        .order_by(ProfilBiometrique.id.desc())
    ).all()
    if not profils:
        raise RessourceIntrouvable("Aucun profil biometrique pour cet etudiant")
    return {"profils": [_serialiser_profil(profil) for profil in profils]}


def _profils_actifs_autres(session: Session, etudiant_id: int) -> list[ProfilBiometrique]:
    return list(
        session.scalars(
            select(ProfilBiometrique)
            .options(selectinload(ProfilBiometrique.encodages))
            .where(ProfilBiometrique.statut == "actif", ProfilBiometrique.etudiant_id != etudiant_id)
        ).all()
    )


def _verifier_coherence(encodages: list[AnalyseVisage], seuil: float) -> None:
    if len({len(item.encodage) for item in encodages}) != 1:
        raise ValueError("Les dimensions des captures ne sont pas coherentes")
    for index, gauche in enumerate(encodages):
        for droite in encodages[index + 1 :]:
            if distance_euclidienne(gauche.encodage, droite.encodage) > seuil:
                raise ValueError("Les captures ne semblent pas appartenir a la meme personne")


def enroler(
    session: Session,
    utilisateur_id: int,
    etudiant_id: int,
    captures: list[tuple[bytes, str | None]],
    consentement: bool,
    reenrollement: bool = False,
    motif: str | None = None,
    moteur: MoteurReconnaissanceFaciale | None = None,
) -> dict:
    if not consentement:
        raise ConflitDonnees("Le consentement biometrique est obligatoire")
    if reenrollement and (not motif or len(motif.strip()) < 3):
        raise ConflitDonnees("Un motif est obligatoire pour un reenrollement")
    etudiant = _etudiant_eligible(session, etudiant_id)
    try:
        _verifier_captures(captures)
    except ValueError as exc:
        raise ConflitDonnees(str(exc)) from exc
    moteur = _verifier_moteur(moteur)
    analyses: list[AnalyseVisage] = []
    try:
        analyses = [moteur.analyser(image) for image, _ in captures]
    except ValueError as exc:
        raise ConflitDonnees(str(exc)) from exc
    finally:
        for index in range(len(captures)):
            captures[index] = (b"", None)
    if any(not analyse.encodage for analyse in analyses):
        raise ValueError("Un encodage facial est vide")
    seuil = obtenir_parametres().biometrie_seuil_distance
    _verifier_coherence(analyses, seuil)
    for profil_autre in _profils_actifs_autres(session, etudiant.id):
        for encodage in profil_autre.encodages:
            if any(distance_euclidienne(analyse.encodage, _decoder_valeurs(encodage)) < seuil for analyse in analyses):
                raise ConflitDonnees("Le visage est deja associe a un autre etudiant")

    profil_actif = session.scalar(
        select(ProfilBiometrique).where(ProfilBiometrique.etudiant_id == etudiant.id, ProfilBiometrique.statut == "actif")
    )
    if profil_actif is not None and not reenrollement:
        raise ConflitDonnees("Un profil biometrique actif existe deja")
    if profil_actif is not None:
        profil_actif.statut = "revoque"
        profil_actif.date_revocation = _maintenant()
        profil_actif.motif_revocation = motif.strip() if motif else "Reenrollement administratif"
        profil_actif.cle_profil_actif = None

    profil = ProfilBiometrique(
        etudiant_id=etudiant.id,
        statut="actif",
        version_moteur=moteur.version,
        seuil_utilise=seuil,
        consentement_enregistre=True,
        date_consentement=_maintenant(),
        cree_par_utilisateur_id=utilisateur_id,
        cle_profil_actif=str(etudiant.id),
    )
    session.add(profil)
    session.flush()
    for analyse in analyses:
        donnees = _encoder_valeurs(analyse.encodage)
        session.add(
            EncodageFacial(
                profil_biometrique_id=profil.id,
                encodage_binaire=donnees,
                dimension=len(analyse.encodage),
                format=FORMAT_ENCODAGE,
                version_moteur=moteur.version,
                actif=True,
                empreinte_integrite=hashlib.sha256(donnees).hexdigest(),
            )
        )
    session.add(
        JournalAudit(
            utilisateur_id=utilisateur_id,
            action="enrolement_biometrique",
            entite="profils_biometriques",
            entite_id=profil.id,
            details_json={"etudiant_id": etudiant.id, "nombre_captures": len(analyses), "reenrollement": reenrollement},
        )
    )
    session.commit()
    return _serialiser_profil(profil)


def changer_statut(
    session: Session, utilisateur_id: int, etudiant_id: int, statut: str, motif: str
) -> dict:
    if len(motif.strip()) < 3:
        raise ConflitDonnees("Le motif est obligatoire")
    profil = session.scalar(
        select(ProfilBiometrique).where(ProfilBiometrique.etudiant_id == etudiant_id, ProfilBiometrique.statut == "actif")
    )
    if profil is None:
        raise RessourceIntrouvable("Profil biometrique actif introuvable")
    profil.statut = statut
    if statut != "actif":
        profil.cle_profil_actif = None
    if statut == "revoque":
        profil.date_revocation = _maintenant()
        profil.motif_revocation = motif.strip()
    session.add(JournalAudit(utilisateur_id=utilisateur_id, action=f"profil_biometrique_{statut}", entite="profils_biometriques", entite_id=profil.id, details_json={"etudiant_id": etudiant_id, "motif": motif.strip()}))
    session.commit()
    return _serialiser_profil(profil)


def _meilleur_profil(profils: Iterable[ProfilBiometrique], analyses: list[AnalyseVisage], seuil: float) -> tuple[ProfilBiometrique | None, float | None]:
    candidats: list[tuple[ProfilBiometrique, list[float]]] = []
    for profil in profils:
        distances = [
            min(distance_euclidienne(analyse.encodage, _decoder_valeurs(encodage)) for encodage in profil.encodages if encodage.actif)
            for analyse in analyses
        ]
        if len(distances) == len(analyses) and distances and max(distances) <= seuil:
            candidats.append((profil, distances))
    if not candidats:
        return None, None
    candidats.sort(key=lambda item: sum(item[1]) / len(item[1]))
    meilleur = candidats[0]
    if len(candidats) > 1 and sum(candidats[1][1]) / len(candidats[1][1]) == sum(meilleur[1]) / len(meilleur[1]):
        return None, None
    return meilleur[0], sum(meilleur[1]) / len(meilleur[1])


def reconnaitre(
    session: Session,
    utilisateur_id: int,
    seance_id: int,
    captures: list[tuple[bytes, str | None]],
    moteur: MoteurReconnaissanceFaciale | None = None,
) -> dict:
    from app.services import presences_academiques

    seance = presences_academiques._seance(session, seance_id)
    if seance.statut != "ouverte":
        return {"visage_reconnu": False, "acces_autorise": False, "motif": "seance_fermee", "presence": None, "seance": presences_academiques._serialiser_seance(seance), "heure_decision": _maintenant()}
    try:
        _verifier_captures(captures)
    except ValueError as exc:
        raise ConflitDonnees(str(exc)) from exc
    moteur = _verifier_moteur(moteur)
    analyses: list[AnalyseVisage] = []
    try:
        analyses = [moteur.analyser(image) for image, _ in captures]
    except ValueError as exc:
        raise ConflitDonnees(str(exc)) from exc
    finally:
        for index in range(len(captures)):
            captures[index] = (b"", None)
    _verifier_coherence(analyses, obtenir_parametres().biometrie_seuil_distance)
    profils = session.scalars(
        select(ProfilBiometrique).options(selectinload(ProfilBiometrique.encodages)).where(ProfilBiometrique.statut == "actif")
    ).all()
    profil, distance = _meilleur_profil(profils, analyses, obtenir_parametres().biometrie_seuil_distance)
    if profil is None:
        return {"visage_reconnu": False, "acces_autorise": False, "motif": "visage_inconnu", "presence": None, "seance": presences_academiques._serialiser_seance(seance), "heure_decision": _maintenant()}
    etudiant = session.get(Etudiant, profil.etudiant_id)
    if etudiant is None:
        return {"visage_reconnu": False, "acces_autorise": False, "motif": "visage_inconnu", "presence": None, "seance": presences_academiques._serialiser_seance(seance), "heure_decision": _maintenant()}
    resultat = presences_academiques.controler_acces(
        session,
        utilisateur_id,
        seance_id,
        ControleAccesPresence(matricule=etudiant.matricule, methode_identification="reconnaissance_faciale"),
    )
    resultat.pop("pourcentage_paiement_utilise", None)
    if isinstance(resultat.get("presence"), dict):
        resultat["presence"].pop("pourcentage_paiement_observe", None)
    resultat["visage_reconnu"] = True
    resultat["distance"] = distance
    resultat["niveau_confiance"] = max(0.0, min(1.0, 1.0 - (distance or 1.0)))
    return resultat
