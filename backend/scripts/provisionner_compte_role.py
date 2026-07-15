from __future__ import annotations

import getpass
import re
import sys
from pathlib import Path

from sqlalchemy import select

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import hacher_mot_de_passe
from app.modeles import Role, Utilisateur, UtilisateurRole


ROLES_PROVISIONNABLES = {
    "surveillant": "Surveillance academique",
    "vice_doyen": "Pilotage academique delegue",
}


def demander_email() -> str:
    while True:
        email = input("Email du compte : ").strip().lower()
        if re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
            return email
        print("Email invalide.")


def demander_role() -> str:
    while True:
        role = input("Role (surveillant ou vice_doyen) : ").strip().lower()
        if role in ROLES_PROVISIONNABLES:
            return role
        print("Role refuse. Utilisez uniquement surveillant ou vice_doyen.")


def demander_mot_de_passe() -> str:
    while True:
        mot_de_passe = getpass.getpass("Mot de passe (saisie masquee) : ")
        confirmation = getpass.getpass("Confirmer le mot de passe : ")
        if len(mot_de_passe) >= 8 and mot_de_passe == confirmation:
            return mot_de_passe
        print("Mot de passe invalide ou confirmations differentes.")


def main() -> None:
    print("Provisionnement local d'un compte Smart Faculty")
    print("Base cible lue depuis la configuration active ; aucune fixture de test n'est copiee.")
    email = demander_email()
    role_nom = demander_role()
    mot_de_passe = demander_mot_de_passe()

    with SessionLocale() as session:
        role = session.scalar(select(Role).where(Role.nom == role_nom))
        if role is None:
            role = Role(nom=role_nom, description=ROLES_PROVISIONNABLES[role_nom])
            session.add(role)
            session.flush()

        utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == email))
        if utilisateur is None:
            nom = input("Nom : ").strip() or "Utilisateur"
            prenom = input("Prenom : ").strip() or None
            utilisateur = Utilisateur(
                nom=nom,
                prenom=prenom,
                email=email,
                mot_de_passe_hash=hacher_mot_de_passe(mot_de_passe),
                statut="actif",
            )
            session.add(utilisateur)
            session.flush()
        else:
            confirmation = input("Compte existant : reactiver et reinitialiser le mot de passe ? [o/N] ").strip().lower()
            if confirmation != "o":
                print("Aucune modification effectuee.")
                return
            utilisateur.mot_de_passe_hash = hacher_mot_de_passe(mot_de_passe)
            utilisateur.statut = "actif"

        liaison = session.scalar(
            select(UtilisateurRole).where(
                UtilisateurRole.utilisateur_id == utilisateur.id,
                UtilisateurRole.role_id == role.id,
            )
        )
        if liaison is None:
            session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))

        session.commit()
        print(f"Compte provisionne : {email} avec le role {role_nom}.")


if __name__ == "__main__":
    main()
