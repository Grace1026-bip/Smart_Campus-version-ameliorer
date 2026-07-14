from __future__ import annotations

from datetime import datetime

from sqlalchemy import or_, select
from sqlalchemy.orm import Session, joinedload, selectinload

from app.exceptions.erreurs import AccesInterdit, ConflitDonnees, ErreurApplication, RessourceIntrouvable
from app.modeles.academique import AnneeAcademique, Enseignant, Etudiant, Promotion
from app.modeles.enrolements import EnrolementAcademique
from app.modeles.projets import EncadrementProjet, ProjetAcademique, ROLES_ENCADREMENT, STATUTS_PROJET, TYPES_PROJET
from app.modeles.securite import Utilisateur, UtilisateurRole
from app.modeles.specialites import SpecialiteEncadrementEnseignant
from app.services.authentification import roles_utilisateur
from app.schemas.projets import (
    EncadrementCreation,
    EncadrementModification,
    ProjetCreation,
    ProjetModification,
    SpecialitesEnseignantModification,
)


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


# The active database convention is ``coencadreur``. The public API exposes
# the clearer ``co_encadreur`` spelling while accepting both on input.
def _role_api(role: str) -> str:
    return "co_encadreur" if role == "coencadreur" else role


def _charger_projet_gestion(session: Session, projet_id: int) -> ProjetAcademique:
    session.expire_all()
    projet = session.scalar(
        select(ProjetAcademique)
        .options(
            joinedload(ProjetAcademique.etudiant).joinedload(Etudiant.utilisateur),
            joinedload(ProjetAcademique.promotion),
            joinedload(ProjetAcademique.annee_academique),
            selectinload(ProjetAcademique.encadrements).options(
                joinedload(EncadrementProjet.enseignant).options(
                    joinedload(Enseignant.utilisateur),
                    selectinload(Enseignant.specialites_encadrement),
                ),
                joinedload(EncadrementProjet.attribue_par),
                joinedload(EncadrementProjet.desactive_par),
            ),
        )
        .where(ProjetAcademique.id == projet_id)
    )
    if projet is None:
        raise RessourceIntrouvable("Projet academique introuvable")
    return projet


def _charger_enseignant_gestion(session: Session, enseignant_id: int) -> Enseignant:
    enseignant = session.scalar(
        select(Enseignant)
        .options(
            joinedload(Enseignant.utilisateur).options(
                selectinload(Utilisateur.roles).joinedload(UtilisateurRole.role),
            ),
            selectinload(Enseignant.specialites_encadrement),
        )
        .where(Enseignant.id == enseignant_id)
    )
    if enseignant is None:
        raise RessourceIntrouvable("Enseignant introuvable")
    if enseignant.statut != "actif" or enseignant.utilisateur.statut != "actif":
        raise ErreurApplication("L enseignant doit avoir un compte actif")
    if "enseignant" not in roles_utilisateur(enseignant.utilisateur):
        raise ErreurApplication("Le compte ne possede pas le role enseignant")
    return enseignant


def _verifier_enrolement_valide(
    session: Session,
    etudiant: Etudiant,
    promotion_id: int,
    annee_academique_id: int,
) -> None:
    if etudiant.utilisateur.statut != "actif" or etudiant.statut_academique != "actif":
        raise ErreurApplication("Le compte etudiant doit etre actif")
    if etudiant.promotion_id != promotion_id:
        raise ErreurApplication("La promotion du projet est incoherente")
    promotion = session.get(Promotion, promotion_id)
    if promotion is None or not promotion.est_active:
        raise ErreurApplication("La promotion du projet doit etre active")
    if promotion.annee_academique_id != annee_academique_id:
        raise ErreurApplication("L annee academique du projet est incoherente")
    enrolement = session.scalar(
        select(EnrolementAcademique.id).where(
            EnrolementAcademique.etudiant_id == etudiant.id,
            EnrolementAcademique.promotion_id == promotion_id,
            EnrolementAcademique.annee_academique_id == annee_academique_id,
            EnrolementAcademique.statut == "valide",
        )
    )
    if enrolement is None:
        raise ErreurApplication(
            "Cet etudiant ne possede pas d enrolement academique valide pour l annee selectionnee"
        )


