import pytest
from fastapi.testclient import TestClient


@pytest.mark.parametrize(
    "origine",
    [
        "http://localhost:3000",
        "http://127.0.0.1:52123",
    ],
)
def test_prevol_local_autorise_origine_dynamique_et_headers(
    client: TestClient,
    origine: str,
):
    reponse = client.options(
        "/api/v1/auth/connexion",
        headers={
            "Origin": origine,
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type,accept",
        },
    )

    assert reponse.status_code == 200
    assert reponse.headers["access-control-allow-origin"] == origine
    assert "POST" in reponse.headers["access-control-allow-methods"]
    headers_autorises = {
        header.strip().lower()
        for header in reponse.headers["access-control-allow-headers"].split(",")
    }
    assert {"authorization", "content-type", "accept"}.issubset(headers_autorises)
    assert "access-control-allow-credentials" not in reponse.headers


def test_prevol_refuse_origine_externe(client: TestClient):
    reponse = client.options(
        "/api/v1/auth/connexion",
        headers={
            "Origin": "https://origine-externe.example",
            "Access-Control-Request-Method": "POST",
            "Access-Control-Request-Headers": "authorization,content-type",
        },
    )

    assert reponse.status_code == 400
    assert "access-control-allow-origin" not in reponse.headers


def test_requete_simple_locale_retourne_origine_sans_credentials(
    client: TestClient,
):
    origine = "http://localhost:45678"

    reponse = client.get("/", headers={"Origin": origine})

    assert reponse.status_code == 200
    assert reponse.headers["access-control-allow-origin"] == origine
    assert "access-control-allow-credentials" not in reponse.headers
