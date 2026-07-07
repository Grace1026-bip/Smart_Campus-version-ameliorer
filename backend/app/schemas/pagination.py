from math import ceil
from typing import Any

from pydantic import BaseModel, Field


class ParametresPagination(BaseModel):
    page: int = Field(default=1, ge=1)
    taille: int = Field(default=20, ge=1, le=100)
    recherche: str | None = Field(default=None, max_length=120)

    @property
    def offset(self) -> int:
        return (self.page - 1) * self.taille


def construire_page(elements: list[Any], total: int, page: int, taille: int) -> dict[str, Any]:
    return {
        "elements": elements,
        "page": page,
        "taille": taille,
        "total": total,
        "pages": ceil(total / taille) if total else 0,
    }
