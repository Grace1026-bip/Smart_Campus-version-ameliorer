from __future__ import annotations

import json

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import creer_access_token
from app.modeles import AnneeAcademique, EnrolementAcademique, Enseignant, Etudiant, ProjetAcademique, Utilisateur


MOT_DE_PASSE = "Smart@123456"


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _connexion(client: TestClient, email: str, role: str) -> str:
    response = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": MOT_DE_PASSE, "role": role},
    )
    assert response.status_code == 200
    return response.json()["donnees"]["access_token"]


def _references() -> tuple[int, int, int]:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        assert etudiant and annee
        return etudiant.id, etudiant.promotion_id, annee.id


def _enrolement_valide(client: TestClient, token_appariteur: str) -> int:
    etudiant_id, promotion_id, annee_id = _references()
    create = client.post(
        "/api/v1/appariteur/enrolements",
        headers=_headers(token_appariteur),
        json={
            "etudiant_id": etudiant_id,
            "promotion_id": promotion_id,
            "annee_academique_id": annee_id,
        },
    )
    assert create.status_code == 201
    enrollment_id = create.json()["donnees"]["id"]
    validate = client.post(
        f"/api/v1/appariteur/enrolements/{enrollment_id}/valider",
        headers=_headers(token_appariteur),
    )
    assert validate.status_code == 200
    return enrollment_id


def _creer_enseignant(client: TestClient, token_admin: str, suffixe: str, statut: str = "actif") -> tuple[str, int]:
    email = f"encadreur.5b.{suffixe}@smartfaculty.test"
    response = client.post(
        "/api/v1/enseignants",
        headers=_headers(token_admin),
        json={
            "utilisateur": {
                "nom": "Encadreur",
                "prenom": suffixe[-6:],
                "email": email,
                "mot_de_passe": MOT_DE_PASSE,
            },
            "matricule_agent": f"ENS-5B-{suffixe[-8:]}",
            "grade": "Assistant",
            "departement": "Informatique",
            "statut": statut,
        },
    )
    assert response.status_code == 201
    return email, response.json()["donnees"]["id"]


def _creer_projet(client: TestClient, token_appariteur: str) -> int:
    etudiant_id, _promotion_id, _annee_id = _references()
    response = client.post(
        "/api/v1/appariteur/projets",
        headers=_headers(token_appariteur),
        json={
            "etudiant_id": etudiant_id,
            "titre": "Plateforme universitaire 5B",
            "type_projet": "genie_logiciel",
            "description": "Projet de test du workflow appariteur.",
        },
    )
    assert response.status_code == 201
    return response.json()["donnees"]["id"]


def test_appariteur_cree_filtre_et_modifie_un_projet(client: TestClient, suffixe: str):
    token = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    _enrolement_valide(client, token)
    projet_id = _creer_projet(client, token)

    listing = client.get(
        "/api/v1/appariteur/projets?type_projet=genie_logiciel&sans_encadreur=true",
        headers=_headers(token),
    )
    assert listing.status_code == 200
    projet = next(item for item in listing.json()["donnees"]["elements"] if item["id"] == projet_id)
    assert projet["statut"] == "propose"
    assert projet["encadreur_principal"] is None
    assert projet["nombre_coencadreurs"] == 0

    modified = client.patch(
        f"/api/v1/appariteur/projets/{projet_id}",
        headers=_headers(token),
        json={"titre": "Plateforme universitaire modifiee"},
    )
    assert modified.status_code == 200
    assert modified.json()["donnees"]["titre"] == "Plateforme universitaire modifiee"
    assert "mot_de_passe" not in json.dumps(modified.json())
    assert "mot_de_passe_hash" not in json.dumps(modified.json())
    assert "access_token" not in json.dumps(modified.json())


def test_creation_refuse_sans_enrolement_et_doublon_actif(client: TestClient):
    token = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    etudiant_id, _promotion_id, _annee_id = _references()
    no_enrollment = client.post(
        "/api/v1/appariteur/projets",
        headers=_headers(token),
        json={"etudiant_id": etudiant_id, "titre": "Sans enrôlement", "type_projet": "reseaux"},
    )
    assert no_enrollment.status_code == 400

    _enrolement_valide(client, token)
    first = _creer_projet(client, token)
    assert first > 0
    duplicate = client.post(
        "/api/v1/appariteur/projets",
        headers=_headers(token),
        json={"etudiant_id": etudiant_id, "titre": "Doublon", "type_projet": "reseaux"},
    )
    assert duplicate.status_code == 409
    assert client.post(
        "/api/v1/appariteur/projets",
        headers=_headers(token),
        json={"etudiant_id": etudiant_id, "titre": "", "type_projet": "reseaux"},
    ).status_code == 422
    assert client.post(
        "/api/v1/appariteur/projets",
        headers=_headers(token),
        json={"etudiant_id": etudiant_id, "titre": "Type libre", "type_projet": "autre"},
    ).status_code == 422


