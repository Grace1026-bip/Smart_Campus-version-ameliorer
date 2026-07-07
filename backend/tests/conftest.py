from __future__ import annotations

import sys
from pathlib import Path
from time import time

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.parametres import obtenir_parametres
from app.main import app
from app.modeles import AnneeAcademique, Semestre


@pytest.fixture(scope="session", autouse=True)
def verifier_base_test():
    parametres = obtenir_parametres()
    assert parametres.mysql_database.endswith("_test"), (
        "Les tests doivent utiliser une base separee finissant par '_test'. "
        f"Base actuelle: {parametres.mysql_database}"
    )


@pytest.fixture()
def client() -> TestClient:
    return TestClient(app)


@pytest.fixture()
def suffixe() -> str:
    return str(int(time() * 1000))


@pytest.fixture()
def token_admin(client: TestClient) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "admin@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "administrateur",
        },
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


@pytest.fixture()
def token_etudiant(client: TestClient) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


@pytest.fixture()
def references_academiques() -> tuple[int, int]:
    with SessionLocale() as session:
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        semestre = session.scalar(select(Semestre).order_by(Semestre.id))
        assert annee is not None
        assert semestre is not None
        return annee.id, semestre.id
