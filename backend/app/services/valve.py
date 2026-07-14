from __future__ import annotations

from datetime import date, datetime, time
from pathlib import Path
from uuid import uuid4

from fastapi import UploadFile, status
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session, selectinload

from app.configuration.parametres import obtenir_parametres
from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Cours, CoursEnseignant, Enseignant, Etudiant, InscriptionCours, Promotion, Semestre
from app.modeles.audit import JournalAudit
from app.modeles.notes import Evaluation, Note
from app.modeles.securite import Utilisateur
from app.modeles.valve import LecturePublication, PieceJointePublication, PublicationValve
from app.schemas.pagination import ParametresPagination, construire_page
from app.schemas.valve import PublicationValveCreation, PublicationValveModification
from app.services.notifications import creer_notification


MIMES_AUTORISES = {
    "pdf": {"application/pdf"},
    "docx": {"application/vnd.openxmlformats-officedocument.wordprocessingml.document"},
    "xlsx": {"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"},
    "pptx": {"application/vnd.openxmlformats-officedocument.presentationml.presentation"},
    "png": {"image/png"},
    "jpg": {"image/jpeg"},
    "jpeg": {"image/jpeg"},
}


def _maintenant() -> datetime:
    return datetime.utcnow()


def _racine_backend() -> Path:
    return Path(__file__).resolve().parents[2]


def _enseignant_connecte(session: Session, utilisateur_id: int) -> Enseignant:
    enseignant = session.scalar(select(Enseignant).where(Enseignant.utilisateur_id == utilisateur_id))
    if enseignant is None:
        raise AccesInterdit("Profil enseignant introuvable")
    return enseignant


def _etudiant_connecte(session: Session, utilisateur_id: int) -> Etudiant:
    etudiant = session.scalar(
        select(Etudiant).join(Etudiant.utilisateur).where(
            Etudiant.utilisateur_id == utilisateur_id,
            Etudiant.statut_academique == "actif",
            Utilisateur.statut == "actif",
        )
    )
    if etudiant is None:
        raise AccesInterdit("Profil etudiant indisponible")
    return etudiant


def _verifier_enseignant_du_cours(session: Session, utilisateur_id: int, cours_id: int) -> Enseignant:
    enseignant = _enseignant_connecte(session, utilisateur_id)
    affectation = session.scalar(
        select(CoursEnseignant).where(
            CoursEnseignant.cours_id == cours_id,
            CoursEnseignant.enseignant_id == enseignant.id,
        )
    )
    if affectation is None:
        raise AccesInterdit("Enseignant non affecte a ce cours")
    return enseignant


def _verifier_etudiant_inscrit(session: Session, etudiant_id: int, cours_id: int) -> None:
    inscription = session.scalar(
        select(InscriptionCours)
        .join(InscriptionCours.cours)
        .join(InscriptionCours.annee_academique)
        .join(Cours.promotion)
        .join(Semestre, Cours.semestre_id == Semestre.id)
        .where(
            InscriptionCours.etudiant_id == etudiant_id,
            InscriptionCours.cours_id == cours_id,
            InscriptionCours.statut == "active",
            InscriptionCours.annee_academique_id == Semestre.annee_academique_id,
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Promotion.est_active.is_(True),
        )
    )
    if inscription is None:
        raise AccesInterdit("Etudiant non inscrit a ce cours")


def _obtenir_publication(session: Session, publication_id: int) -> PublicationValve:
    publication = session.scalar(
        select(PublicationValve)
        .options(
            selectinload(PublicationValve.cours),
            selectinload(PublicationValve.auteur),
            selectinload(PublicationValve.pieces_jointes),
        )
        .where(PublicationValve.id == publication_id)
    )
    if publication is None:
        raise RessourceIntrouvable("Publication introuvable")
    return publication


def _publication_enseignant(session: Session, utilisateur_id: int, publication_id: int) -> PublicationValve:
    publication = _obtenir_publication(session, publication_id)
    _verifier_enseignant_du_cours(session, utilisateur_id, publication.cours_id)
    return publication


