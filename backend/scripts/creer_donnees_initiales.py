from __future__ import annotations

import sys
from datetime import date
from pathlib import Path

from passlib.context import CryptContext
from sqlalchemy import select

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import (
    AnneeAcademique,
    Cours,
    CoursEnseignant,
    Enseignant,
    Etudiant,
    InscriptionCours,
    Permission,
    Promotion,
    Role,
    RolePermission,
    Semestre,
    TypeEvaluation,
    Utilisateur,
    UtilisateurRole,
)


contexte_mot_de_passe = CryptContext(schemes=["bcrypt"], deprecated="auto")
MOT_DE_PASSE_TEST = "Smart@123456"


def obtenir_ou_creer(session, modele, valeurs_recherche: dict, valeurs_creation: dict | None = None):
    instance = session.scalar(select(modele).filter_by(**valeurs_recherche))
    if instance:
        return instance

    donnees = {**valeurs_recherche, **(valeurs_creation or {})}
    instance = modele(**donnees)
    session.add(instance)
    session.flush()
    return instance


def creer_utilisateur(session, email: str, nom: str, prenom: str, roles: list[Role]) -> Utilisateur:
    utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == email))
    if utilisateur is None:
        utilisateur = Utilisateur(
            nom=nom,
            postnom=None,
            prenom=prenom,
            email=email,
            mot_de_passe_hash=contexte_mot_de_passe.hash(MOT_DE_PASSE_TEST),
            statut="actif",
        )
        session.add(utilisateur)
        session.flush()

    for role in roles:
        existe = session.scalar(
            select(UtilisateurRole).where(
                UtilisateurRole.utilisateur_id == utilisateur.id,
                UtilisateurRole.role_id == role.id,
            )
        )
        if existe is None:
            session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))

    session.flush()
    return utilisateur


def associer_permission(session, role: Role, permission: Permission) -> None:
    existe = session.scalar(
        select(RolePermission).where(
            RolePermission.role_id == role.id,
            RolePermission.permission_id == permission.id,
        )
    )
    if existe is None:
        session.add(RolePermission(role_id=role.id, permission_id=permission.id))


