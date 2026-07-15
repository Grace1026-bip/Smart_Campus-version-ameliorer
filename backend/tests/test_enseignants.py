from __future__ import annotations

import json

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import creer_access_token
from app.modeles import Role, Utilisateur, UtilisateurRole


MOT_DE_PASSE = "Smart@123456"


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": MOT_DE_PASSE, "role": role},
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _creer_enseignant(client: TestClient, token_admin: str, suffixe: str, statut: str = "actif") -> tuple[str, int]:
    email = f"enseignant.4ar.{suffixe}@smartfaculty.test"
    reponse = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Test",
                "postnom": "Compte",
                "prenom": "Enseignant",
                "email": email,
                "mot_de_passe": MOT_DE_PASSE,
            },
            "matricule_agent": f"ENS-4AR-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
            "statut": statut,
        },
        headers=_headers(token_admin),
    )
    assert reponse.status_code == 201
    return email, reponse.json()["donnees"]["id"]


def _creer_cours(client: TestClient, token_admin: str, references: tuple[int, int], suffixe: str) -> int:
    annee_id, semestre_id = references
    promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"Promotion 4AR {suffixe}",
            "niveau": "L4",
            "annee_academique_id": annee_id,
        },
        headers=_headers(token_admin),
    )
    assert promotion.status_code == 201
    cours = client.post(
        "/api/v1/cours",
        json={
            "code": f"4AR{suffixe[-5:]}",
            "intitule": "Cours enseignant de controle",
            "nombre_heures": 30,
            "nombre_credits": 3,
            "semestre_id": semestre_id,
            "promotion_id": promotion.json()["donnees"]["id"],
        },
        headers=_headers(token_admin),
    )
    assert cours.status_code == 201
    return cours.json()["donnees"]["id"]


def _ajouter_role(email: str, role_nom: str) -> None:
    with SessionLocale() as session:
        utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == email))
        role = session.scalar(select(Role).where(Role.nom == role_nom))
        assert utilisateur is not None
        assert role is not None
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))
        session.commit()


def test_enseignant_accede_a_son_profil_sans_donnee_sensible(client: TestClient):
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")

    reponse = client.get("/api/v1/enseignants/moi", headers=_headers(token))

    assert reponse.status_code == 200
    profil = reponse.json()["donnees"]
    assert profil["role_actif"] == "enseignant"
    assert profil["matricule_agent"]
    contenu = json.dumps(profil)
    assert "mot_de_passe" not in contenu
    assert "mot_de_passe_hash" not in contenu
    assert "access_token" not in contenu
    assert "refresh_token" not in contenu


def test_acces_enseignant_refuse_sans_token_et_avec_autre_role(client: TestClient, token_etudiant: str):
    sans_token = client.get("/api/v1/enseignants/moi")
    avec_autre_role = client.get(
        "/api/v1/enseignants/moi",
        headers=_headers(token_etudiant),
    )

    assert sans_token.status_code == 401
    assert avec_autre_role.status_code == 403


def test_role_actif_falsifie_et_compte_non_actif_sont_refuses(
    client: TestClient,
    token_admin: str,
    suffixe: str,
):
    with SessionLocale() as session:
        etudiant = session.scalar(select(Utilisateur).where(Utilisateur.email == "etudiant@smartfaculty.test"))
        assert etudiant is not None
        token_falsifie = creer_access_token(str(etudiant.id), "enseignant")

    email, _ = _creer_enseignant(client, token_admin, suffixe, statut="suspendu")
    token_non_actif = _connexion(client, email, "enseignant")

    assert client.get("/api/v1/enseignants/moi", headers=_headers(token_falsifie)).status_code == 403
    assert client.get("/api/v1/enseignants/moi", headers=_headers(token_non_actif)).status_code == 403


def test_enseignant_ne_voit_que_ses_cours_et_son_detail(
    client: TestClient,
    token_admin: str,
    references_academiques: tuple[int, int],
    suffixe: str,
):
    email_autre, enseignant_id = _creer_enseignant(client, token_admin, suffixe)
    cours_autre_id = _creer_cours(client, token_admin, references_academiques, suffixe)
    affectation = client.post(
        f"/api/v1/cours/{cours_autre_id}/enseignants",
        json={"enseignant_id": enseignant_id, "type_intervenant": "professeur"},
        headers=_headers(token_admin),
    )
    assert affectation.status_code == 201

    token_principal = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    token_autre = _connexion(client, email_autre, "enseignant")
    liste_principale = client.get(
        "/api/v1/enseignants/moi/cours", headers=_headers(token_principal)
    )
    liste_autre = client.get(
        "/api/v1/enseignants/moi/cours", headers=_headers(token_autre)
    )

    assert liste_principale.status_code == 200
    assert liste_autre.status_code == 200
    codes_principaux = {item["code"] for item in liste_principale.json()["donnees"]["elements"]}
    cours_autre = liste_autre.json()["donnees"]["elements"]
    assert cours_autre and cours_autre[0]["id"] == cours_autre_id
    assert cours_autre[0]["code"] not in codes_principaux

    cours_principal_id = liste_principale.json()["donnees"]["elements"][0]["id"]
    assert client.get(
        f"/api/v1/enseignants/moi/cours/{cours_principal_id}",
        headers=_headers(token_principal),
    ).status_code == 200
    assert client.get(
        f"/api/v1/enseignants/moi/cours/{cours_autre_id}",
        headers=_headers(token_principal),
    ).status_code == 404


def test_enseignant_sans_cours_retourne_une_liste_vide(
    client: TestClient,
    token_admin: str,
    suffixe: str,
):
    email, _ = _creer_enseignant(client, token_admin, suffixe)
    token = _connexion(client, email, "enseignant")

    reponse = client.get("/api/v1/enseignants/moi/cours", headers=_headers(token))

    assert reponse.status_code == 200
    assert reponse.json()["donnees"] == {"elements": [], "total": 0}


def test_multi_role_accepte_enseignant_actif_et_refuse_autre_role(
    client: TestClient,
    token_admin: str,
    suffixe: str,
):
    email, _ = _creer_enseignant(client, token_admin, suffixe)
    _ajouter_role(email, "doyen")

    token_enseignant = _connexion(client, email, "enseignant")
    token_doyen = _connexion(client, email, "doyen")

    assert client.get(
        "/api/v1/enseignants/moi", headers=_headers(token_enseignant)
    ).status_code == 200
    assert client.get(
        "/api/v1/enseignants/moi", headers=_headers(token_doyen)
    ).status_code == 403


def test_cours_retourne_promotion_annee_et_donnees_essentielles(client: TestClient):
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    reponse = client.get("/api/v1/enseignants/moi/cours", headers=_headers(token))

    assert reponse.status_code == 200
    cours = reponse.json()["donnees"]["elements"][0]
    assert cours["code"]
    assert cours["intitule"]
    assert cours["promotion"]["nom"]
    assert cours["promotion"]["annee_academique"]["id"] == cours["semestre"]["annee_academique"]["id"]
    assert cours["credits"] > 0
    assert cours["nombre_heures"] > 0