def _publication_de_enseignant(
    session: Session,
    utilisateur_id: int,
    publication_id: int,
) -> PublicationValve:
    publication = _publication_enseignant(session, utilisateur_id, publication_id)
    if publication.auteur_id != utilisateur_id:
        raise AccesInterdit("Cette publication appartient a un autre enseignant")
    return publication


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


def _serialiser_cours(cours: Cours) -> dict:
    semestre = cours.semestre
    promotion = cours.promotion
    annee = semestre.annee_academique if semestre else None
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


def _serialiser_piece(piece: PieceJointePublication) -> dict:
    return {
        "id": piece.id,
        "publication_id": piece.publication_id,
        "nom_original": piece.nom_original,
        "type_mime": piece.type_mime,
        "taille": piece.taille,
        "est_archivee": piece.est_archivee,
        "ajoute_le": piece.ajoute_le,
    }


def _publication_est_lue(session: Session, publication_id: int, utilisateur_id: int | None) -> bool:
    if utilisateur_id is None:
        return False
    lecture_id = session.scalar(
        select(LecturePublication.id).where(
            LecturePublication.publication_id == publication_id,
            LecturePublication.utilisateur_id == utilisateur_id,
        )
    )
    return lecture_id is not None


def _serialiser_publication(
    session: Session,
    publication: PublicationValve,
    utilisateur_id: int | None = None,
) -> dict:
    pieces = [piece for piece in publication.pieces_jointes if not piece.est_archivee]
    return {
        "id": publication.id,
        "cours_id": publication.cours_id,
        "cours": _serialiser_cours(publication.cours) if publication.cours else None,
        "auteur_id": publication.auteur_id,
        "auteur": _nom_utilisateur(publication.auteur),
        "est_auteur": utilisateur_id is not None and publication.auteur_id == utilisateur_id,
        "type_publication": publication.type_publication,
        "titre": publication.titre,
        "contenu": publication.contenu,
        "est_importante": publication.est_importante,
        "statut": publication.statut,
        "publie_le": publication.publie_le,
        "modifie_le": publication.modifie_le,
        "est_lue": _publication_est_lue(session, publication.id, utilisateur_id),
        "pieces_jointes": [_serialiser_piece(piece) for piece in pieces],
    }


def _serialiser_affectation(ligne) -> dict:
    affectation, enseignant, utilisateur = ligne
    return {
        "enseignant_id": enseignant.id,
        "utilisateur_id": utilisateur.id,
        "nom": _nom_utilisateur(utilisateur),
        "type_intervenant": affectation.type_intervenant,
        "est_responsable": affectation.est_responsable,
    }


def _enseignants_du_cours(session: Session, cours_id: int) -> list[dict]:
    lignes = session.execute(
        select(CoursEnseignant, Enseignant, Utilisateur)
        .join(Enseignant, CoursEnseignant.enseignant_id == Enseignant.id)
        .join(Utilisateur, Enseignant.utilisateur_id == Utilisateur.id)
        .where(CoursEnseignant.cours_id == cours_id)
        .order_by(CoursEnseignant.est_responsable.desc(), CoursEnseignant.type_intervenant)
    ).all()
    return [_serialiser_affectation(ligne) for ligne in lignes]


def _appliquer_filtres_publications(
    requete,
    recherche: str | None,
    cours_id: int | None,
    type_publication: str | None,
    date_debut: date | None,
    date_fin: date | None,
):
    if recherche:
        motif = f"%{recherche}%"
        requete = requete.where(or_(PublicationValve.titre.like(motif), PublicationValve.contenu.like(motif)))
    if cours_id:
        requete = requete.where(PublicationValve.cours_id == cours_id)
    if type_publication:
        requete = requete.where(PublicationValve.type_publication == type_publication)
    if date_debut:
        requete = requete.where(PublicationValve.publie_le >= datetime.combine(date_debut, time.min))
    if date_fin:
        requete = requete.where(PublicationValve.publie_le <= datetime.combine(date_fin, time.max))
    return requete


