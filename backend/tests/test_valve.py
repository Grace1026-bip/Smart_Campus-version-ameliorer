from __future__ import annotations

from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.parametres import obtenir_parametres
from app.modeles import Cours, Promotion


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


def _promotion_id(nom: str) -> int:
    with SessionLocale() as session:
        promotion = session.scalar(select(Promotion).where(Promotion.nom == nom))
        assert promotion is not None
        return promotion.id


@pytest.fixture(autouse=True)
def stockage_valve_temporaire(monkeypatch: pytest.MonkeyPatch, tmp_path):
    monkeypatch.setenv("DOSSIER_STOCKAGE_VALVE", str(tmp_path / "valve"))
    obtenir_parametres.cache_clear()
    yield
    obtenir_parametres.cache_clear()


def test_cycle_valve_publication_document_et_lecture(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    cours_id = _cours_id()
    titre = f"Support valve {suffixe}"
    contenu_pdf = b"%PDF-1.4\nSmart Faculty\n%%EOF"

    creation = client.post(
        "/api/v1/enseignant/valve/publications",
        json={
            "cours_id": cours_id,
            "type_publication": "support_de_cours",
            "titre": titre,
            "contenu": "Support du chapitre API",
            "est_importante": True,
            "publier_maintenant": False,
        },
        headers=headers_enseignant,
    )
    assert creation.status_code == 201
    publication = creation.json()["donnees"]["publication"]
    publication_id = publication["id"]
    assert publication["statut"] == "brouillon"

    invisible_avant_publication = client.get(
        f"/api/v1/etudiant/valve/cours/{cours_id}?recherche={titre}",
        headers=headers_etudiant,
    )
    assert invisible_avant_publication.status_code == 200
    assert invisible_avant_publication.json()["donnees"]["publications"]["total"] == 0

    upload = client.post(
        f"/api/v1/enseignant/valve/publications/{publication_id}/pieces-jointes",
        files={"fichier": ("support.pdf", contenu_pdf, "application/pdf")},
        headers=headers_enseignant,
    )
    assert upload.status_code == 201
    piece_id = upload.json()["donnees"]["piece_jointe"]["id"]

    publication_reussie = client.post(
        f"/api/v1/enseignant/valve/publications/{publication_id}/publier",
        headers=headers_enseignant,
    )
    assert publication_reussie.status_code == 200
    assert publication_reussie.json()["donnees"]["publication"]["statut"] == "publiee"

    liste_cours = client.get(
        f"/api/v1/etudiant/valve/cours/{cours_id}?recherche={titre}",
        headers=headers_etudiant,
    )
    assert liste_cours.status_code == 200
    publications = liste_cours.json()["donnees"]["publications"]
    assert publications["total"] == 1
    assert publications["elements"][0]["id"] == publication_id
    assert publications["elements"][0]["est_lue"] is False
    assert publications["elements"][0]["pieces_jointes"][0]["id"] == piece_id

    telechargement = client.get(
        f"/api/v1/etudiant/valve/pieces-jointes/{piece_id}/telecharger",
        headers=headers_etudiant,
    )
    assert telechargement.status_code == 200
    assert telechargement.content == contenu_pdf

    detail = client.get(f"/api/v1/etudiant/valve/publications/{publication_id}", headers=headers_etudiant)
    assert detail.status_code == 200
    assert detail.json()["donnees"]["publication"]["est_lue"] is True

    liste_apres_lecture = client.get(
        f"/api/v1/etudiant/valve/cours/{cours_id}?recherche={titre}",
        headers=headers_etudiant,
    )
    assert liste_apres_lecture.status_code == 200
    assert liste_apres_lecture.json()["donnees"]["publications"]["elements"][0]["est_lue"] is True

    archivage = client.post(
        f"/api/v1/enseignant/valve/publications/{publication_id}/archiver",
        headers=headers_enseignant,
    )
    assert archivage.status_code == 200
    assert archivage.json()["donnees"]["publication"]["statut"] == "archivee"


def test_valve_refuse_enseignant_non_affecte(client: TestClient, token_admin: str, suffixe: str):
    cours_id = _cours_id()
    email = f"prof.valve.{suffixe}@smartfaculty.test"
    creation_enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Valve",
                "postnom": "Test",
                "prenom": "Prof",
                "email": email,
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-V-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    assert creation_enseignant.status_code == 201

    token_autre_enseignant = _connexion(client, email, "enseignant")
    reponse = client.post(
        "/api/v1/enseignant/valve/publications",
        json={
            "cours_id": cours_id,
            "type_publication": "annonce",
            "titre": f"Annonce refusee {suffixe}",
            "contenu": "Cet enseignant n'est pas affecte au cours.",
        },
        headers={"Authorization": f"Bearer {token_autre_enseignant}"},
    )
    assert reponse.status_code == 403


def test_valve_refuse_etudiant_non_inscrit(client: TestClient, token_admin: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    cours_id = _cours_id()
    titre = f"Annonce privee {suffixe}"

    publication = client.post(
        "/api/v1/enseignant/valve/publications",
        json={
            "cours_id": cours_id,
            "type_publication": "annonce",
            "titre": titre,
            "contenu": "Information reservee aux inscrits.",
            "publier_maintenant": True,
        },
        headers={"Authorization": f"Bearer {token_enseignant}"},
    )
    assert publication.status_code == 201
    publication_id = publication.json()["donnees"]["publication"]["id"]

    email = f"l1.valve.{suffixe}@smartfaculty.test"
    creation_etudiant = client.post(
        "/api/v1/etudiants",
        json={
            "utilisateur": {
                "nom": "Valve",
                "postnom": "L1",
                "prenom": "Student",
                "email": email,
                "mot_de_passe": "Smart@123456",
            },
            "matricule": f"ST-V-{suffixe}",
            "promotion_id": _promotion_id("L1 Informatique"),
            "date_inscription": str(date.today()),
        },
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    assert creation_etudiant.status_code == 201

    token_autre_etudiant = _connexion(client, email, "etudiant")
    detail = client.get(
        f"/api/v1/etudiant/valve/publications/{publication_id}",
        headers={"Authorization": f"Bearer {token_autre_etudiant}"},
    )
    assert detail.status_code == 403
