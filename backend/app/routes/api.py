from fastapi import APIRouter

from app.base_de_donnees.connexion import verifier_connexion_mysql
from app.configuration.parametres import obtenir_parametres
from app.routes.academique import routeur_academique
from app.routes.authentification import routeur_auth
from app.routes.dashboard import routeur_dashboard
from app.routes.enseignants import routeur_enseignants
from app.routes.inscriptions import routeur_inscriptions
from app.routes.notes import routeur_notes
from app.routes.notifications import routeur_notifications
from app.routes.reclamations import routeur_reclamations
from app.routes.risques import routeur_risques
from app.routes.valve import routeur_valve
from app.utilitaires.reponses import reponse_erreur, reponse_succes


routeur_api = APIRouter(prefix="/api/v1")
routeur_api.include_router(routeur_auth)
routeur_api.include_router(routeur_enseignants)
routeur_api.include_router(routeur_academique)
routeur_api.include_router(routeur_dashboard)
routeur_api.include_router(routeur_inscriptions)
routeur_api.include_router(routeur_notes)
routeur_api.include_router(routeur_notifications)
routeur_api.include_router(routeur_valve)
routeur_api.include_router(routeur_reclamations)
routeur_api.include_router(routeur_risques)


@routeur_api.get("/statut", tags=["systeme"])
def statut_api():
    parametres = obtenir_parametres()
    return reponse_succes(
        message="API Smart Faculty en ligne",
        donnees={
            "application": parametres.app_name,
            "environnement": parametres.app_env,
            "version": "0.1.0",
        },
    )


@routeur_api.get("/sante/base-de-donnees", tags=["systeme"])
def sante_base_de_donnees():
    if verifier_connexion_mysql():
        return reponse_succes(message="Connexion MySQL operationnelle")

    return reponse_erreur(
        message="Connexion MySQL indisponible",
        erreurs=["Verifie MYSQL_HOST, MYSQL_PORT, MYSQL_DATABASE, MYSQL_USER et MYSQL_PASSWORD."],
        code_http=503,
    )