def _notifier_publication(session: Session, publication: PublicationValve) -> None:
    cours = publication.cours or session.get(Cours, publication.cours_id)
    titre = "Nouvelle publication"
    contenu = publication.titre
    if cours is not None:
        titre = f"Nouvelle publication - {cours.code}"
        contenu = f"{publication.titre} ({cours.intitule})"

    inscriptions = session.scalars(
        select(InscriptionCours).where(
            InscriptionCours.cours_id == publication.cours_id,
            InscriptionCours.statut == "active",
        )
    ).all()
    for inscription in inscriptions:
        etudiant = session.get(Etudiant, inscription.etudiant_id)
        if etudiant is None:
            continue
        creer_notification(
            session,
            etudiant.utilisateur_id,
            "nouvelle_publication",
            titre,
            contenu,
            {"publication_id": publication.id, "cours_id": publication.cours_id},
        )


def lister_valve_enseignant(
    session: Session,
    utilisateur_id: int,
    pagination: ParametresPagination,
    cours_id: int | None = None,
    type_publication: str | None = None,
    date_debut: date | None = None,
    date_fin: date | None = None,
) -> dict:
    enseignant = _enseignant_connecte(session, utilisateur_id)
    conditions = [
        CoursEnseignant.enseignant_id == enseignant.id,
        PublicationValve.statut != "archivee",
    ]

    requete = (
        select(PublicationValve)
        .join(CoursEnseignant, CoursEnseignant.cours_id == PublicationValve.cours_id)
        .options(
            selectinload(PublicationValve.cours),
            selectinload(PublicationValve.auteur),
            selectinload(PublicationValve.pieces_jointes),
        )
        .where(*conditions)
    )
    total_requete = (
        select(func.count())
        .select_from(PublicationValve)
        .join(CoursEnseignant, CoursEnseignant.cours_id == PublicationValve.cours_id)
        .where(*conditions)
    )
    requete = _appliquer_filtres_publications(
        requete,
        pagination.recherche,
        cours_id,
        type_publication,
        date_debut,
        date_fin,
    )
    total_requete = _appliquer_filtres_publications(
        total_requete,
        pagination.recherche,
        cours_id,
        type_publication,
        date_debut,
        date_fin,
    )

    total = session.scalar(total_requete) or 0
    publications = session.scalars(
        requete.order_by(PublicationValve.modifie_le.desc()).offset(pagination.offset).limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_publication(session, publication, utilisateur_id) for publication in publications],
        total,
        pagination.page,
        pagination.taille,
    )


def creer_publication(session: Session, utilisateur_id: int, donnees: PublicationValveCreation) -> dict:
    _verifier_enseignant_du_cours(session, utilisateur_id, donnees.cours_id)
    cours = session.get(Cours, donnees.cours_id)
    if cours is None:
        raise RessourceIntrouvable("Cours introuvable")

    publication = PublicationValve(
        cours_id=donnees.cours_id,
        auteur_id=utilisateur_id,
        type_publication=donnees.type_publication,
        titre=donnees.titre,
        contenu=donnees.contenu,
        est_importante=donnees.est_importante,
        statut="publiee" if donnees.publier_maintenant else "brouillon",
        publie_le=_maintenant() if donnees.publier_maintenant else None,
    )
    publication.cours = cours
    session.add(publication)
    try:
        session.flush()
        if publication.statut == "publiee":
            _notifier_publication(session, publication)
        _journaliser(
            session,
            utilisateur_id,
            "creation_publication_valve",
            "publications_valve",
            publication.id,
            {"statut": publication.statut},
        )
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Publication impossible a creer") from exc

    return obtenir_publication_enseignant(session, utilisateur_id, publication.id)


def obtenir_publication_enseignant(session: Session, utilisateur_id: int, publication_id: int) -> dict:
    publication = _publication_enseignant(session, utilisateur_id, publication_id)
    return _serialiser_publication(session, publication, utilisateur_id)


