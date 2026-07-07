from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.configuration.parametres import obtenir_parametres
from app.exceptions.gestionnaires import enregistrer_gestionnaires_exceptions
from app.routes.api import routeur_api
from app.utilitaires.reponses import reponse_succes


def creer_application() -> FastAPI:
    parametres = obtenir_parametres()

    application = FastAPI(
        title=parametres.app_name,
        debug=parametres.app_debug,
        version="0.1.0",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    application.add_middleware(
        CORSMiddleware,
        allow_origins=parametres.frontend_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    enregistrer_gestionnaires_exceptions(application)
    application.include_router(routeur_api)

    @application.get("/", tags=["systeme"])
    def racine():
        return reponse_succes(
            message="API Smart Faculty operationnelle",
            donnees={"nom": parametres.app_name, "environnement": parametres.app_env},
        )

    return application


app = creer_application()
