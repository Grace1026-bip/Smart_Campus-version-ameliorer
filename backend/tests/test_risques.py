from __future__ import annotations

from datetime import date, timedelta

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import Cours, Etudiant, Notification, TypeEvaluation


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


def _references_seed(code_cours: str = "WEB202") -> tuple[int, int]:
    with SessionLocale() as session:
        cours = session.scalar(select(Cours).where(Cours.code == code_cours))
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        assert cours is not None
        assert etudiant is not None
        return cours.id, etudiant.id


def _type_evaluation_id() -> int:
    with SessionLocale() as session:
        type_evaluation = session.scalar(select(TypeEvaluation).where(TypeEvaluation.nom == "examen"))
        assert type_evaluation is not None
        return type_evaluation.id


def _notifications_alerte(cours_id: int) -> int:
    with SessionLocale() as session:
        return len(
            session.scalars(
                select(Notification).where(
                    Notification.type_notification == "alerte_academique",
                    Notification.donnees_json["cours_id"].as_integer() == cours_id,
                )
            ).all()
        )


def test_absences_retards_declenchent_risque_visible_par_roles(client: TestClient, token_etudiant: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    headers_appariteur = {"Authorization": f"Bearer {token_appariteur}"}
    cours_id, etudiant_id = _references_seed()
    debut = date(2026, 1, 10)

    for index, statut_presence in enumerate(["absent", "absent", "retard", "absent"]):
        reponse = client.post(
            f"/api/v1/enseignant/cours/{cours_id}/presences",
            json={
                "date_seance": str(debut + timedelta(days=index)),
                "presences": [{"etudiant_id": etudiant_id, "statut": statut_presence}],
            },
            headers=headers_enseignant,
        )
        assert reponse.status_code == 201

    risques_etudiant = client.get(f"/api/v1/etudiant/cours/{cours_id}/risques", headers=headers_etudiant)
    assert risques_etudiant.status_code == 200
    risques = risques_etudiant.json()["donnees"]["risques"]
    assert len(risques) == 1
    assert risques[0]["niveau_risque"] == "moyen"
    assert risques[0]["score_risque"] >= 35
    assert any(raison["critere"] == "absences" for raison in risques[0]["raisons_detaillees"])

    risques_enseignant = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/risques?niveau=moyen",
        headers=headers_enseignant,
    )
    assert risques_enseignant.status_code == 200
    assert risques_enseignant.json()["donnees"]["total"] == 1

    risques_appariteur = client.get(f"/api/v1/risques?cours_id={cours_id}&niveau=moyen", headers=headers_appariteur)
    assert risques_appariteur.status_code == 200
    assert risques_appariteur.json()["donnees"]["total"] == 1
    assert _notifications_alerte(cours_id) >= 1


def test_publication_note_faible_recalcule_risque(client: TestClient, token_admin: str, references_academiques: tuple[int, int], suffixe: str):
    annee_id, semestre_id = references_academiques
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"L2 Risque {suffixe}",
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
            "code": f"RSK{suffixe[-5:]}",
            "intitule": "Cours Risque Pytest",
            "nombre_heures": 30,
            "nombre_credits": 4,
            "semestre_id": semestre_id,
            "promotion_id": promotion_id,
        },
        headers=headers_admin,
    )
    assert cours.status_code == 201
    cours_id = cours.json()["donnees"]["id"]

    email_enseignant = f"prof.risque.{suffixe}@smartfaculty.test"
    enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Risque",
                "postnom": "Pytest",
                "prenom": "Prof",
                "email": email_enseignant,
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-RSK-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers=headers_admin,
    )
    assert enseignant.status_code == 201
    enseignant_id = enseignant.json()["donnees"]["id"]

    email_etudiant = f"student.risque.{suffixe}@smartfaculty.test"
    etudiant = client.post(
        "/api/v1/etudiants",
        json={
            "utilisateur": {
                "nom": "Risque",
                "postnom": "Pytest",
                "prenom": "Student",
                "email": email_etudiant,
                "mot_de_passe": "Smart@123456",
            },
            "matricule": f"ST-RSK-{suffixe}",
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
            "titre": f"Examen risque {suffixe}",
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

    publication = client.post(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/publier",
        headers=headers_enseignant,
    )
    assert publication.status_code == 200

    risques = client.get(f"/api/v1/etudiant/cours/{cours_id}/risques", headers=headers_etudiant)
    assert risques.status_code == 200
    risque = risques.json()["donnees"]["risques"][0]
    assert risque["niveau_risque"] == "moyen"
    assert any(raison["critere"] == "moyenne" for raison in risque["raisons_detaillees"])
    assert _notifications_alerte(cours_id) >= 1


def test_risques_refuse_enseignant_sans_profil_ou_non_affecte(client: TestClient):
    token_doyen_enseignant = _connexion(client, "doyen@smartfaculty.test", "enseignant")
    cours_id, _etudiant_id = _references_seed()
    reponse = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/risques",
        headers={"Authorization": f"Bearer {token_doyen_enseignant}"},
    )
    assert reponse.status_code == 403
