from typing import Any

from pydantic import BaseModel, Field


class ReponseSucces(BaseModel):
    succes: bool = True
    message: str = "Operation reussie"
    donnees: Any = Field(default_factory=dict)


class ReponseErreur(BaseModel):
    succes: bool = False
    message: str = "Une erreur est survenue"
    erreurs: list[Any] = Field(default_factory=list)
