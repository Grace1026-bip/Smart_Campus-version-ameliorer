from __future__ import annotations

from datetime import date
from typing import Literal

from pydantic import BaseModel, Field, field_validator, model_validator


StatutPresence = Literal["present", "absent", "retard", "justifie"]
NiveauRisque = Literal["faible", "moyen", "eleve"]


class PresenceEtudiantItem(BaseModel):
    etudiant_id: int = Field(gt=0)
    statut: StatutPresence


class PresenceLotCreation(BaseModel):
    date_seance: date
    presences: list[PresenceEtudiantItem] = Field(min_length=1)

    @field_validator("presences")
    @classmethod
    def empecher_doublons(cls, valeur: list[PresenceEtudiantItem]) -> list[PresenceEtudiantItem]:
        ids = [item.etudiant_id for item in valeur]
        if len(ids) != len(set(ids)):
            raise ValueError("Un etudiant ne peut apparaitre qu'une seule fois dans la seance")
        return valeur


class RecalculRisquesRequete(BaseModel):
    cours_id: int | None = Field(default=None, gt=0)
    promotion_id: int | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def valider_portee(self):
        if self.cours_id is not None and self.promotion_id is not None:
            raise ValueError("Choisis soit un cours, soit une promotion pour le recalcul")
        return self
