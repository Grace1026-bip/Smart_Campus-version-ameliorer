from datetime import datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from typing import Any

from jose import jwt
from passlib.context import CryptContext

from app.configuration.parametres import obtenir_parametres


def generer_chaine_secrete(longueur: int = 32) -> str:
    return token_urlsafe(longueur)


contexte_mot_de_passe = CryptContext(schemes=["bcrypt"], deprecated="auto")


def maintenant_utc() -> datetime:
    return datetime.utcnow()


def hacher_mot_de_passe(mot_de_passe: str) -> str:
    return contexte_mot_de_passe.hash(mot_de_passe)


def verifier_mot_de_passe(mot_de_passe: str, mot_de_passe_hash: str) -> bool:
    return contexte_mot_de_passe.verify(mot_de_passe, mot_de_passe_hash)


def hacher_jeton(jeton: str) -> str:
    return sha256(jeton.encode("utf-8")).hexdigest()


def generer_refresh_token() -> str:
    return token_urlsafe(48)


def creer_access_token(
    sujet: str,
    role: str,
    donnees_supplementaires: dict[str, Any] | None = None,
    expiration_minutes: int | None = None,
) -> str:
    parametres = obtenir_parametres()
    maintenant = maintenant_utc()
    expiration = maintenant + timedelta(
        minutes=expiration_minutes or parametres.access_token_expire_minutes,
    )

    donnees = {
        "sub": sujet,
        "role": role,
        "type": "access",
        "iat": int(maintenant.timestamp()),
        "exp": expiration,
    }
    if donnees_supplementaires:
        donnees.update(donnees_supplementaires)

    return jwt.encode(
        donnees,
        parametres.jwt_secret_key,
        algorithm=parametres.jwt_algorithm,
    )


def decoder_token(token: str) -> dict[str, Any]:
    parametres = obtenir_parametres()
    return jwt.decode(
        token,
        parametres.jwt_secret_key,
        algorithms=[parametres.jwt_algorithm],
    )