def _serialiser_specialite(specialite: SpecialiteEncadrementEnseignant) -> dict:
    return {
        "id": specialite.id,
        "type_projet": specialite.type_projet,
        "type_projet_libelle": LIBELLES_TYPES_PROJET[specialite.type_projet],
        "actif": specialite.actif,
        "date_creation": specialite.date_creation,
        "date_desactivation": specialite.date_desactivation,
        "cree_par_utilisateur_id": specialite.cree_par_utilisateur_id,
    }


def _serialiser_enseignant_gestion(enseignant: Enseignant, type_projet: str | None = None) -> dict:
    specialites = [
        item
        for item in enseignant.specialites_encadrement
        if item.actif and (type_projet is None or item.type_projet == type_projet)
    ]
    return {
        "id": enseignant.id,
        "utilisateur_id": enseignant.utilisateur_id,
        "matricule_agent": enseignant.matricule_agent,
        "nom": _nom(enseignant.utilisateur),
        "grade": enseignant.grade,
        "departement": enseignant.departement,
        "statut": enseignant.statut,
        "specialites": [_serialiser_specialite(item) for item in specialites],
        "types_projet_compatibles": [item.type_projet for item in specialites],
    }


def _serialiser_encadrement_gestion(encadrement: EncadrementProjet) -> dict:
    enseignant = encadrement.enseignant
    return {
        "id": encadrement.id,
        "enseignant_id": enseignant.id,
        "enseignant": {
            "id": enseignant.id,
            "matricule_agent": enseignant.matricule_agent,
            "nom": _nom(enseignant.utilisateur),
            "grade": enseignant.grade,
            "departement": enseignant.departement,
        },
        "role_encadrement": _role_api(encadrement.role_encadrement),
        "actif": encadrement.actif,
        "date_attribution": encadrement.date_attribution,
        "date_fin": encadrement.date_fin,
        "attribue_par_utilisateur_id": encadrement.attribue_par_utilisateur_id,
        "desactive_par_utilisateur_id": encadrement.desactive_par_utilisateur_id,
        "specialites": [
            _serialiser_specialite(item)
            for item in enseignant.specialites_encadrement
            if item.actif
        ],
    }


def _serialiser_projet_gestion(projet: ProjetAcademique) -> dict:
    encadrements_actifs = [item for item in projet.encadrements if item.actif]
    encadrements_historiques = [item for item in projet.encadrements if not item.actif]
    principal = next(
        (item for item in encadrements_actifs if item.role_encadrement == "principal"),
        None,
    )
    coencadreurs = [item for item in encadrements_actifs if item.role_encadrement == "coencadreur"]
    return {
        "id": projet.id,
        "projet_id": projet.id,
        "titre": projet.titre,
        "description": projet.description,
        "type_projet": projet.type_projet,
        "type_projet_libelle": LIBELLES_TYPES_PROJET[projet.type_projet],
        "statut": projet.statut,
        "etudiant": {
            "id": projet.etudiant.id,
            "matricule": projet.etudiant.matricule,
            "nom": _nom(projet.etudiant.utilisateur),
        },
        "promotion": {
            "id": projet.promotion.id,
            "nom": projet.promotion.nom,
            "niveau": projet.promotion.niveau,
        },
        "annee_academique": _annee(projet.annee_academique),
        "date_creation": projet.cree_le,
        "date_modification": projet.modifie_le,
        "encadreur_principal": (
            _serialiser_encadrement_gestion(principal) if principal else None
        ),
        "nombre_coencadreurs": len(coencadreurs),
        "encadrements_actifs": [_serialiser_encadrement_gestion(item) for item in encadrements_actifs],
        "encadrements_historiques": [
            _serialiser_encadrement_gestion(item) for item in encadrements_historiques
        ],
    }


def _valider_type_et_statut(type_projet: str | None, statut: str | None) -> None:
    if type_projet is not None and type_projet not in TYPES_PROJET:
        raise ErreurApplication("Type de projet invalide")
    if statut is not None and statut not in STATUTS_PROJET:
        raise ErreurApplication("Statut de projet invalide")


