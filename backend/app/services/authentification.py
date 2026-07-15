from __future__ import annotations

from datetime import timedelta

from fastapi import Request, status
from jose import JWTError
from sqlalchemy import select
from sqlalchemy.orm import Session, selectinload

from app.configuration.parametres import obtenir_parametres
from app.configuration.securite import (
    creer_access_token,
    decoder_token,
    generer_refresh_token,
    hacher_jeton,
    hacher_mot_de_passe,
    maintenant_utc,
    verifier_mot_de_passe,
)
from app.exceptions.erreurs import AccesInterdit, AuthentificationRequise, ErreurApplication
from app.modeles.securite import JetonActualisation, Role, RolePermission, Utilisateur, UtilisateurRole
from app.schemas.authentification import (
    ActualisationRequete,
    ChangementMotDePasseRequete,
    ConnexionRequete,
    DeconnexionRequete,
)


MESSAGE_IDENTIFIANTS_INVALIDES = "Email, mot de passe ou role incorrect"
MESSAGE_ROLE_NON_AUTORISE = "Role non autorise pour ce compte"


def charger_utilisateur_par_email(session: Session, email: str) -> Utilisateur | None:
    return session.scalar(
        select(Utilisateur)
        .options(
            selectinload(Utilisateur.roles)
            .selectinload(UtilisateurRole.role)
            .selectinload(Role.permissions)
            .selectinload(RolePermission.permission)
        )
        .where(Utilisateur.email == email)
    )


def charger_utilisateur_par_id(session: Session, utilisateur_id: int) -> Utilisateur | None:
    return session.scalar(
        select(Utilisateur)
        .options(
            selectinload(Utilisateur.roles)
            .selectinload(UtilisateurRole.role)
            .selectinload(Role.permissions)
            .selectinload(RolePermission.permission)
        )
        .where(Utilisateur.id == utilisateur_id)
    )


def roles_utilisateur(utilisateur: Utilisateur) -> list[str]:
    return sorted({liaison.role.nom for liaison in utilisateur.roles if liaison.role})


def permissions_utilisateur(utilisateur: Utilisateur) -> list[str]:
    permissions = set()
    for liaison_role in utilisateur.roles:
        if not liaison_role.role:
            continue
        for liaison_permission in liaison_role.role.permissions:
            if liaison_permission.permission:
                permissions.add(liaison_permission.permission.code)
    return sorted(permissions)


def serialiser_utilisateur(utilisateur: Utilisateur, role_actif: str | None = None) -> dict:
    return {
        "id": utilisateur.id,
        "nom": utilisateur.nom,
        "postnom": utilisateur.postnom,
        "prenom": utilisateur.prenom,
        "email": utilisateur.email,
        "telephone": utilisateur.telephone,
        "photo": utilisateur.photo,
        "statut": utilisateur.statut,
        "roles": roles_utilisateur(utilisateur),
        "role_actif": role_actif,
        "permissions": permissions_utilisateur(utilisateur),
    }


def verifier_compte_actif(utilisateur: Utilisateur) -> None:
    if utilisateur.statut != "actif":
        raise AccesInterdit("Compte non actif")


def verifier_role(utilisateur: Utilisateur, role: str) -> None:
    if role not in roles_utilisateur(utilisateur):
        raise AccesInterdit(MESSAGE_ROLE_NON_AUTORISE)


def construire_reponse_jetons(session: Session, utilisateur: Utilisateur, role: str, request: Request | None, appareil: str | None) -> dict:
    parametres = obtenir_parametres()
    refresh_token = generer_refresh_token()
    expiration_refresh = maintenant_utc() + timedelta(days=parametres.refresh_token_expire_days)

    jeton = JetonActualisation(
        utilisateur_id=utilisateur.id,
        jeton_hash=hacher_jeton(refresh_token),
        expiration=expiration_refresh,
        est_revoque=False,
        appareil=appareil,
        adresse_ip=request.client.host if request and request.client else None,
    )
    session.add(jeton)

    utilisateur.derniere_connexion = maintenant_utc()
    session.commit()
    session.refresh(utilisateur)

    access_token = creer_access_token(
        sujet=str(utilisateur.id),
        role=role,
        donnees_supplementaires={"roles": roles_utilisateur(utilisateur)},
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": parametres.access_token_expire_minutes * 60,
        "role_actif": role,
        "utilisateur": serialiser_utilisateur(utilisateur, role_actif=role),
    }


