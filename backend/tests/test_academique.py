from __future__ import annotations

from datetime import date

from fastapi.testclient import TestClient


def test_protection_mauvais_role_sur_creation_promotion(
    client: TestClient,
    token_etudiant: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    annee_id, _semestre_id = references_academiques
    reponse = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"Refus {suffixe}",
            "niveau": "L0",
            "annee_academique_id": annee_id,
        },
        headers={"Authorization": f"Bearer {token_etudiant}"},
    )
    assert reponse.status_code == 403


def test_creation_promotion_et_cours(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    annee_id, semestre_id = references_academiques
    headers = {"Authorization": f"Bearer {token_admin}"}

    promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"L3 Pytest {suffixe}",
            "niveau": "L3",
            "annee_academique_id": annee_id,
            "description": "Promotion pytest",
        },
        headers=headers,
    )
    assert promotion.status_code == 201
    promotion_id = promotion.json()["donnees"]["id"]

    liste = client.get("/api/v1/promotions?page=1&taille=5&recherche=Pytest", headers=headers)
    assert liste.status_code == 200
    assert liste.json()["donnees"]["total"] >= 1

    cours = client.post(
        "/api/v1/cours",
        json={
            "code": f"PYT{suffixe[-5:]}",
            "intitule": "Cours Pytest",
            "nombre_heures": 30,
            "nombre_credits": 3,
            "semestre_id": semestre_id,
            "promotion_id": promotion_id,
        },
        headers=headers,
    )
    assert cours.status_code == 201
    cours_id = cours.json()["donnees"]["id"]

    modification = client.put(
        f"/api/v1/cours/{cours_id}",
        json={"nombre_heures": 36, "nombre_credits": 4},
        headers=headers,
    )
    assert modification.status_code == 200
    assert modification.json()["donnees"]["nombre_heures"] == 36


def test_creation_enseignant_affectation_etudiant_inscription(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    annee_id, semestre_id = references_academiques
    headers = {"Authorization": f"Bearer {token_admin}"}

    promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"L2 Inscription {suffixe}",
            "niveau": "L2",
            "annee_academique_id": annee_id,
        },
        headers=headers,
    )
    assert promotion.status_code == 201
    promotion_id = promotion.json()["donnees"]["id"]

    cours = client.post(
        "/api/v1/cours",
        json={
            "code": f"INS{suffixe[-5:]}",
            "intitule": "Cours Inscription",
            "nombre_heures": 45,
            "nombre_credits": 4,
            "semestre_id": semestre_id,
            "promotion_id": promotion_id,
        },
        headers=headers,
    )
    assert cours.status_code == 201
    cours_id = cours.json()["donnees"]["id"]

    enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Pytest",
                "postnom": "E",
                "prenom": "Prof",
                "email": f"prof.{suffixe}@smartfaculty.test",
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-PY-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers=headers,
    )
    assert enseignant.status_code == 201
    enseignant_id = enseignant.json()["donnees"]["id"]

    etudiant = client.post(
        "/api/v1/etudiants",
        json={
            "utilisateur": {
                "nom": "Pytest",
                "postnom": "E",
                "prenom": "Student",
                "email": f"student.{suffixe}@smartfaculty.test",
                "mot_de_passe": "Smart@123456",
            },
            "matricule": f"ST-PY-{suffixe}",
            "promotion_id": promotion_id,
            "date_inscription": str(date.today()),
        },
        headers=headers,
    )
    assert etudiant.status_code == 201
    etudiant_id = etudiant.json()["donnees"]["id"]

    affectation = client.post(
        f"/api/v1/cours/{cours_id}/enseignants",
        json={
            "enseignant_id": enseignant_id,
            "type_intervenant": "professeur",
            "est_responsable": True,
        },
        headers=headers,
    )
    assert affectation.status_code == 201

    inscription = client.post(
        "/api/v1/inscriptions-cours",
        json={
            "etudiant_id": etudiant_id,
            "cours_id": cours_id,
            "annee_academique_id": annee_id,
            "date_inscription": str(date.today()),
        },
        headers=headers,
    )
    assert inscription.status_code == 201
    inscription_id = inscription.json()["donnees"]["id"]

    retrait = client.delete(f"/api/v1/inscriptions-cours/{inscription_id}", headers=headers)
    assert retrait.status_code == 200
    assert retrait.json()["donnees"]["statut"] == "retiree"
