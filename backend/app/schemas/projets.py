from pydantic import BaseModel, Field, field_validator

from app.modeles.projets import ROLES_ENCADREMENT, STATUTS_PROJET, TYPES_PROJET


def _normaliser_type(value: str) -> str:
    value = value.strip()
    if value not in TYPES_PROJET:
        raise ValueError("Type de projet invalide")
    return value


class ProjetCreation(BaseModel):
    etudiant_id: int = Field(gt=0)
    titre: str = Field(min_length=1, max_length=180)
    type_projet: str
    description: str | None = Field(default=None, max_length=5000)

    @field_validator("titre")
    @classmethod
    def titre_non_vide(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Le titre du projet est obligatoire")
        return value

    @field_validator("type_projet")
    @classmethod
    def type_controle(cls, value: str) -> str:
        return _normaliser_type(value)


class ProjetModification(BaseModel):
    titre: str | None = Field(default=None, min_length=1, max_length=180)
    type_projet: str | None = None
    description: str | None = Field(default=None, max_length=5000)
    statut: str | None = None

    @field_validator("titre")
    @classmethod
    def titre_non_vide(cls, value: str | None) -> str | None:
        if value is None:
            return value
        value = value.strip()
        if not value:
            raise ValueError("Le titre du projet est obligatoire")
        return value

    @field_validator("type_projet")
    @classmethod
    def type_controle(cls, value: str | None) -> str | None:
        return _normaliser_type(value) if value is not None else None

    @field_validator("statut")
    @classmethod
    def statut_controle(cls, value: str | None) -> str | None:
        if value is not None and value not in STATUTS_PROJET:
            raise ValueError("Statut de projet invalide")
        return value


class SpecialitesEnseignantModification(BaseModel):
    types_projet: list[str] = Field(default_factory=list, max_length=len(TYPES_PROJET))

    @field_validator("types_projet")
    @classmethod
    def types_controles(cls, values: list[str]) -> list[str]:
        normalises = [_normaliser_type(value) for value in values]
        if len(set(normalises)) != len(normalises):
            raise ValueError("Une specialite ne peut pas etre repetee")
        return normalises


class EncadrementCreation(BaseModel):
    enseignant_id: int = Field(gt=0)
    role_encadrement: str = "principal"
    remplacer_principal: bool = False

    @field_validator("role_encadrement")
    @classmethod
    def role_controle(cls, value: str) -> str:
        if value == "co_encadreur":
            return "coencadreur"
        if value not in ROLES_ENCADREMENT:
            raise ValueError("Role d encadrement invalide")
        return value


class EncadrementModification(BaseModel):
    role_encadrement: str

    @field_validator("role_encadrement")
    @classmethod
    def role_controle(cls, value: str) -> str:
        if value == "co_encadreur":
            return "coencadreur"
        if value not in ROLES_ENCADREMENT:
            raise ValueError("Role d encadrement invalide")
        return value