def connecter(session: Session, donnees: ConnexionRequete, request: Request | None = None) -> dict:
    utilisateur = charger_utilisateur_par_email(session, donnees.email)
    if utilisateur is None or not verifier_mot_de_passe(donnees.mot_de_passe, utilisateur.mot_de_passe_hash):
        raise AuthentificationRequise(MESSAGE_IDENTIFIANTS_INVALIDES)

    verifier_compte_actif(utilisateur)
    verifier_role(utilisateur, donnees.role)

    return construire_reponse_jetons(session, utilisateur, donnees.role, request, donnees.appareil)


def actualiser(session: Session, donnees: ActualisationRequete, request: Request | None = None) -> dict:
    jeton_hash = hacher_jeton(donnees.refresh_token)
    jeton = session.scalar(
        select(JetonActualisation).where(
            JetonActualisation.jeton_hash == jeton_hash,
            JetonActualisation.est_revoque.is_(False),
        )
    )
    if jeton is None or jeton.expiration <= maintenant_utc():
        raise AuthentificationRequise("Refresh token invalide ou expire")

    utilisateur = charger_utilisateur_par_id(session, jeton.utilisateur_id)
    if utilisateur is None:
        raise AuthentificationRequise("Refresh token invalide ou expire")

    verifier_compte_actif(utilisateur)

    roles = roles_utilisateur(utilisateur)
    role = donnees.role
    if role is None:
        if len(roles) != 1:
            raise ErreurApplication("Role requis pour actualiser une session multi-role", status.HTTP_400_BAD_REQUEST)
        role = roles[0]

    verifier_role(utilisateur, role)

    jeton.est_revoque = True
    jeton.revoque_le = maintenant_utc()
    return construire_reponse_jetons(session, utilisateur, role, request, jeton.appareil)


def deconnecter(session: Session, utilisateur: Utilisateur, donnees: DeconnexionRequete) -> None:
    jeton_hash = hacher_jeton(donnees.refresh_token)
    jeton = session.scalar(
        select(JetonActualisation).where(
            JetonActualisation.jeton_hash == jeton_hash,
            JetonActualisation.utilisateur_id == utilisateur.id,
        )
    )
    if jeton is None:
        raise AuthentificationRequise("Refresh token invalide")

    jeton.est_revoque = True
    jeton.revoque_le = maintenant_utc()
    session.commit()


def changer_mot_de_passe(session: Session, utilisateur: Utilisateur, donnees: ChangementMotDePasseRequete) -> None:
    if not verifier_mot_de_passe(donnees.ancien_mot_de_passe, utilisateur.mot_de_passe_hash):
        raise AuthentificationRequise("Ancien mot de passe incorrect")

    utilisateur.mot_de_passe_hash = hacher_mot_de_passe(donnees.nouveau_mot_de_passe)
    session.query(JetonActualisation).filter(
        JetonActualisation.utilisateur_id == utilisateur.id,
        JetonActualisation.est_revoque.is_(False),
    ).update({"est_revoque": True, "revoque_le": maintenant_utc()})
    session.commit()


def extraire_identite_depuis_access_token(token: str) -> tuple[int, str]:
    try:
        payload = decoder_token(token)
    except JWTError as exc:
        raise AuthentificationRequise("Token invalide ou expire") from exc

    if payload.get("type") != "access":
        raise AuthentificationRequise("Token invalide ou expire")

    sujet = payload.get("sub")
    role = payload.get("role")
    if sujet is None or role is None:
        raise AuthentificationRequise("Token invalide ou expire")

    try:
        utilisateur_id = int(sujet)
    except (TypeError, ValueError) as exc:
        raise AuthentificationRequise("Token invalide ou expire") from exc

    return utilisateur_id, str(role)
