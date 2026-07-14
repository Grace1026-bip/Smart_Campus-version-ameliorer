from __future__ import annotations

from fastapi.testclient import TestClient


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _connexion(client: TestClient, email: str, role: str) -> str:
    response = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": "Smart@123456", "role": role},
    )
    assert response.status_code == 200
    return response.json()["donnees"]["access_token"]


def test_tableau_de_bord_etudiant_ne_contient_que_des_donnees_reelles(client: TestClient, token_etudiant: str):
    response = client.get("/api/v1/etudiants/moi/tableau-de-bord", headers=_headers(token_etudiant))
    assert response.status_code == 200
    data = response.json()["donnees"]
    assert data["profil"]["matricule"]
    assert data["profil"]["promotion"]
    assert isinstance(data["nombre_cours"], int)
    assert "moyenne_generale" not in data
    assert "risques" not in data
    assert "presences" not in data
    assert "mot_de_passe" not in str(data).lower()


def test_etudiant_cours_et_historique_sont_limites_a_son_perimetre(client: TestClient, token_etudiant: str):
    headers = _headers(token_etudiant)
    courses = client.get("/api/v1/etudiants/moi/cours", headers=headers)
    assert courses.status_code == 200
    data = courses.json()["donnees"]
    assert isinstance(data["cours"], list)
    for card in data["cours"]:
        course = card["cours"]
        assert course["promotion"] == data["promotion"]["nom"]
        assert course["annee_academique"] == data["annee_academique"]["libelle"]
        assert "enseignant_id" not in str(card)

    history = client.get("/api/v1/etudiants/moi/historique-academique", headers=headers)
    assert history.status_code == 200
    assert isinstance(history.json()["donnees"]["groupes"], list)


def test_detail_cours_refuse_un_cours_hors_inscription(client: TestClient, token_etudiant: str):
    response = client.get("/api/v1/etudiants/moi/cours/999999", headers=_headers(token_etudiant))
    assert response.status_code == 404


def test_nouvelles_routes_etudiant_refusent_absence_de_token_et_autre_role(client: TestClient, token_admin: str):
    assert client.get("/api/v1/etudiants/moi/tableau-de-bord").status_code == 401
    assert client.get(
        "/api/v1/etudiants/moi/historique-academique",
        headers=_headers(token_admin),
    ).status_code == 403
