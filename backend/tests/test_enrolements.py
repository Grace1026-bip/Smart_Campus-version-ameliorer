from __future__ import annotations

from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import AnneeAcademique, Etudiant


@pytest.fixture()
def token_appariteur(client: TestClient) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "appariteur@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "appariteur",
        },
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


@pytest.fixture()
def references_enrolement() -> tuple[int, int, int]:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).order_by(Etudiant.id))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        assert etudiant is not None
        assert annee is not None
        return etudiant.id, etudiant.promotion_id, annee.id


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _creer(client: TestClient, token: str, references: tuple[int, int, int]):
    etudiant_id, promotion_id, annee_id = references
    return client.post(
        "/api/v1/appariteur/enrolements",
        json={
            "etudiant_id": etudiant_id,
            "promotion_id": promotion_id,
            "annee_academique_id": annee_id,
            "date_enrolement": str(date.today()),
        },
        headers=_headers(token),
    )


def test_appariteur_liste_et_cree_un_enrolement_sans_donnee_sensible(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    creation = _creer(client, token_appariteur, references_enrolement)
    assert creation.status_code == 201
    donnees = creation.json()["donnees"]
    assert donnees["statut"] == "en_attente"
    assert donnees["reference_fiche"].startswith("ENR-")
    assert "mot_de_passe" not in donnees
    assert "email" not in donnees["etudiant"]

    liste = client.get(
        "/api/v1/appariteur/enrolements?statut=en_attente",
        headers=_headers(token_appariteur),
    )
    assert liste.status_code == 200
    assert liste.json()["donnees"]["total"] == 1
    assert liste.json()["donnees"]["elements"][0]["id"] == donnees["id"]


def test_enrolements_refusent_absence_de_token_et_autres_roles(
    client: TestClient,
    token_etudiant: str,
    token_admin: str,
):
    assert client.get("/api/v1/appariteur/enrolements").status_code == 401
    assert client.get(
        "/api/v1/appariteur/enrolements",
        headers=_headers(token_etudiant),
    ).status_code == 403
    assert client.get(
        "/api/v1/appariteur/enrolements",
        headers=_headers(token_admin),
    ).status_code == 403


def test_creation_refuse_references_inexistantes(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    etudiant_id, promotion_id, annee_id = references_enrolement
    assert _creer(client, token_appariteur, (999999, promotion_id, annee_id)).status_code == 404
    assert _creer(client, token_appariteur, (etudiant_id, 999999, annee_id)).status_code == 404
    assert _creer(client, token_appariteur, (etudiant_id, promotion_id, 999999)).status_code == 404


def test_doublon_actif_et_reference_backend_sont_controles(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    premier = _creer(client, token_appariteur, references_enrolement)
    assert premier.status_code == 201
    second = _creer(client, token_appariteur, references_enrolement)
    assert second.status_code == 409


def test_validation_est_idempotente_et_bloque_la_modification_sensible(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    creation = _creer(client, token_appariteur, references_enrolement)
    identifiant = creation.json()["donnees"]["id"]
    url = f"/api/v1/appariteur/enrolements/{identifiant}"

    validation = client.post(f"{url}/valider", headers=_headers(token_appariteur))
    assert validation.status_code == 200
    assert validation.json()["donnees"]["statut"] == "valide"

    seconde_validation = client.post(f"{url}/valider", headers=_headers(token_appariteur))
    assert seconde_validation.status_code == 200
    modification = client.patch(
        url,
        json={"promotion_id": references_enrolement[1] + 1},
        headers=_headers(token_appariteur),
    )
    assert modification.status_code == 409


def test_annulation_conserve_historique_et_libere_le_triplet(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    premier = _creer(client, token_appariteur, references_enrolement)
    identifiant = premier.json()["donnees"]["id"]
    annulation = client.post(
        f"/api/v1/appariteur/enrolements/{identifiant}/annuler",
        json={"motif": "Correction administrative"},
        headers=_headers(token_appariteur),
    )
    assert annulation.status_code == 200
    assert annulation.json()["donnees"]["statut"] == "annule"

    second = _creer(client, token_appariteur, references_enrolement)
    assert second.status_code == 201
    historique = client.get(
        "/api/v1/appariteur/enrolements",
        headers=_headers(token_appariteur),
    )
    assert historique.status_code == 200
    assert historique.json()["donnees"]["total"] == 2


def test_detail_fiche_et_filtres_retournent_le_programme(
    client: TestClient,
    token_appariteur: str,
    references_enrolement: tuple[int, int, int],
):
    creation = _creer(client, token_appariteur, references_enrolement)
    identifiant = creation.json()["donnees"]["id"]
    url = f"/api/v1/appariteur/enrolements/{identifiant}"
    assert client.post(f"{url}/valider", headers=_headers(token_appariteur)).status_code == 200

    detail = client.get(url, headers=_headers(token_appariteur))
    assert detail.status_code == 200
    donnees = detail.json()["donnees"]
    assert "programme" in donnees
    assert "credits_prevus" in donnees

    fiche = client.get(f"{url}/fiche/donnees", headers=_headers(token_appariteur))
    assert fiche.status_code == 200
    assert fiche.json()["donnees"]["reference_fiche"] == donnees["reference_fiche"]

    recherche = client.get(
        f"/api/v1/appariteur/enrolements?recherche={donnees['etudiant']['matricule']}",
        headers=_headers(token_appariteur),
    )
    assert recherche.status_code == 200
    assert recherche.json()["donnees"]["total"] == 1


def test_liste_etudiant_inconnue_et_statut_invalide_sont_refuses(
    client: TestClient,
    token_appariteur: str,
):
    statut = client.get(
        "/api/v1/appariteur/enrolements?statut=inconnu",
        headers=_headers(token_appariteur),
    )
    assert statut.status_code == 400
    etudiant = client.get(
        "/api/v1/appariteur/etudiants/999999/enrolements",
        headers=_headers(token_appariteur),
    )
    assert etudiant.status_code == 404
