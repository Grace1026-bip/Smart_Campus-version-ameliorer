from __future__ import annotations

import json

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import delete, select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import creer_access_token, hacher_jeton, hacher_mot_de_passe
from app.modeles import JetonActualisation, Role, Utilisateur, UtilisateurRole


MOT_DE_PASSE_TEST = "Smart@123456"


def _creer_utilisateur(
    email: str,
    roles: list[str],
    statut: str = "actif",
) -> Utilisateur:
    with SessionLocale() as session:
        utilisateur = Utilisateur(
            nom="Authentification",
            postnom=None,
            prenom="Test",
            email=email,
            mot_de_passe_hash=hacher_mot_de_passe(MOT_DE_PASSE_TEST),
            statut=statut,
        )
        session.add(utilisateur)
        session.flush()
        for nom_role in roles:
            role = session.scalar(select(Role).where(Role.nom == nom_role))
            if role is None:
                role = Role(nom=nom_role, description=f"Role de test {nom_role}")
                session.add(role)
                session.flush()
            session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role.id))
        session.commit()
        session.refresh(utilisateur)
        return utilisateur


def _connecter(client: TestClient, email: str, role: str, mot_de_passe: str = MOT_DE_PASSE_TEST):
    return client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": mot_de_passe, "role": role},
    )


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


@pytest.mark.parametrize("role", ["chef_promotion", "surveillant", "vice_doyen"])
def test_connexion_roles_fonctionnels_pris_en_charge(client: TestClient, suffixe: str, role: str):
    email = f"{role}.{suffixe}@smartfaculty.test"
    _creer_utilisateur(email, [role])

    reponse = _connecter(client, email, role)

    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["role_actif"] == role


@pytest.mark.parametrize("statut", ["en_attente", "bloque", "rejete", "archive"])
def test_seul_statut_actif_autorise_connexion(client: TestClient, suffixe: str, statut: str):
    email = f"statut.{statut}.{suffixe}@smartfaculty.test"
    _creer_utilisateur(email, ["etudiant"], statut=statut)

    reponse = _connecter(client, email, "etudiant")

    assert reponse.status_code == 403


def test_email_connexion_est_normalise(client: TestClient):
    reponse = _connecter(client, "  ETUDIANT@SMARTFACULTY.TEST  ", "etudiant")

    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["utilisateur"]["email"] == "etudiant@smartfaculty.test"


def test_reponse_connexion_exclut_mot_de_passe_et_hash(client: TestClient):
    reponse = _connecter(client, "etudiant@smartfaculty.test", "etudiant")

    assert reponse.status_code == 200
    contenu = json.dumps(reponse.json())
    assert MOT_DE_PASSE_TEST not in contenu
    assert "mot_de_passe" not in contenu
    assert "mot_de_passe_hash" not in contenu


def test_refresh_token_est_stocke_uniquement_sous_forme_hachee(client: TestClient):
    reponse = _connecter(client, "etudiant@smartfaculty.test", "etudiant")
    assert reponse.status_code == 200
    refresh_token = reponse.json()["donnees"]["refresh_token"]

    with SessionLocale() as session:
        jeton = session.scalar(
            select(JetonActualisation).where(JetonActualisation.jeton_hash == hacher_jeton(refresh_token))
        )
        assert jeton is not None
        assert jeton.jeton_hash != refresh_token


def test_access_token_expire_est_refuse(client: TestClient):
    token = creer_access_token("3", "etudiant", expiration_minutes=-1)

    reponse = client.get("/api/v1/auth/moi", headers={"Authorization": f"Bearer {token}"})

    assert reponse.status_code == 401


def test_access_token_modifie_est_refuse(client: TestClient):
    connexion = _connecter(client, "etudiant@smartfaculty.test", "etudiant")
    token = connexion.json()["donnees"]["access_token"]
    entete, contenu, signature = token.split(".")
    premier = "a" if signature[0] != "a" else "b"
    token_modifie = f"{entete}.{contenu}.{premier}{signature[1:]}"

    reponse = client.get(
        "/api/v1/auth/moi",
        headers={"Authorization": f"Bearer {token_modifie}"},
    )

    assert reponse.status_code == 401


def test_access_token_refuse_si_utilisateur_supprime(client: TestClient, suffixe: str):
    email = f"supprime.{suffixe}@smartfaculty.test"
    utilisateur = _creer_utilisateur(email, ["etudiant"])
    connexion = _connecter(client, email, "etudiant")
    token = connexion.json()["donnees"]["access_token"]

    with SessionLocale() as session:
        utilisateur_persistant = session.get(Utilisateur, utilisateur.id)
        assert utilisateur_persistant is not None
        session.delete(utilisateur_persistant)
        session.commit()

    reponse = client.get("/api/v1/auth/moi", headers={"Authorization": f"Bearer {token}"})

    assert reponse.status_code == 401


def test_access_token_refuse_si_role_retire(client: TestClient, suffixe: str):
    email = f"role.retire.{suffixe}@smartfaculty.test"
    utilisateur = _creer_utilisateur(email, ["etudiant"])
    connexion = _connecter(client, email, "etudiant")
    token = connexion.json()["donnees"]["access_token"]

    with SessionLocale() as session:
        session.execute(delete(UtilisateurRole).where(UtilisateurRole.utilisateur_id == utilisateur.id))
        session.commit()

    reponse = client.get("/api/v1/auth/moi", headers={"Authorization": f"Bearer {token}"})

    assert reponse.status_code == 401


def test_role_flutter_falsifie_est_refuse_par_backend(client: TestClient):
    reponse = _connecter(client, "etudiant@smartfaculty.test", "administrateur")

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
