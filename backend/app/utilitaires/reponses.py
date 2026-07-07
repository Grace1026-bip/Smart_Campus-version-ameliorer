from typing import Any

from fastapi.encoders import jsonable_encoder
from fastapi.responses import JSONResponse


def contenu_succes(message: str = "Operation reussie", donnees: Any | None = None) -> dict[str, Any]:
    return {
        "succes": True,
        "message": message,
        "donnees": donnees if donnees is not None else {},
    }


def contenu_erreur(message: str = "Une erreur est survenue", erreurs: list | None = None) -> dict[str, Any]:
    return {
        "succes": False,
        "message": message,
        "erreurs": erreurs or [],
    }


def reponse_succes(
    message: str = "Operation reussie",
    donnees: Any | None = None,
    code_http: int = 200,
) -> JSONResponse:
    return JSONResponse(
        status_code=code_http,
        content=jsonable_encoder(contenu_succes(message=message, donnees=donnees)),
    )


def reponse_erreur(
    message: str = "Une erreur est survenue",
    erreurs: list | None = None,
    code_http: int = 400,
) -> JSONResponse:
    return JSONResponse(
        status_code=code_http,
        content=jsonable_encoder(contenu_erreur(message=message, erreurs=erreurs)),
    )
