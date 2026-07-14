from __future__ import annotations

from datetime import date, time
from typing import Literal

from pydantic import BaseModel, Field, model_validator


TypeCoursSeance = Literal["cours_1", "cours_2", "autre"]


class SeanceAcademiqueCreation(BaseModel):
    cours_id: int = Field(gt=0)
    date_seance: date
    heure_debut: time | None = None
    heure_fin: time | None = None
    type_cours: TypeCoursSeance = "cours_1"

    @model_validator(mode="after")
    def verifier_heures(self) -> "SeanceAcademiqueCreation":
        if self.heure_debut is not None and self.heure_fin is not None and self.heure_fin <= self.heure_debut:
            raise ValueError("L heure de fin doit etre posterieure a l heure de debut")
        return self


class ControleAccesPresence(BaseModel):
    matricule: str = Field(min_length=2, max_length=80)
    statut: Literal["present", "retard"] = "present"