def creer_donnees_initiales() -> None:
    with SessionLocale() as session:
        roles = {
            nom: obtenir_ou_creer(session, Role, {"nom": nom}, {"description": description})
            for nom, description in {
                "etudiant": "Acces etudiant",
                "enseignant": "Acces enseignant",
                "chef_promotion": "Representation de promotion",
                "surveillant": "Surveillance academique",
                "appariteur": "Gestion academique operationnelle",
                "doyen": "Pilotage et decision academique",
                "vice_doyen": "Pilotage academique delegue",
                "administrateur": "Administration systeme",
                "icp": "Role historique conserve",
                "paritaire": "Role historique conserve",
            }.items()
        }

        permissions = {
            code: obtenir_ou_creer(session, Permission, {"code": code}, {"description": description})
            for code, description in {
                "auth.moi": "Consulter son profil connecte",
                "academique.lecture": "Lire les donnees academiques",
                "academique.ecriture": "Creer et modifier les donnees academiques",
                "notes.encoder": "Encoder des notes",
                "notes.publier": "Publier des notes",
                "reclamations.creer": "Creer une reclamation",
                "reclamations.traiter": "Traiter une reclamation",
                "dashboard.lecture": "Consulter le dashboard decisionnel",
                "utilisateurs.administrer": "Administrer les utilisateurs et roles",
            }.items()
        }

        matrice_permissions = {
            "etudiant": ["auth.moi", "reclamations.creer"],
            "enseignant": ["auth.moi", "academique.lecture", "notes.encoder", "notes.publier", "reclamations.traiter"],
            "chef_promotion": ["auth.moi", "academique.lecture", "reclamations.creer"],
            "surveillant": ["auth.moi", "academique.lecture"],
            "appariteur": ["auth.moi", "academique.lecture", "academique.ecriture", "reclamations.traiter", "dashboard.lecture"],
            "doyen": ["auth.moi", "academique.lecture", "dashboard.lecture"],
            "vice_doyen": ["auth.moi", "academique.lecture", "dashboard.lecture"],
            "administrateur": list(permissions.keys()),
            "icp": ["auth.moi"],
            "paritaire": ["auth.moi"],
        }
        for role_nom, codes_permissions in matrice_permissions.items():
            for code in codes_permissions:
                associer_permission(session, roles[role_nom], permissions[code])

        annee = obtenir_ou_creer(
            session,
            AnneeAcademique,
            {"libelle": "2025-2026"},
            {"date_debut": date(2025, 10, 1), "date_fin": date(2026, 9, 30), "est_active": True},
        )
        semestre_1 = obtenir_ou_creer(session, Semestre, {"annee_academique_id": annee.id, "numero": 1}, {"nom": "Semestre 1"})
        semestre_2 = obtenir_ou_creer(session, Semestre, {"annee_academique_id": annee.id, "numero": 2}, {"nom": "Semestre 2"})

        promotion_l1 = obtenir_ou_creer(
            session,
            Promotion,
            {"nom": "L1 Informatique", "annee_academique_id": annee.id},
            {"niveau": "L1", "description": "Premiere licence informatique", "est_active": True},
        )
        promotion_l2 = obtenir_ou_creer(
            session,
            Promotion,
            {"nom": "L2 Informatique", "annee_academique_id": annee.id},
            {"niveau": "L2", "description": "Deuxieme licence informatique", "est_active": True},
        )

        cours_algo = obtenir_ou_creer(
            session,
            Cours,
            {"code": "ALGO101", "promotion_id": promotion_l1.id, "semestre_id": semestre_1.id},
            {"intitule": "Algorithmique", "nombre_heures": 45, "nombre_credits": 4, "est_actif": True},
        )
        cours_bd = obtenir_ou_creer(
            session,
            Cours,
            {"code": "BD201", "promotion_id": promotion_l2.id, "semestre_id": semestre_1.id},
            {"intitule": "Bases de donnees", "nombre_heures": 60, "nombre_credits": 5, "est_actif": True},
        )
        cours_web = obtenir_ou_creer(
            session,
            Cours,
            {"code": "WEB202", "promotion_id": promotion_l2.id, "semestre_id": semestre_2.id},
            {"intitule": "Developpement Web", "nombre_heures": 60, "nombre_credits": 5, "est_actif": True},
        )

        for nom, description in {
            "interrogation": "Interrogation ou quiz",
            "travail_pratique": "Travail pratique",
            "examen": "Examen",
            "autre": "Autre evaluation",
        }.items():
            obtenir_ou_creer(session, TypeEvaluation, {"nom": nom}, {"description": description})

        utilisateur_admin = creer_utilisateur(
            session,
            "admin@smartfaculty.test",
            "Admin",
            "Systeme",
            [roles["administrateur"]],
        )
        utilisateur_enseignant = creer_utilisateur(
            session,
            "enseignant@smartfaculty.test",
            "Mukendi",
            "Jean",
            [roles["enseignant"]],
        )
        utilisateur_etudiant = creer_utilisateur(
            session,
            "etudiant@smartfaculty.test",
            "Kabeya",
            "Grace",
            [roles["etudiant"]],
        )
        creer_utilisateur(
            session,
            "chef.promotion@smartfaculty.test",
            "Kabeya",
            "Chef",
            [roles["etudiant"], roles["chef_promotion"]],
        )
        creer_utilisateur(
            session,
            "surveillant@smartfaculty.test",
            "Surveillance",
            "Campus",
            [roles["surveillant"]],
        )
        creer_utilisateur(
            session,
            "appariteur@smartfaculty.test",
            "Ilunga",
            "Patrick",
            [roles["appariteur"]],
        )
        creer_utilisateur(
            session,
            "doyen@smartfaculty.test",
            "Tshibanda",
            "Marie",
            [roles["doyen"], roles["enseignant"]],
        )
        creer_utilisateur(
            session,
            "vice.doyen@smartfaculty.test",
            "Tshibanda",
            "Vice",
            [roles["vice_doyen"], roles["enseignant"]],
        )

        enseignant = obtenir_ou_creer(
            session,
            Enseignant,
            {"utilisateur_id": utilisateur_enseignant.id},
            {"matricule_agent": "ENS-0001", "grade": "Assistant", "departement": "Informatique", "statut": "actif"},
        )
        etudiant = obtenir_ou_creer(
            session,
            Etudiant,
            {"utilisateur_id": utilisateur_etudiant.id},
            {
                "matricule": "SF-L2-0001",
                "promotion_id": promotion_l2.id,
                "date_inscription": date(2025, 10, 10),
                "statut_academique": "actif",
            },
        )

        for cours in [cours_algo, cours_bd, cours_web]:
            obtenir_ou_creer(
                session,
                CoursEnseignant,
                {"cours_id": cours.id, "enseignant_id": enseignant.id, "type_intervenant": "professeur"},
                {"est_responsable": True},
            )

        for cours in [cours_bd, cours_web]:
            obtenir_ou_creer(
                session,
                InscriptionCours,
                {"etudiant_id": etudiant.id, "cours_id": cours.id, "annee_academique_id": annee.id},
                {"date_inscription": date(2025, 10, 10), "statut": "active"},
            )

        session.commit()
        print("Donnees initiales creees ou deja presentes.")
        print(f"Administrateur de test: {utilisateur_admin.email}")


if __name__ == "__main__":
    creer_donnees_initiales()