def modifier_publication(
    session: Session,
    utilisateur_id: int,
    publication_id: int,
    donnees: PublicationValveModification,
) -> dict:
    publication = _publication_de_enseignant(session, utilisateur_id, publication_id)
    if publication.statut == "archivee":
        raise AccesInterdit("Une publication archivee ne peut pas etre modifiee")

    valeurs = donnees.model_dump(exclude_unset=True)
    for champ, valeur in valeurs.items():
        setattr(publication, champ, valeur)

    try:
        _journaliser(
            session,
            utilisateur_id,
            "modification_publication_valve",
            "publications_valve",
            publication.id,
            {"champs": sorted(valeurs.keys())},
        )
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Publication impossible a modifier") from exc
    return obtenir_publication_enseignant(session, utilisateur_id, publication_id)


def publier_publication(session: Session, utilisateur_id: int, publication_id: int) -> dict:
    publication = _publication_de_enseignant(session, utilisateur_id, publication_id)
    if publication.statut == "archivee":
        raise AccesInterdit("Une publication archivee ne peut pas etre publiee")
    if publication.statut == "publiee":
        return _serialiser_publication(session, publication)

    publication.statut = "publiee"
    publication.publie_le = _maintenant()
    try:
        session.flush()
        _notifier_publication(session, publication)
        _journaliser(session, utilisateur_id, "publication_valve", "publications_valve", publication.id)
        session.commit()
    except IntegrityError as exc:
        session.rollback()
        raise ConflitDonnees("Publication impossible a publier") from exc
    return obtenir_publication_enseignant(session, utilisateur_id, publication_id)


def archiver_publication(session: Session, utilisateur_id: int, publication_id: int) -> dict:
    publication = _publication_de_enseignant(session, utilisateur_id, publication_id)
    publication.statut = "archivee"
    moment = _maintenant()
    for piece in publication.pieces_jointes:
        piece.est_archivee = True
        piece.archivee_le = moment
    _journaliser(session, utilisateur_id, "archivage_publication_valve", "publications_valve", publication.id)
    session.commit()
    return _serialiser_publication(session, publication)


def _dossier_stockage() -> Path:
    parametres = obtenir_parametres()
    dossier = Path(parametres.dossier_stockage_valve)
    if not dossier.is_absolute():
        dossier = _racine_backend() / dossier
    dossier.mkdir(parents=True, exist_ok=True)
    return dossier


def _chemin_persistant(chemin: Path) -> str:
    try:
        return str(chemin.relative_to(_racine_backend()))
    except ValueError:
        return str(chemin)


def _chemin_absolu(piece: PieceJointePublication) -> Path:
    chemin = Path(piece.chemin)
    if not chemin.is_absolute():
        chemin = _racine_backend() / chemin
    return chemin


def _valider_fichier(fichier: UploadFile, contenu: bytes) -> tuple[str, str]:
    parametres = obtenir_parametres()
    nom_original = Path(fichier.filename or "").name
    extension = Path(nom_original).suffix.lower().lstrip(".")
    extensions_autorisees = {extension.lower().lstrip(".") for extension in parametres.extensions_pieces_jointes_valve}
    if not nom_original or extension not in extensions_autorisees:
        raise ErreurApplication("Extension de fichier non autorisee", status.HTTP_400_BAD_REQUEST)

    type_mime = fichier.content_type or ""
    if type_mime not in MIMES_AUTORISES.get(extension, set()):
        raise ErreurApplication("Type MIME de fichier non autorise", status.HTTP_400_BAD_REQUEST)

    taille_max = parametres.taille_max_piece_jointe_valve_mb * 1024 * 1024
    if not contenu:
        raise ErreurApplication("Le fichier est vide", status.HTTP_400_BAD_REQUEST)
    if len(contenu) > taille_max:
        raise ErreurApplication("Le fichier depasse la taille maximale autorisee", status.HTTP_400_BAD_REQUEST)

    return nom_original, extension


