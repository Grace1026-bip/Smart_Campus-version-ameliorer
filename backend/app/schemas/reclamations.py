from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, model_validator


CategorieReclamation = Literal["erreur_note", "inscription", "cours", "document_academique", "autre"]
PrioriteReclamation = Literal["faible", "normale", "elevee", "urgente"]
StatutReclamation = Literal["en_attente", "en_cours", "resolue", "rejetee"]


class ReclamationCreation(BaseModel):
    categorie: CategorieReclamation
    objet: str = Field(min_length=3, max_length=180)
    description: str = Field(min_length=10)
    cours_id: int | None = Field(default=None, gt=0)
    note_id: int | None = Field(default=None, gt=0)
    priorite: PrioriteReclamation = "normale"

    @model_validator(mode="after")
    def valider_coherence(self):
        if self.categorie == "erreur_note" and self.note_id is None:
            raise ValueError("Une reclamation pour erreur de note doit referencer une note")
        return self


class MessageReclamationCreation(BaseModel):
    message: str = Field(min_length=2)
    est_interne: bool = False


class TraitementReclamation(BaseModel):
    statut: StatutReclamation | None = None
    priorite: PrioriteReclamation | None = None
    assignee_a: int | None = Field(default=None, gt=0)
    commentaire: str | None = Field(default=None, min_length=2)
    reponse_etudiant: str | None = Field(default=None, min_length=2)

    @model_validator(mode="after")
    def valider_action(self):
        if (
            self.statut is None
            and self.priorite is None
            and self.assignee_a is None
            and self.commentaire is None
            and self.reponse_etudiant is None
        ):
            raise ValueError("Au moins une action de traitement est requise")
        return self