def lister_projets_appariteur(
    session: Session,
    type_projet: str | None = None,
    promotion_id: int | None = None,
    annee_academique_id: int | None = None,
    statut: str | None = None,
    etudiant_id: int | None = None,
    enseignant_id: int | None = None,
    recherche: str | None = None,
    sans_encadreur: bool = False,
    avec_encadreur: bool = False,
) -> dict:
    _valider_type_et_statut(type_projet, statut)
    projets = list(
        session.scalars(
            select(ProjetAcademique)
            .options(
                joinedload(ProjetAcademique.etudiant).joinedload(Etudiant.utilisateur),
                joinedload(ProjetAcademique.promotion),
                joinedload(ProjetAcademique.annee_academique),
                selectinload(ProjetAcademique.encadrements).options(
                    joinedload(EncadrementProjet.enseignant).options(
                        joinedload(Enseignant.utilisateur),
                        selectinload(Enseignant.specialites_encadrement),
                    ),
                    joinedload(EncadrementProjet.attribue_par),
                    joinedload(EncadrementProjet.desactive_par),
                ),
            )
            .order_by(ProjetAcademique.id.desc())
        ).unique().all()
    )
    terme = recherche.strip().lower() if recherche else None
    elements = []
    for projet in projets:
        actifs = [item for item in projet.encadrements if item.actif]
        if type_projet and projet.type_projet != type_projet:
            continue
        if promotion_id and projet.promotion_id != promotion_id:
            continue
        if annee_academique_id and projet.annee_academique_id != annee_academique_id:
            continue
        if statut and projet.statut != statut:
            continue
        if etudiant_id and projet.etudiant_id != etudiant_id:
            continue
        if enseignant_id and not any(item.enseignant_id == enseignant_id for item in actifs):
            continue
        if sans_encadreur and actifs:
            continue
        if avec_encadreur and not actifs:
            continue
        if terme:
            texte = " ".join(
                (
                    projet.titre,
                    projet.type_projet,
                    projet.etudiant.matricule,
                    _nom(projet.etudiant.utilisateur),
                )
            ).lower()
            if terme not in texte:
                continue
        elements.append(_serialiser_projet_gestion(projet))
    return {"elements": elements, "total": len(elements)}


def obtenir_projet_appariteur(session: Session, projet_id: int) -> dict:
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet_id))


def creer_projet_appariteur(session: Session, utilisateur_id: int, donnees: ProjetCreation) -> dict:
    etudiant = session.scalar(
        select(Etudiant)
        .options(joinedload(Etudiant.utilisateur), joinedload(Etudiant.promotion))
        .where(Etudiant.id == donnees.etudiant_id)
    )
    if etudiant is None:
        raise RessourceIntrouvable("Etudiant introuvable")
    annee_id = etudiant.promotion.annee_academique_id
    _verifier_enrolement_valide(session, etudiant, etudiant.promotion_id, annee_id)
    doublon = session.scalar(
        select(ProjetAcademique.id).where(
            ProjetAcademique.etudiant_id == etudiant.id,
            ProjetAcademique.annee_academique_id == annee_id,
            ProjetAcademique.statut != "archive",
        )
    )
    if doublon is not None:
        raise ConflitDonnees("Cet etudiant possede deja un projet actif pour cette annee")
    projet = ProjetAcademique(
        etudiant_id=etudiant.id,
        titre=donnees.titre.strip(),
        type_projet=donnees.type_projet,
        description=donnees.description.strip() if donnees.description else None,
        promotion_id=etudiant.promotion_id,
        annee_academique_id=annee_id,
        statut="propose",
    )
    session.add(projet)
    session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))