def ajouter_piece_jointe(
    session: Session,
    utilisateur_id: int,
    publication_id: int,
    fichier: UploadFile,
) -> dict:
    publication = _publication_de_enseignant(session, utilisateur_id, publication_id)
    if publication.statut == "archivee":
        raise AccesInterdit("Impossible d'ajouter un document a une publication archivee")

    contenu = fichier.file.read()
    nom_original, extension = _valider_fichier(fichier, contenu)
    nom_stockage = f"{uuid4().hex}.{extension}"
    chemin = _dossier_stockage() / nom_stockage

    try:
        chemin.write_bytes(contenu)
        piece = PieceJointePublication(
            publication_id=publication.id,
            nom_original=nom_original,
            nom_stockage=nom_stockage,
            chemin=_chemin_persistant(chemin),
            type_mime=fichier.content_type or "",
            taille=len(contenu),
            est_archivee=False,
        )
        session.add(piece)
        session.flush()
        _journaliser(
            session,
            utilisateur_id,
            "ajout_piece_jointe_valve",
            "pieces_jointes_publications",
            piece.id,
            {"publication_id": publication.id},
        )
        session.commit()
    except Exception:
        session.rollback()
        if chemin.exists():
            chemin.unlink()
        raise

    session.refresh(piece)
    return _serialiser_piece(piece)


def archiver_piece_jointe(session: Session, utilisateur_id: int, piece_id: int) -> dict:
    piece = session.get(PieceJointePublication, piece_id)
    if piece is None or piece.est_archivee:
        raise RessourceIntrouvable("Piece jointe introuvable")
    publication = _publication_de_enseignant(session, utilisateur_id, piece.publication_id)
    if publication.statut == "archivee":
        raise AccesInterdit("La publication est deja archivee")

    piece.est_archivee = True
    piece.archivee_le = _maintenant()
    _journaliser(
        session,
        utilisateur_id,
        "archivage_piece_jointe_valve",
        "pieces_jointes_publications",
        piece.id,
        {"publication_id": publication.id},
    )
    session.commit()
    session.refresh(piece)
    return _serialiser_piece(piece)


def obtenir_piece_jointe_autorisee(
    session: Session,
    utilisateur_id: int,
    role_actif: str,
    piece_id: int,
) -> tuple[Path, str, str]:
    piece = session.get(PieceJointePublication, piece_id)
    if piece is None or piece.est_archivee:
        raise RessourceIntrouvable("Piece jointe introuvable")
    publication = _obtenir_publication(session, piece.publication_id)

    if role_actif == "enseignant":
        _verifier_enseignant_du_cours(session, utilisateur_id, publication.cours_id)
    elif role_actif == "etudiant":
        if publication.statut != "publiee":
            raise RessourceIntrouvable("Publication introuvable")
        etudiant = _etudiant_connecte(session, utilisateur_id)
        _verifier_etudiant_inscrit(session, etudiant.id, publication.cours_id)
    else:
        raise AccesInterdit("Role insuffisant")

    chemin = _chemin_absolu(piece)
    if not chemin.exists():
        raise RessourceIntrouvable("Fichier introuvable")
    return chemin, piece.nom_original, piece.type_mime


def _marquer_publication_lue(session: Session, publication_id: int, utilisateur_id: int) -> None:
    lecture = session.scalar(
        select(LecturePublication).where(
            LecturePublication.publication_id == publication_id,
            LecturePublication.utilisateur_id == utilisateur_id,
        )
    )
    if lecture is None:
        session.add(LecturePublication(publication_id=publication_id, utilisateur_id=utilisateur_id, lu_le=_maintenant()))
    else:
        lecture.lu_le = _maintenant()


def _publications_etudiant_cours(
    session: Session,
    utilisateur_id: int,
    cours_id: int,
    pagination: ParametresPagination,
    type_publication: str | None = None,
    date_debut: date | None = None,
    date_fin: date | None = None,
) -> dict:
    conditions = [PublicationValve.cours_id == cours_id, PublicationValve.statut == "publiee"]
    requete = (
        select(PublicationValve)
        .options(
            selectinload(PublicationValve.cours),
            selectinload(PublicationValve.auteur),
            selectinload(PublicationValve.pieces_jointes),
        )
        .where(*conditions)
    )
    total_requete = select(func.count()).select_from(PublicationValve).where(*conditions)
    requete = _appliquer_filtres_publications(
        requete,
        pagination.recherche,
        None,
        type_publication,
        date_debut,
        date_fin,
    )
    total_requete = _appliquer_filtres_publications(
        total_requete,
        pagination.recherche,
        None,
        type_publication,
        date_debut,
        date_fin,
    )
    total = session.scalar(total_requete) or 0
    publications = session.scalars(
        requete.order_by(PublicationValve.publie_le.desc()).offset(pagination.offset).limit(pagination.taille)
    ).all()
    return construire_page(
        [_serialiser_publication(session, publication, utilisateur_id) for publication in publications],
        total,
        pagination.page,
        pagination.taille,
    )


