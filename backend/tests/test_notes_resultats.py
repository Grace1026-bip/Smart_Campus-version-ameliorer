from __future__ import annotations

from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import Cours, Etudiant, TypeEvaluation


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


def _references_notes(code_cours: str = "BD201") -> tuple[int, int, int]:
    with SessionLocale() as session:
        cours = session.scalar(select(Cours).where(Cours.code == code_cours))
        type_evaluation = session.scalar(select(TypeEvaluation).where(TypeEvaluation.nom == "examen"))
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        assert cours is not None
        assert type_evaluation is not None
        assert etudiant is not None
        return cours.id, type_evaluation.id, etudiant.id


def test_cycle_notes_publication_resultats_etudiant(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes()

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Examen pytest {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
            "date_evaluation": str(date.today()),
        },
        headers=headers_enseignant,
    )
    assert creation.status_code == 201
    evaluation = creation.json()["donnees"]["evaluation"]
    evaluation_id = evaluation["id"]
    assert evaluation["statut"] == "brouillon"

    notes_avant_publication = client.get("/api/v1/etudiant/notes", headers=headers_etudiant)
    assert notes_avant_publication.status_code == 200
    assert all(
        ligne["evaluation"]["id"] != evaluation_id
        for ligne in notes_avant_publication.json()["donnees"]["notes"]
    )

    encodage = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={
            "notes": [
                {
                    "etudiant_id": etudiant_id,
                    "note_obtenue": 16,
                    "commentaire": "Bonne maitrise",
                }
            ]
        },
        headers=headers_enseignant,
    )
    assert encodage.status_code == 200
    assert encodage.json()["donnees"]["notes"][0]["note_obtenue"] == 16

    publication = client.post(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/publier",
        json={"confirmer_notes_manquantes": False},
        headers=headers_enseignant,
    )
    assert publication.status_code == 200
    assert publication.json()["donnees"]["evaluation"]["statut"] == "publiee"

    notes_publiees = client.get(f"/api/v1/etudiant/cours/{cours_id}/notes", headers=headers_etudiant)
    assert notes_publiees.status_code == 200
    lignes_notes = notes_publiees.json()["donnees"]["notes"]
    assert any(ligne["evaluation"]["id"] == evaluation_id for ligne in lignes_notes)

    resultats = client.get("/api/v1/etudiant/resultats", headers=headers_etudiant)
    assert resultats.status_code == 200
    ligne_resultat = next(
        resultat for resultat in resultats.json()["donnees"]["resultats"] if resultat["cours_id"] == cours_id
    )
    assert ligne_resultat["moyenne"] == 80
    assert ligne_resultat["statut_resultat"] == "reussi"
    assert ligne_resultat["credits_obtenus"] == 5

    verrouillage = client.post(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/verrouiller",
        headers=headers_enseignant,
    )
    assert verrouillage.status_code == 200
    assert verrouillage.json()["donnees"]["evaluation"]["est_verrouillee"] is True

    modification_apres_publication = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 18}]},
        headers=headers_enseignant,
    )
    assert modification_apres_publication.status_code == 403


def test_notes_refuse_note_superieure_au_maximum(client: TestClient, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token_enseignant}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes("WEB202")

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Controle maximum {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
        },
        headers=headers,
    )
    assert creation.status_code == 201
    evaluation_id = creation.json()["donnees"]["evaluation"]["id"]

    encodage = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 21}]},
        headers=headers,
    )
    assert encodage.status_code == 400
    assert "note maximale" in encodage.json()["message"]


def test_enseignant_non_affecte_ou_sans_profil_refuse(client: TestClient, suffixe: str):
    token_doyen_enseignant = _connexion(client, "doyen@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token_doyen_enseignant}"}
    cours_id, type_evaluation_id, _etudiant_id = _references_notes()

    reponse = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Refus profil {suffixe}",
            "note_maximale": 20,
            "ponderation": 10,
        },
        headers=headers,
    )
    assert reponse.status_code == 403
