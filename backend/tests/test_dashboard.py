from __future__ import annotations

from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import TypeEvaluation


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": email,
            "mot_de_passe": "Smart@123456",
            "role": role,
        },
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _type_evaluation_id() -> int:
    with SessionLocale() as session:
        type_evaluation = session.scalar(select(TypeEvaluation).where(TypeEvaluation.nom == "examen"))
        assert type_evaluation is not None
        return type_evaluation.id


def _preparer_donnees_dashboard(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
) -> dict:
    annee_id, semestre_id = references_academiques
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"L2 Dashboard {suffixe}",
            "niveau": "L2",
            "annee_academique_id": annee_id,
        },
        headers=headers_admin,
    )
    assert promotion.status_code == 201
    promotion_id = promotion.json()["donnees"]["id"]

    cours = client.post(
        "/api/v1/cours",
        json={
            "code": f"DSH{suffixe[-5:]}",
            "intitule": "Cours Dashboard Pytest",
            "nombre_heures": 30,
            "nombre_credits": 4,
            "semestre_id": semestre_id,
            "promotion_id": promotion_id,
        },
        headers=headers_admin,
    )
    assert cours.status_code == 201
    cours_id = cours.json()["donnees"]["id"]

    email_enseignant = f"prof.dashboard.{suffixe}@smartfaculty.test"
    enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Dashboard",
                "postnom": "Pytest",
                "prenom": "Prof",
                "email": email_enseignant,
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-DSH-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers=headers_admin,
    )
    assert enseignant.status_code == 201
    enseignant_id = enseignant.json()["donnees"]["id"]

    email_etudiant = f"student.dashboard.{suffixe}@smartfaculty.test"
    etudiant = client.post(
        "/api/v1/etudiants",
        json={
            "utilisateur": {
                "nom": "Dashboard",
                "postnom": "Pytest",
                "prenom": "Student",
                "email": email_etudiant,
                "mot_de_passe": "Smart@123456",
            },
            "matricule": f"ST-DSH-{suffixe}",
            "promotion_id": promotion_id,
            "date_inscription": str(date.today()),
        },
        headers=headers_admin,
    )
    assert etudiant.status_code == 201
    etudiant_id = etudiant.json()["donnees"]["id"]

    affectation = client.post(
        f"/api/v1/cours/{cours_id}/enseignants",
        json={"enseignant_id": enseignant_id, "type_intervenant": "professeur", "est_responsable": True},
        headers=headers_admin,
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
        headers=headers_admin,
    )
    assert inscription.status_code == 201

    token_enseignant = _connexion(client, email_enseignant, "enseignant")
    token_etudiant = _connexion(client, email_etudiant, "etudiant")
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}

    evaluation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": _type_evaluation_id(),
            "titre": f"Examen dashboard {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
            "date_evaluation": str(date.today()),
        },
        headers=headers_enseignant,
    )
    assert evaluation.status_code == 201
    evaluation_id = evaluation.json()["donnees"]["evaluation"]["id"]

    encodage = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 8}]},
        headers=headers_enseignant,
    )
    assert encodage.status_code == 200

    publication = client.post(f"/api/v1/enseignant/evaluations/{evaluation_id}/publier", headers=headers_enseignant)
    assert publication.status_code == 200

    reclamation = client.post(
        "/api/v1/etudiant/reclamations",
        json={
            "categorie": "cours",
            "objet": f"Dashboard reclamation {suffixe}",
            "description": "Cette reclamation doit apparaitre dans le dashboard.",
            "cours_id": cours_id,
        },
        headers=headers_etudiant,
    )
    assert reclamation.status_code == 201

    return {
        "promotion_id": promotion_id,
        "cours_id": cours_id,
        "etudiant_id": etudiant_id,
        "token_etudiant": token_etudiant,
    }


def test_dashboard_decisionnel_agrege_les_indicateurs(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    donnees = _preparer_donnees_dashboard(client, token_admin, references_academiques, suffixe)
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    resume = client.get("/api/v1/dashboard/resume", headers=headers_admin)
    assert resume.status_code == 200
    indicateurs = resume.json()["donnees"]
    assert indicateurs["effectifs"]["etudiants"] >= 1
    assert indicateurs["effectifs"]["enseignants"] >= 1
    assert indicateurs["resultats"]["echoues"] >= 1
    assert indicateurs["risques"]["moyen"] >= 1
    assert indicateurs["reclamations"]["en_attente"] >= 1

    cours_difficiles = client.get(
        f"/api/v1/dashboard/cours-difficiles?promotion_id={donnees['promotion_id']}",
        headers=headers_admin,
    )
    assert cours_difficiles.status_code == 200
    elements_cours = cours_difficiles.json()["donnees"]["elements"]
    assert elements_cours[0]["cours"]["id"] == donnees["cours_id"]
    assert elements_cours[0]["resultats"]["echoues"] == 1
    assert elements_cours[0]["resultats"]["taux_echec"] == 100

    promotions = client.get("/api/v1/dashboard/performances-promotions", headers=headers_admin)
    assert promotions.status_code == 200
    promotion = next(
        item
        for item in promotions.json()["donnees"]["elements"]
        if item["promotion"]["id"] == donnees["promotion_id"]
    )
    assert promotion["resultats"]["echoues"] == 1
    assert promotion["risques_actifs"]["moyen"] >= 1

    reclamations = client.get("/api/v1/dashboard/reclamations", headers=headers_admin)
    assert reclamations.status_code == 200
    assert reclamations.json()["donnees"]["par_categorie"]["cours"] >= 1

    risques = client.get("/api/v1/dashboard/risques?niveau=moyen", headers=headers_admin)
    assert risques.status_code == 200
    assert any(item["cours_id"] == donnees["cours_id"] for item in risques.json()["donnees"]["top_risques"])


def test_dashboard_refuse_role_etudiant(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    donnees = _preparer_donnees_dashboard(client, token_admin, references_academiques, f"{suffixe}x")
    reponse = client.get(
        "/api/v1/dashboard/resume",
        headers={"Authorization": f"Bearer {donnees['token_etudiant']}"},
    )
    assert reponse.status_code == 403
