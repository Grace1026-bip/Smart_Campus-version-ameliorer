from dataclasses import dataclass
from typing import Callable

from fastapi import Depends
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.exceptions.erreurs import AccesInterdit, AuthentificationRequise
from app.modeles.securite import Utilisateur
from app.services.authentification import (
    charger_utilisateur_par_id,
    extraire_identite_depuis_access_token,
    permissions_utilisateur,
    roles_utilisateur,
    verifier_compte_actif,
    verifier_role,
)


schema_bearer = HTTPBearer(auto_error=False)


@dataclass
class ContexteUtilisateur:
    utilisateur: Utilisateur
    role_actif: str
    roles: list[str]
    permissions: list[str]


def obtenir_utilisateur_connecte(
    credentiels: HTTPAuthorizationCredentials | None = Depends(schema_bearer),
    session: Session = Depends(obtenir_session),
) -> ContexteUtilisateur:
    if credentiels is None or credentiels.scheme.lower() != "bearer":
        raise AuthentificationRequise()

    utilisateur_id, role_actif = extraire_identite_depuis_access_token(credentiels.credentials)
    utilisateur = charger_utilisateur_par_id(session, utilisateur_id)
    if utilisateur is None:
        raise AuthentificationRequise("Token invalide ou expire")

    verifier_compte_actif(utilisateur)
    verifier_role(utilisateur, role_actif)

    return ContexteUtilisateur(
        utilisateur=utilisateur,
        role_actif=role_actif,
        roles=roles_utilisateur(utilisateur),
        permissions=permissions_utilisateur(utilisateur),
    )


def exiger_role(role: str) -> Callable:
    def dependance(contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte)) -> ContexteUtilisateur:
        if contexte.role_actif != role:
            raise AccesInterdit("Role insuffisant")
        return contexte

    return dependance


def exiger_un_des_roles(*roles: str) -> Callable:
    roles_autorises = set(roles)

    def dependance(contexte: ContexteUtilisateur = Depends(obtenir_utilisateur_connecte)) -> ContexteUtilisateur:
        if contexte.role_actif not in roles_autorises:
            raise AccesInterdit("Role insuffisant")
        return contexte

    return dependance
