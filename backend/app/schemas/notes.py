from datetime import date
from decimal import Decimal

from pydantic import BaseModel, Field, field_validator


class EvaluationCreation(BaseModel):
    type_evaluation_id: int = Field(gt=0)
    titre: str = Field(min_length=2, max_length=180)
    note_maximale: Decimal = Field(gt=0, decimal_places=2)
    ponderation: Decimal = Field(gt=0, decimal_places=2)
    date_evaluation: date | None = None


class EvaluationModification(BaseModel):
    type_evaluation_id: int | None = Field(default=None, gt=0)
    titre: str | None = Field(default=None, min_length=2, max_length=180)
    note_maximale: Decimal | None = Field(default=None, gt=0, decimal_places=2)
    ponderation: Decimal | None = Field(default=None, gt=0, decimal_places=2)
    date_evaluation: date | None = None


class NoteEvaluationItem(BaseModel):
    etudiant_id: int = Field(gt=0)
    note_obtenue: Decimal = Field(ge=0, decimal_places=2)
    commentaire: str | None = None


class NotesEvaluationModification(BaseModel):
    notes: list[NoteEvaluationItem] = Field(min_length=1)

    @field_validator("notes")
    @classmethod
    def empecher_doublons(cls, valeur: list[NoteEvaluationItem]) -> list[NoteEvaluationItem]:
        ids = [note.etudiant_id for note in valeur]
        if len(ids) != len(set(ids)):
            raise ValueError("Un etudiant ne peut apparaitre qu'une seule fois dans le lot")
        return valeur


class PublicationEvaluationRequete(BaseModel):
    confirmer_notes_manquantes: bool = False
