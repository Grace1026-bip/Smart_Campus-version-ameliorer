from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field


TypePublicationValve = Literal[
    "annonce",
    "communique",
    "devoir",
    "support_de_cours",
    "changement_horaire",
    "consigne_examen",
    "rappel",
]


class PublicationValveCreation(BaseModel):
    cours_id: int = Field(gt=0)
    type_publication: TypePublicationValve
    titre: str = Field(min_length=3, max_length=180)
    contenu: str = Field(min_length=3)
    est_importante: bool = False
    publier_maintenant: bool = False


class PublicationValveModification(BaseModel):
    type_publication: TypePublicationValve | None = None
    titre: str | None = Field(default=None, min_length=3, max_length=180)
    contenu: str | None = Field(default=None, min_length=3)
    est_importante: bool | None = None
