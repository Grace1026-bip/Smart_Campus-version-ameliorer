from __future__ import annotations

from datetime import date, time
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


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
    methode_identification: Literal["manuelle", "matricule", "reconnaissance_faciale"] = "matricule"

    @field_validator("matricule")
    @classmethod
    def matricule_normalise(cls, valeur: str) -> str:
        return valeur.strip()


class CorrectionPresence(BaseModel):
    nouveau_statut: Literal["present", "retard", "absent", "refuse"]
    motif: str = Field(min_length=3, max_length=500)

    @field_validator("motif")
    @classmethod
    def motif_normalise(cls, valeur: str) -> str:
        valeur = valeur.strip()
        if len(valeur) < 3:
            raise ValueError("Le motif de correction est obligatoire")
        return valeur
