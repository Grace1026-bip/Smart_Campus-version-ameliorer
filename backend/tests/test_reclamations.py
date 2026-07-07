from __future__ import annotations

from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import Cours, Notification, Reclamation


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


def _cours_id(code_cours: str = "WEB202") -> int:
    with SessionLocale() as session:
        cours = session.scalar(select(Cours).where(Cours.code == code_cours))
        assert cours is not None
        return cours.id


def _notifications_reclamation(reclamation_id: int) -> int:
    with SessionLocale() as session:
        return len(
            session.scalars(
                select(Notification).where(
                    Notification.type_notification == "reclamation_mise_a_jour",
                    Notification.donnees_json["reclamation_id"].as_integer() == reclamation_id,
                )
            ).all()
        )


def test_cycle_reclamation_creation_traitement_et_suivi(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    cours_id = _cours_id()
    objet = f"Erreur horaire reclamation {suffixe}"

    creation = client.post(
        "/api/v1/etudiant/reclamations",
        json={
            "categorie": "cours",
            "objet": objet,
            "description": "La consigne du cours semble contradictoire avec la valve.",
            "cours_id": cours_id,
            "priorite": "normale",
        },
        headers=headers_etudiant,
    )
    assert creation.status_code == 201
    reclamation = creation.json()["donnees"]["reclamation"]
    reclamation_id = reclamation["id"]
    assert reclamation["statut"] == "en_attente"
    assert reclamation["cours_id"] == cours_id

    liste_etudiant = client.get("/api/v1/etudiant/reclamations", headers=headers_etudiant)
    assert liste_etudiant.status_code == 200
    assert any(item["id"] == reclamation_id for item in liste_etudiant.json()["donnees"]["elements"])

    liste_enseignant = client.get(
        f"/api/v1/reclamations?statut=en_attente&recherche={objet}",
        headers=headers_enseignant,
    )
    assert liste_enseignant.status_code == 200
    assert liste_enseignant.json()["donnees"]["total"] == 1

    message = client.post(
        f"/api/v1/reclamations/{reclamation_id}/messages",
        json={"message": "Nous analysons votre dossier.", "est_interne": False},
        headers=headers_enseignant,
    )
    assert message.status_code == 201
    assert message.json()["donnees"]["message"]["est_interne"] is False

    traitement = client.put(
        f"/api/v1/reclamations/{reclamation_id}/traitement",
        json={
            "statut": "resolue",
            "commentaire": "Consigne clarifiee par l'enseignant.",
            "reponse_etudiant": "La consigne corrigee est maintenant disponible.",
        },
        headers=headers_enseignant,
    )
    assert traitement.status_code == 200
    reclamation_traitee = traitement.json()["donnees"]["reclamation"]
    assert reclamation_traitee["statut"] == "resolue"
    assert reclamation_traitee["resolue_le"] is not None

    detail_etudiant = client.get(f"/api/v1/etudiant/reclamations/{reclamation_id}", headers=headers_etudiant)
    assert detail_etudiant.status_code == 200
    detail = detail_etudiant.json()["donnees"]["reclamation"]
    assert detail["statut"] == "resolue"
    assert any(message["message"] == "La consigne corrigee est maintenant disponible." for message in detail["messages"])
    assert all(message["est_interne"] is False for message in detail["messages"])
    assert _notifications_reclamation(reclamation_id) >= 2


def test_reclamation_refuse_cours_non_inscrit_et_erreur_note_sans_note(client: TestClient, token_etudiant: str, suffixe: str):
    headers = {"Authorization": f"Bearer {token_etudiant}"}

    cours_non_inscrit = client.post(
        "/api/v1/etudiant/reclamations",
        json={
            "categorie": "cours",
            "objet": f"Cours non inscrit {suffixe}",
            "description": "Je ne devrais pas pouvoir reclamer sur ce cours.",
            "cours_id": _cours_id("ALGO101"),
        },
        headers=headers,
    )
    assert cours_non_inscrit.status_code == 403

    erreur_note_sans_note = client.post(
        "/api/v1/etudiant/reclamations",
        json={
            "categorie": "erreur_note",
            "objet": f"Erreur note sans reference {suffixe}",
            "description": "Cette reclamation doit obligatoirement referencer une note.",
        },
        headers=headers,
    )
    assert erreur_note_sans_note.status_code == 422


def test_reclamation_refuse_enseignant_non_affecte(client: TestClient, token_admin: str, token_etudiant: str, suffixe: str):
    cours_id = _cours_id()
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}

    creation = client.post(
        "/api/v1/etudiant/reclamations",
        json={
            "categorie": "cours",
            "objet": f"Reclamation privee {suffixe}",
            "description": "Seuls les responsables du cours doivent voir cette reclamation.",
            "cours_id": cours_id,
        },
        headers=headers_etudiant,
    )
    assert creation.status_code == 201
    reclamation_id = creation.json()["donnees"]["reclamation"]["id"]

    email = f"prof.reclamation.{suffixe}@smartfaculty.test"
    creation_enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Reclamation",
                "postnom": "Test",
                "prenom": "Prof",
                "email": email,
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-R-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    assert creation_enseignant.status_code == 201

    token_autre_enseignant = _connexion(client, email, "enseignant")
    detail = client.get(
        f"/api/v1/reclamations/{reclamation_id}",
        headers={"Authorization": f"Bearer {token_autre_enseignant}"},
    )
    assert detail.status_code == 403

    with SessionLocale() as session:
        assert session.scalar(select(Reclamation).where(Reclamation.id == reclamation_id)) is not None
