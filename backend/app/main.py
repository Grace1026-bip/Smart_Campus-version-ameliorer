from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.configuration.parametres import obtenir_parametres
from app.exceptions.gestionnaires import enregistrer_gestionnaires_exceptions
from app.routes.api import routeur_api
from app.utilitaires.reponses import reponse_succes


ORIGINE_LOCALE_REGEX = r"^http://(localhost|127\.0\.0\.1)(:\d+)?$"
METHODES_CORS = ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
HEADERS_CORS = ["Authorization", "Content-Type", "Accept"]


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

    est_environnement_local = parametres.app_env.lower() in {
        "development",
        "dev",
        "test",
    }
    configuration_cors = {
        "allow_credentials": False,
        "allow_methods": METHODES_CORS,
        "allow_headers": HEADERS_CORS,
    }
    if est_environnement_local:
        configuration_cors["allow_origins"] = []
        configuration_cors["allow_origin_regex"] = ORIGINE_LOCALE_REGEX
    else:
        configuration_cors["allow_origins"] = parametres.frontend_origins

    application.add_middleware(CORSMiddleware, **configuration_cors)

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