def test_specialites_filtrent_les_enseignants_compatibles(client: TestClient, token_admin: str, suffixe: str):
    token = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    email, enseignant_id = _creer_enseignant(client, token_admin, suffixe)
    config = client.put(
        f"/api/v1/appariteur/enseignants-encadreurs/{enseignant_id}/specialites",
        headers=_headers(token),
        json={"types_projet": ["genie_logiciel", "reseaux"]},
    )
    assert config.status_code == 200
    types = {item["type_projet"] for item in config.json()["donnees"]["specialites"] if item["actif"]}
    assert types == {"genie_logiciel", "reseaux"}

    compatible = client.get(
        "/api/v1/appariteur/enseignants-encadreurs?type_projet=genie_logiciel",
        headers=_headers(token),
    )
    assert compatible.status_code == 200
    element = next(item for item in compatible.json()["donnees"]["elements"] if item["id"] == enseignant_id)
    assert "genie_logiciel" in element["types_projet_compatibles"]
    assert email not in json.dumps(element)
    assert client.get(
        "/api/v1/appariteur/enseignants-encadreurs?type_projet=type_libre",
        headers=_headers(token),
    ).status_code == 400

    duplicate = client.put(
        f"/api/v1/appariteur/enseignants-encadreurs/{enseignant_id}/specialites",
        headers=_headers(token),
        json={"types_projet": ["reseaux", "reseaux"]},
    )
    assert duplicate.status_code == 422


def test_attribution_principal_coencadreur_remplacement_et_historique(
    client: TestClient,
    token_admin: str,
    suffixe: str,
):
    appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    email_a, enseignant_a = _creer_enseignant(client, token_admin, f"a-{suffixe}")
    _email_b, enseignant_b = _creer_enseignant(client, token_admin, f"b-{suffixe}")
    for enseignant_id in (enseignant_a, enseignant_b):
        response = client.put(
            f"/api/v1/appariteur/enseignants-encadreurs/{enseignant_id}/specialites",
            headers=_headers(appariteur),
            json={"types_projet": ["genie_logiciel"]},
        )
        assert response.status_code == 200
    _enrolement_valide(client, appariteur)
    projet_id = _creer_projet(client, appariteur)

    principal = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements",
        headers=_headers(appariteur),
        json={"enseignant_id": enseignant_a, "role_encadrement": "principal"},
    )
    assert principal.status_code == 201
    co = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements",
        headers=_headers(appariteur),
        json={"enseignant_id": enseignant_b, "role_encadrement": "co_encadreur"},
    )
    assert co.status_code == 201
    assert co.json()["donnees"]["nombre_coencadreurs"] == 1

    second_principal = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements",
        headers=_headers(appariteur),
        json={"enseignant_id": enseignant_b, "role_encadrement": "principal"},
    )
    assert second_principal.status_code == 409

    replaced = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements",
        headers=_headers(appariteur),
        json={
            "enseignant_id": enseignant_b,
            "role_encadrement": "principal",
            "remplacer_principal": True,
        },
    )
    assert replaced.status_code == 409
    # A teacher cannot be both co-encadreur and principal in the same active project.
    deactivate_co = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements/{co.json()['donnees']['encadrements_actifs'][-1]['id']}/desactiver",
        headers=_headers(appariteur),
    )
    assert deactivate_co.status_code == 200
    replaced = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/encadrements",
        headers=_headers(appariteur),
        json={
            "enseignant_id": enseignant_b,
            "role_encadrement": "principal",
            "remplacer_principal": True,
        },
    )
    assert replaced.status_code == 201
    data = replaced.json()["donnees"]
    assert data["encadreur_principal"]["enseignant_id"] == enseignant_b
    assert any(item["enseignant_id"] == enseignant_a for item in data["encadrements_historiques"])

    token_a = _connexion(client, email_a, "enseignant")
    visible_a = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_a))
    assert visible_a.status_code == 200
    assert all(item["projet"]["id"] != projet_id for item in visible_a.json()["donnees"]["elements"])


def test_enseignant_inactif_ou_sans_role_refuse_et_archivage_conserve_historique(
    client: TestClient,
    token_admin: str,
    suffixe: str,
):
    appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    _email, enseignant_id = _creer_enseignant(client, token_admin, suffixe, statut="suspendu")
    assert client.put(
        f"/api/v1/appariteur/enseignants-encadreurs/{enseignant_id}/specialites",
        headers=_headers(appariteur),
        json={"types_projet": ["reseaux"]},
    ).status_code == 400
    assert client.get(
        "/api/v1/appariteur/projets",
        headers=_headers(_connexion(client, "etudiant@smartfaculty.test", "etudiant")),
    ).status_code == 403
    assert client.get("/api/v1/appariteur/projets").status_code == 401

    _enrolement_valide(client, appariteur)
    projet_id = _creer_projet(client, appariteur)
    archived = client.post(
        f"/api/v1/appariteur/projets/{projet_id}/archiver",
        headers=_headers(appariteur),
    )
    assert archived.status_code == 200
    assert archived.json()["donnees"]["statut"] == "archive"


def test_role_actif_falsifie_est_refuse(client: TestClient):
    with SessionLocale() as session:
        etudiant = session.scalar(select(Utilisateur).where(Utilisateur.email == "etudiant@smartfaculty.test"))
        assert etudiant is not None
        token = creer_access_token(str(etudiant.id), "appariteur")
    assert client.get("/api/v1/appariteur/projets", headers=_headers(token)).status_code == 401
