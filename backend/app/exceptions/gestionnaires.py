from fastapi import FastAPI, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from sqlalchemy.exc import SQLAlchemyError
from starlette.exceptions import HTTPException as StarletteHTTPException

from app.exceptions.erreurs import ErreurApplication
from app.utilitaires.reponses import contenu_erreur


def enregistrer_gestionnaires_exceptions(application: FastAPI) -> None:
    @application.exception_handler(ErreurApplication)
    async def gerer_erreur_application(_requete: Request, exception: ErreurApplication):
        return JSONResponse(
            status_code=exception.code_http,
            content=contenu_erreur(exception.message, exception.erreurs),
        )

    @application.exception_handler(RequestValidationError)
    async def gerer_erreur_validation(_requete: Request, exception: RequestValidationError):
        erreurs = [
            {
                "champ": ".".join(str(partie) for partie in erreur.get("loc", [])),
                "message": erreur.get("msg", "Valeur invalide"),
            }
            for erreur in exception.errors()
        ]
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content=contenu_erreur("Donnees invalides", erreurs),
        )

    @application.exception_handler(StarletteHTTPException)
    async def gerer_erreur_http(_requete: Request, exception: StarletteHTTPException):
        message = exception.detail if isinstance(exception.detail, str) else "Erreur HTTP"
        return JSONResponse(
            status_code=exception.status_code,
            content=contenu_erreur(message),
        )

    @application.exception_handler(SQLAlchemyError)
    async def gerer_erreur_sqlalchemy(_requete: Request, _exception: SQLAlchemyError):
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=contenu_erreur("Erreur de base de donnees"),
        )

    @application.exception_handler(Exception)
    async def gerer_erreur_inattendue(_requete: Request, _exception: Exception):
        return JSONResponse(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            content=contenu_erreur("Erreur interne du serveur"),
        )