def modifier_projet_appariteur(session: Session, projet_id: int, donnees: ProjetModification) -> dict:
    projet = _charger_projet_gestion(session, projet_id)
    if projet.statut == "archive":
        raise ConflitDonnees("Un projet archive ne peut plus etre modifie")
    valeurs = donnees.model_dump(exclude_unset=True)
    nouveau_type = valeurs.get("type_projet", projet.type_projet)
    if valeurs.get("statut") == "archive":
        raise ConflitDonnees("Utilisez l action d archivage du projet")
    actifs = [item for item in projet.encadrements if item.actif]
    if nouveau_type != projet.type_projet:
        for encadrement in actifs:
            compatible = session.scalar(
                select(SpecialiteEncadrementEnseignant.id).where(
                    SpecialiteEncadrementEnseignant.enseignant_id == encadrement.enseignant_id,
                    SpecialiteEncadrementEnseignant.type_projet == nouveau_type,
                    SpecialiteEncadrementEnseignant.actif.is_(True),
                )
            )
            if compatible is None:
                raise ConflitDonnees(
                    "Le nouveau type est incompatible avec un encadreur actif"
                )
    for champ in ("titre", "type_projet", "description", "statut"):
        if champ in valeurs:
            valeur = valeurs[champ]
            setattr(projet, champ, valeur.strip() if isinstance(valeur, str) else valeur)
    session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))


def archiver_projet_appariteur(session: Session, utilisateur_id: int, projet_id: int) -> dict:
    projet = _charger_projet_gestion(session, projet_id)
    if projet.statut == "archive":
        return _serialiser_projet_gestion(projet)
    maintenant = datetime.now()
    projet.statut = "archive"
    for encadrement in projet.encadrements:
        if encadrement.actif:
            encadrement.actif = False
            encadrement.date_fin = maintenant
            encadrement.desactive_par_utilisateur_id = utilisateur_id
    session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))


def lister_enseignants_encadreurs(
    session: Session,
    type_projet: str | None = None,
    recherche: str | None = None,
) -> dict:
    if type_projet is not None and type_projet not in TYPES_PROJET:
        raise ErreurApplication("Type de projet invalide")
    enseignants = list(
        session.scalars(
            select(Enseignant)
            .options(
                joinedload(Enseignant.utilisateur).options(
                    selectinload(Utilisateur.roles).joinedload(UtilisateurRole.role),
                ),
                selectinload(Enseignant.specialites_encadrement),
            )
            .where(Enseignant.statut == "actif", Utilisateur.statut == "actif")
            .join(Enseignant.utilisateur)
            .order_by(Enseignant.id)
        ).unique().all()
    )
    terme = recherche.strip().lower() if recherche else None
    elements = []
    for enseignant in enseignants:
        if "enseignant" not in roles_utilisateur(enseignant.utilisateur):
            continue
        if type_projet and not any(
            item.actif and item.type_projet == type_projet
            for item in enseignant.specialites_encadrement
        ):
            continue
        if terme and terme not in (
            f"{_nom(enseignant.utilisateur)} {enseignant.matricule_agent or ''} "
            f"{enseignant.departement or ''}"
        ).lower():
            continue
        elements.append(_serialiser_enseignant_gestion(enseignant, type_projet))
    return {"elements": elements, "total": len(elements)}


def obtenir_specialites_enseignant(session: Session, enseignant_id: int) -> dict:
    enseignant = _charger_enseignant_gestion(session, enseignant_id)
    return {
        "enseignant": _serialiser_enseignant_gestion(enseignant),
        "specialites": [_serialiser_specialite(item) for item in enseignant.specialites_encadrement],
    }


def configurer_specialites_enseignant(
    session: Session,
    utilisateur_id: int,
    enseignant_id: int,
    donnees: SpecialitesEnseignantModification,
) -> dict:
    enseignant = _charger_enseignant_gestion(session, enseignant_id)
    demandees = set(donnees.types_projet)
    existantes = {item.type_projet: item for item in enseignant.specialites_encadrement}
    maintenant = datetime.now()
    for type_projet, specialite in existantes.items():
        if specialite.actif and type_projet not in demandees:
            specialite.actif = False
            specialite.date_desactivation = maintenant
            specialite.cle_doublon_active = None
        elif not specialite.actif and type_projet in demandees:
            specialite.actif = True
            specialite.date_desactivation = None
            specialite.cle_doublon_active = f"{enseignant.id}:{type_projet}"
    for type_projet in demandees:
        if type_projet not in existantes:
            session.add(
                SpecialiteEncadrementEnseignant(
                    enseignant_id=enseignant.id,
                    type_projet=type_projet,
                    actif=True,
                    cree_par_utilisateur_id=utilisateur_id,
                    cle_doublon_active=f"{enseignant.id}:{type_projet}",
                )
            )
    session.commit()
    session.expire_all()
    return obtenir_specialites_enseignant(session, enseignant.id)


