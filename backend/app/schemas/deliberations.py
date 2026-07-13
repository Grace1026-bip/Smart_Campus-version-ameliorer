from typing import Literal

from pydantic import BaseModel, Field


class SessionDeliberationCreation(BaseModel):
    promotion_id: int = Field(gt=0)
    annee_academique_id: int = Field(gt=0)
    semestre_id: int = Field(gt=0)


class MembreJuryCreation(BaseModel):
    utilisateur_id: int = Field(gt=0)
    qualite: Literal["president", "membre", "secretaire"]
    present: bool = True


class DecisionJuryCreation(BaseModel):
    decision: Literal["ADM", "COMP", "DEF", "AJ"]
    motif: str | None = Field(default=None, max_length=2000)


class ReouvertureCreation(BaseModel):
    motif: str = Field(min_length=3, max_length=2000)
