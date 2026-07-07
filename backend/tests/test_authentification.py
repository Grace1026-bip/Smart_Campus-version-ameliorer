from __future__ import annotations

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import hacher_mot_de_passe
from app.modeles import Role, Utilisateur, UtilisateurRole


def test_connexion_reussie_et_moi(client: TestClient):
    connexion = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert connexion.status_code == 200
    donnees = connexion.json()["donnees"]
    assert donnees["utilisateur"]["email"] == "etudiant@smartfaculty.test"
    assert donnees["role_actif"] == "etudiant"

    moi = client.get(
        "/api/v1/auth/moi",
        headers={"Authorization": f"Bearer {donnees['access_token']}"},
    )
    assert moi.status_code == 200
    assert moi.json()["donnees"]["role_actif"] == "etudiant"


def test_connexion_echouee_mot_de_passe(client: TestClient):
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "incorrect",
            "role": "etudiant",
        },
    )
    assert reponse.status_code == 401


def test_compte_bloque_refuse(client: TestClient, suffixe: str):
    email = f"bloque.{suffixe}@smartfaculty.test"
    with SessionLocale() as session:
        role = session.scalar(select(Role).where(Role.nom == "etudiant"))
        assert role is not None
        utilisateur = Utilisateur(
            nom="Bloque",
            postnom=None,
            prenom="Test",
            email=email,
            mot_de_passe_hash=hacher_mot_de_passe("Smart@123456"),
            statut="bloque",
        )
        session.add(utilisateur)
        session.flush()
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))
        session.commit()

    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": email,
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert reponse.status_code == 403


def test_acces_sans_token_refuse(client: TestClient):
    reponse = client.get("/api/v1/auth/moi")
    assert reponse.status_code == 401


def test_acces_avec_mauvais_role_refuse(client: TestClient):
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "enseignant",
        },
    )
    assert reponse.status_code == 401


def test_actualisation_et_deconnexion(client: TestClient):
    connexion = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert connexion.status_code == 200
    refresh_token = connexion.json()["donnees"]["refresh_token"]

    actualisation = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": refresh_token, "role": "etudiant"},
    )
    assert actualisation.status_code == 200
    nouveaux_jetons = actualisation.json()["donnees"]

    reutilisation = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": refresh_token, "role": "etudiant"},
    )
    assert reutilisation.status_code == 401

    deconnexion = client.post(
        "/api/v1/auth/deconnexion",
        json={"refresh_token": nouveaux_jetons["refresh_token"]},
        headers={"Authorization": f"Bearer {nouveaux_jetons['access_token']}"},
    )
    assert deconnexion.status_code == 200

    apres_deconnexion = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": nouveaux_jetons["refresh_token"], "role": "etudiant"},
    )
    assert apres_deconnexion.status_code == 401


def test_changement_mot_de_passe_et_restauration(client: TestClient):
    connexion = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert connexion.status_code == 200
    access_token = connexion.json()["donnees"]["access_token"]

    changement = client.put(
        "/api/v1/auth/mot-de-passe",
        json={
            "ancien_mot_de_passe": "Smart@123456",
            "nouveau_mot_de_passe": "Smart@123456Temp",
        },
        headers={"Authorization": f"Bearer {access_token}"},
    )
    assert changement.status_code == 200

    ancien_refuse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    assert ancien_refuse.status_code == 401

    nouveau = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456Temp",
            "role": "etudiant",
        },
    )
    assert nouveau.status_code == 200

    restauration = client.put(
        "/api/v1/auth/mot-de-passe",
        json={
            "ancien_mot_de_passe": "Smart@123456Temp",
            "nouveau_mot_de_passe": "Smart@123456",
        },
        headers={"Authorization": f"Bearer {nouveau.json()['donnees']['access_token']}"},
    )
    assert restauration.status_code == 200