def attribuer_encadrement_appariteur(
    session: Session,
    utilisateur_id: int,
    projet_id: int,
    donnees: EncadrementCreation,
) -> dict:
    projet = _charger_projet_gestion(session, projet_id)
    if projet.statut == "archive":
        raise ConflitDonnees("Un projet archive ne peut pas recevoir d encadrement")
    _verifier_enrolement_valide(session, projet.etudiant, projet.promotion_id, projet.annee_academique_id)
    enseignant = _charger_enseignant_gestion(session, donnees.enseignant_id)
    compatible = session.scalar(
        select(SpecialiteEncadrementEnseignant.id).where(
            SpecialiteEncadrementEnseignant.enseignant_id == enseignant.id,
            SpecialiteEncadrementEnseignant.type_projet == projet.type_projet,
            SpecialiteEncadrementEnseignant.actif.is_(True),
        )
    )
    if compatible is None:
        raise ConflitDonnees("L enseignant ne possede pas la specialite du projet")
    existant = next(
        (item for item in projet.encadrements if item.enseignant_id == enseignant.id and item.actif),
        None,
    )
    if existant is not None:
        raise ConflitDonnees("Cet enseignant est deja attribue a ce projet")
    principal = next(
        (item for item in projet.encadrements if item.actif and item.role_encadrement == "principal"),
        None,
    )
    if donnees.role_encadrement == "principal" and principal is not None:
        if not donnees.remplacer_principal:
            raise ConflitDonnees("Un encadreur principal est deja present")
        principal.actif = False
        principal.date_fin = datetime.now()
        principal.desactive_par_utilisateur_id = utilisateur_id
    historique = next(
        (item for item in projet.encadrements if item.enseignant_id == enseignant.id and not item.actif),
        None,
    )
    if historique is not None:
        historique.actif = True
        historique.role_encadrement = donnees.role_encadrement
        historique.date_attribution = datetime.now()
        historique.date_fin = None
        historique.attribue_par_utilisateur_id = utilisateur_id
        historique.desactive_par_utilisateur_id = None
    else:
        session.add(
            EncadrementProjet(
                projet_id=projet.id,
                enseignant_id=enseignant.id,
                attribue_par_utilisateur_id=utilisateur_id,
                role_encadrement=donnees.role_encadrement,
                actif=True,
            )
        )
    session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))


def modifier_encadrement_appariteur(
    session: Session,
    projet_id: int,
    encadrement_id: int,
    donnees: EncadrementModification,
) -> dict:
    projet = _charger_projet_gestion(session, projet_id)
    encadrement = next((item for item in projet.encadrements if item.id == encadrement_id), None)
    if encadrement is None:
        raise RessourceIntrouvable("Encadrement introuvable")
    if not encadrement.actif:
        raise ConflitDonnees("Un encadrement desactive ne peut plus etre modifie")
    if donnees.role_encadrement == "principal":
        autre = next(
            (
                item
                for item in projet.encadrements
                if item.actif and item.id != encadrement.id and item.role_encadrement == "principal"
            ),
            None,
        )
        if autre is not None:
            raise ConflitDonnees("Un encadreur principal est deja present")
    encadrement.role_encadrement = donnees.role_encadrement
    session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))


def desactiver_encadrement_appariteur(
    session: Session,
    utilisateur_id: int,
    projet_id: int,
    encadrement_id: int,
) -> dict:
    projet = _charger_projet_gestion(session, projet_id)
    encadrement = next((item for item in projet.encadrements if item.id == encadrement_id), None)
    if encadrement is None:
        raise RessourceIntrouvable("Encadrement introuvable")
    if encadrement.actif:
        encadrement.actif = False
        encadrement.date_fin = datetime.now()
        encadrement.desactive_par_utilisateur_id = utilisateur_id
        session.commit()
    return _serialiser_projet_gestion(_charger_projet_gestion(session, projet.id))
