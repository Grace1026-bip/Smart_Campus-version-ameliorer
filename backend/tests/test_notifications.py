from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import Cours


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


def _publier_annonce_valve(client: TestClient, token_enseignant: str, titre: str) -> None:
    cours_id = _cours_id()
    reponse = client.post(
        "/api/v1/enseignant/valve/publications",
        json={
            "cours_id": cours_id,
            "type_publication": "annonce",
            "titre": titre,
            "contenu": "Notification generee par la valve academique.",
            "publier_maintenant": True,
        },
        headers={"Authorization": f"Bearer {token_enseignant}"},
    )
    assert reponse.status_code == 201


def test_notifications_consultation_compteur_et_lecture(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}

    _publier_annonce_valve(client, token_enseignant, f"Notification A {suffixe}")
    _publier_annonce_valve(client, token_enseignant, f"Notification B {suffixe}")

    compteur = client.get("/api/v1/notifications/non-lues/compteur", headers=headers_etudiant)
    assert compteur.status_code == 200
    assert compteur.json()["donnees"]["total_non_lues"] >= 2
    assert compteur.json()["donnees"]["par_type"]["nouvelle_publication"] >= 2

    liste_non_lues = client.get(
        "/api/v1/notifications?est_lue=false&type_notification=nouvelle_publication",
        headers=headers_etudiant,
    )
    assert liste_non_lues.status_code == 200
    donnees_liste = liste_non_lues.json()["donnees"]
    assert donnees_liste["total"] >= 2
    notification_id = donnees_liste["elements"][0]["id"]
    assert donnees_liste["elements"][0]["est_lue"] is False

    lecture = client.post(f"/api/v1/notifications/{notification_id}/lire", headers=headers_etudiant)
    assert lecture.status_code == 200
    notification_lue = lecture.json()["donnees"]["notification"]
    assert notification_lue["id"] == notification_id
    assert notification_lue["est_lue"] is True
    assert notification_lue["lue_le"] is not None

    compteur_apres_une_lecture = client.get("/api/v1/notifications/non-lues/compteur", headers=headers_etudiant)
    assert compteur_apres_une_lecture.status_code == 200
    assert compteur_apres_une_lecture.json()["donnees"]["total_non_lues"] >= 1

    tout_lire = client.post("/api/v1/notifications/tout-lire", headers=headers_etudiant)
    assert tout_lire.status_code == 200
    assert tout_lire.json()["donnees"]["nombre_mises_a_jour"] >= 1

    compteur_final = client.get("/api/v1/notifications/non-lues/compteur", headers=headers_etudiant)
    assert compteur_final.status_code == 200
    assert compteur_final.json()["donnees"]["total_non_lues"] == 0


def test_notifications_refuse_acces_a_celle_dun_autre_utilisateur(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    token_admin = _connexion(client, "admin@smartfaculty.test", "administrateur")
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    headers_admin = {"Authorization": f"Bearer {token_admin}"}

    _publier_annonce_valve(client, token_enseignant, f"Notification privee {suffixe}")

    liste = client.get("/api/v1/notifications?est_lue=false", headers=headers_etudiant)
    assert liste.status_code == 200
    notification_id = liste.json()["donnees"]["elements"][0]["id"]

    tentative_admin = client.post(f"/api/v1/notifications/{notification_id}/lire", headers=headers_admin)
    assert tentative_admin.status_code == 404
