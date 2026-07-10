from __future__ import annotations

import io
import sys
from contextlib import redirect_stdout
from pathlib import Path

import pymysql
from alembic import command
from alembic.config import Config
from sqlalchemy import text

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.configuration.parametres import obtenir_parametres


BASE_TEST_OFFICIELLE = "smart_faculty_test"
HOTE_TEST_OFFICIEL = "127.0.0.1"
PORT_TEST_OFFICIEL = 3307


def verifier_cible() -> None:
    parametres = obtenir_parametres()
    cible_valide = (
        parametres.mysql_host == HOTE_TEST_OFFICIEL
        and parametres.mysql_port == PORT_TEST_OFFICIEL
        and parametres.mysql_database == BASE_TEST_OFFICIELLE
        and parametres.mysql_database.endswith("_test")
    )
    if not cible_valide:
        raise RuntimeError(
            "Reinitialisation refusee: la cible doit etre exactement "
            f"{HOTE_TEST_OFFICIEL}:{PORT_TEST_OFFICIEL}/{BASE_TEST_OFFICIELLE}."
        )


def recreer_base() -> None:
    parametres = obtenir_parametres()
    connexion = pymysql.connect(
        host=parametres.mysql_host,
        port=parametres.mysql_port,
        user=parametres.mysql_user,
        password=parametres.mysql_password,
        charset="utf8mb4",
        autocommit=True,
    )
    try:
        with connexion.cursor() as curseur:
            curseur.execute(f"DROP DATABASE IF EXISTS `{BASE_TEST_OFFICIELLE}`")
            curseur.execute(
                f"CREATE DATABASE `{BASE_TEST_OFFICIELLE}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci"
            )
    finally:
        connexion.close()


def appliquer_migrations() -> None:
    racine_backend = Path(__file__).resolve().parents[1]
    configuration = Config(str(racine_backend / "alembic.ini"))
    configuration.set_main_option("script_location", str(racine_backend / "alembic"))
    command.upgrade(configuration, "head")


def appliquer_donnees_initiales() -> None:
    from scripts.creer_donnees_initiales import creer_donnees_initiales

    # Le seed historique affiche le mot de passe commun; la preparation officielle
    # garde cette information hors de la sortie des tests.
    with redirect_stdout(io.StringIO()):
        creer_donnees_initiales()


def obtenir_revision() -> str:
    from app.base_de_donnees.connexion import moteur

    with moteur.connect() as connexion:
        return str(connexion.execute(text("SELECT version_num FROM alembic_version")).scalar_one())


def main() -> None:
    verifier_cible()
    print(f"Cible verifiee: {HOTE_TEST_OFFICIEL}:{PORT_TEST_OFFICIEL}/{BASE_TEST_OFFICIELLE}")
    recreer_base()
    appliquer_migrations()
    appliquer_donnees_initiales()
    print(f"Base de test prete; revision Alembic: {obtenir_revision()}")


if __name__ == "__main__":
    main()
