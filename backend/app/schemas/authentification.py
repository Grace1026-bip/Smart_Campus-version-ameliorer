from pydantic import BaseModel, Field, field_validator


ROLES_AUTORISES = {"etudiant", "enseignant", "appariteur", "doyen", "administrateur"}


class ConnexionRequete(BaseModel):
    email: str = Field(min_length=3, max_length=190)
    mot_de_passe: str = Field(min_length=1, max_length=128)
    role: str = Field(min_length=3, max_length=60)
    appareil: str | None = Field(default=None, max_length=255)

    @field_validator("email")
    @classmethod
    def normaliser_email(cls, valeur: str) -> str:
        return valeur.strip().lower()

    @field_validator("role")
    @classmethod
    def valider_role(cls, valeur: str) -> str:
        role = valeur.strip().lower()
        if role not in ROLES_AUTORISES:
            raise ValueError("Role invalide")
        return role


class ActualisationRequete(BaseModel):
    refresh_token: str = Field(min_length=20)
    role: str | None = Field(default=None, max_length=60)

    @field_validator("role")
    @classmethod
    def valider_role(cls, valeur: str | None) -> str | None:
        if valeur is None:
            return None
        role = valeur.strip().lower()
        if role not in ROLES_AUTORISES:
            raise ValueError("Role invalide")
        return role


class DeconnexionRequete(BaseModel):
    refresh_token: str = Field(min_length=20)


class ChangementMotDePasseRequete(BaseModel):
    ancien_mot_de_passe: str = Field(min_length=1, max_length=128)
    nouveau_mot_de_passe: str = Field(min_length=8, max_length=128)


class UtilisateurConnecteReponse(BaseModel):
    id: int
    nom: str
    postnom: str | None = None
    prenom: str | None = None
    email: str
    telephone: str | None = None
    photo: str | None = None
    statut: str
    roles: list[str]
    role_actif: str | None = None
    permissions: list[str] = []


class JetonsReponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int
    role_actif: str
    utilisateur: UtilisateurConnecteReponse
