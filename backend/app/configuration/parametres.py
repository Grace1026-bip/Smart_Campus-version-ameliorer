from functools import lru_cache
from urllib.parse import quote_plus

from pydantic import AliasChoices, Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Parametres(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=(".env", "backend/.env"),
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=False,
    )

    app_name: str = Field(default="Smart Faculty", validation_alias="APP_NAME")
    app_env: str = Field(default="development", validation_alias="APP_ENV")
    app_debug: bool = Field(default=True, validation_alias="APP_DEBUG")

    mysql_host: str = Field(default="localhost", validation_alias=AliasChoices("MYSQL_HOST", "DB_HOST"))
    mysql_port: int = Field(default=3306, validation_alias=AliasChoices("MYSQL_PORT", "DB_PORT"))
    mysql_database: str = Field(default="smart_faculty", validation_alias=AliasChoices("MYSQL_DATABASE", "DB_DATABASE"))
    mysql_user: str = Field(default="root", validation_alias=AliasChoices("MYSQL_USER", "DB_USERNAME"))
    mysql_password: str = Field(default="", validation_alias=AliasChoices("MYSQL_PASSWORD", "DB_PASSWORD"))

    jwt_secret_key: str = Field(default="changer_cette_cle", validation_alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", validation_alias="JWT_ALGORITHM")
    access_token_expire_minutes: int = Field(default=30, validation_alias="ACCESS_TOKEN_EXPIRE_MINUTES")
    refresh_token_expire_days: int = Field(default=15, validation_alias="REFRESH_TOKEN_EXPIRE_DAYS")
    seuil_reussite_cours: float = Field(default=50.0, validation_alias="SEUIL_REUSSITE_COURS")
    ponderation_max_cours: float = Field(default=100.0, validation_alias="PONDERATION_MAX_COURS")
    seuil_risque_moyen: float = Field(default=35.0, validation_alias="SEUIL_RISQUE_MOYEN")
    seuil_risque_eleve: float = Field(default=70.0, validation_alias="SEUIL_RISQUE_ELEVE")
    dossier_stockage_valve: str = Field(default="stockage/valve", validation_alias="DOSSIER_STOCKAGE_VALVE")
    taille_max_piece_jointe_valve_mb: int = Field(default=10, ge=1, validation_alias="TAILLE_MAX_PIECE_JOINTE_VALVE_MB")
    extensions_pieces_jointes_valve: list[str] = Field(
        default_factory=lambda: ["pdf", "docx", "xlsx", "pptx", "png", "jpg", "jpeg"],
        validation_alias="EXTENSIONS_PIECES_JOINTES_VALVE",
    )

    frontend_origins: list[str] = Field(
        default_factory=lambda: ["http://localhost:3000", "http://localhost:5000"],
        validation_alias="FRONTEND_ORIGINS",
    )

    @field_validator("frontend_origins", mode="before")
    @classmethod
    def convertir_origines(cls, valeur):
        if isinstance(valeur, str):
            return [origine.strip() for origine in valeur.split(",") if origine.strip()]
        return valeur

    @field_validator("extensions_pieces_jointes_valve", mode="before")
    @classmethod
    def convertir_extensions(cls, valeur):
        if isinstance(valeur, str):
            return [extension.strip().lower().lstrip(".") for extension in valeur.split(",") if extension.strip()]
        return valeur

    @model_validator(mode="after")
    def valider_parametres(self):
        champs_obligatoires = {
            "MYSQL_HOST": self.mysql_host,
            "MYSQL_DATABASE": self.mysql_database,
            "MYSQL_USER": self.mysql_user,
            "JWT_SECRET_KEY": self.jwt_secret_key,
        }
        manquants = [nom for nom, valeur in champs_obligatoires.items() if valeur is None or str(valeur).strip() == ""]
        if manquants:
            raise ValueError(f"Variables d'environnement obligatoires manquantes: {', '.join(manquants)}")

        if self.app_env.lower() in {"production", "prod"} and self.jwt_secret_key == "changer_cette_cle":
            raise ValueError("JWT_SECRET_KEY doit etre personnalisee en production.")

        return self

    @property
    def url_base_de_donnees(self) -> str:
        utilisateur = quote_plus(self.mysql_user)
        mot_de_passe = quote_plus(self.mysql_password)
        identifiants = utilisateur if mot_de_passe == "" else f"{utilisateur}:{mot_de_passe}"
        return (
            f"mysql+pymysql://{identifiants}@{self.mysql_host}:{self.mysql_port}/"
            f"{self.mysql_database}?charset=utf8mb4"
        )


@lru_cache
def obtenir_parametres() -> Parametres:
    return Parametres()