def lister_valve_etudiant(session: Session, utilisateur_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    inscriptions = session.scalars(
        select(InscriptionCours)
        .options(
            selectinload(InscriptionCours.cours).selectinload(Cours.semestre),
            selectinload(InscriptionCours.cours).selectinload(Cours.promotion),
        )
        .join(InscriptionCours.cours)
        .join(InscriptionCours.annee_academique)
        .join(Cours.promotion)
        .join(Semestre, Cours.semestre_id == Semestre.id)
        .where(
            InscriptionCours.etudiant_id == etudiant.id,
            InscriptionCours.statut == "active",
            InscriptionCours.annee_academique_id == Semestre.annee_academique_id,
            AnneeAcademique.est_active.is_(True),
            Cours.est_actif.is_(True),
            Cours.promotion_id == etudiant.promotion_id,
            Promotion.est_active.is_(True),
        )
        .order_by(InscriptionCours.cours_id)
    ).all()

    cartes = []
    for inscription in inscriptions:
        cours = inscription.cours
        publications = session.scalars(
            select(PublicationValve)
            .options(selectinload(PublicationValve.cours), selectinload(PublicationValve.auteur))
            .where(PublicationValve.cours_id == cours.id, PublicationValve.statut == "publiee")
            .order_by(PublicationValve.publie_le.desc())
        ).all()
        non_lues = sum(1 for publication in publications if not _publication_est_lue(session, publication.id, utilisateur_id))
        notes_publiees = session.scalar(
            select(func.count())
            .select_from(Note)
            .join(Evaluation, Note.evaluation_id == Evaluation.id)
            .where(
                Note.etudiant_id == etudiant.id,
                Evaluation.cours_id == cours.id,
                Evaluation.statut == "publiee",
            )
        ) or 0
        enseignants = _enseignants_du_cours(session, cours.id)
        cartes.append(
            {
                "cours": _serialiser_cours(cours),
                "enseignant_principal": next((item for item in enseignants if item["est_responsable"]), None),
                "assistants": [item for item in enseignants if item["type_intervenant"] != "professeur"],
                "nombre_publications": len(publications),
                "derniere_publication": _serialiser_publication(session, publications[0], utilisateur_id)
                if publications
                else None,
                "nombre_nouveautes": non_lues,
                "a_nouveau_contenu": non_lues > 0,
                "notes_disponibles": notes_publiees > 0,
            }
        )
    return {"cours": cartes}


def obtenir_cours_valve_etudiant(
    session: Session,
    utilisateur_id: int,
    cours_id: int,
    pagination: ParametresPagination,
    type_publication: str | None = None,
    date_debut: date | None = None,
    date_fin: date | None = None,
) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    _verifier_etudiant_inscrit(session, etudiant.id, cours_id)
    cours = session.get(Cours, cours_id)
    if cours is None:
        raise RessourceIntrouvable("Cours introuvable")
    return {
        "cours": _serialiser_cours(cours),
        "enseignants": _enseignants_du_cours(session, cours_id),
        "publications": _publications_etudiant_cours(
            session,
            utilisateur_id,
            cours_id,
            pagination,
            type_publication,
            date_debut,
            date_fin,
        ),
    }


def obtenir_publication_etudiant(session: Session, utilisateur_id: int, publication_id: int) -> dict:
    etudiant = _etudiant_connecte(session, utilisateur_id)
    publication = _obtenir_publication(session, publication_id)
    if publication.statut != "publiee":
        raise RessourceIntrouvable("Publication introuvable")
    _verifier_etudiant_inscrit(session, etudiant.id, publication.cours_id)
    _marquer_publication_lue(session, publication.id, utilisateur_id)
    session.commit()
    return _serialiser_publication(session, publication, utilisateur_id)
