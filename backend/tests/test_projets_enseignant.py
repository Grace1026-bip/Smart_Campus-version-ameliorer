from __future__ import annotations

import json

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import creer_access_token
from app.modeles import AnneeAcademique, EncadrementProjet, Etudiant, Enseignant, ProjetAcademique, Utilisateur


MOT_DE_PASSE = "Smart@123456"


def _headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": MOT_DE_PASSE, "role": role},
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _creer_enseignant(client: TestClient, token_admin: str, suffixe: str, statut: str = "actif") -> tuple[str, int, int]:
    email = f"encadreur.4d.{suffixe}@smartfaculty.test"
    reponse = client.post(
        "/api/v1/enseignants",
        headers=_headers(token_admin),
        json={
            "utilisateur": {
                "nom": "Encadreur",
                "postnom": "Test",
                "prenom": suffixe[-6:],
                "email": email,
                "mot_de_passe": MOT_DE_PASSE,
            },
            "matricule_agent": f"ENS-4D-{suffixe[-8:]}",
            "grade": "Assistant",
            "departement": "Informatique",
            "statut": statut,
        },
    )
    assert reponse.status_code == 201
    enseignant_id = reponse.json()["donnees"]["id"]
    with SessionLocale() as session:
        enseignant = session.get(Enseignant, enseignant_id)
        assert enseignant is not None
        return email, enseignant.id, enseignant.utilisateur_id


def _creer_projet(enseignant_ids: list[int], suffixe: str, type_projet: str = "genie_logiciel") -> tuple[int, list[int]]:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        appariteur = session.scalar(select(Utilisateur).where(Utilisateur.email == "appariteur@smartfaculty.test"))
        assert etudiant and annee and appariteur
        projet = ProjetAcademique(
            etudiant_id=etudiant.id,
            titre=f"Projet enseignant {suffixe}",
            type_projet=type_projet,
            description="Description pedagogique minimale.",
            promotion_id=etudiant.promotion_id,
            annee_academique_id=annee.id,
            statut="en_cours",
        )
        session.add(projet)
        session.flush()
        for index, enseignant_id in enumerate(enseignant_ids):
            session.add(
                EncadrementProjet(
                    projet_id=projet.id,
                    enseignant_id=enseignant_id,
                    attribue_par_utilisateur_id=appariteur.id,
                    role_encadrement="principal" if index == 0 else "coencadreur",
                    actif=True,
                )
            )
        session.commit()
        return projet.id, list(enseignant_ids)


def _encadrement_id(projet_id: int, enseignant_id: int) -> int:
    with SessionLocale() as session:
        encadrement = session.scalar(
            select(EncadrementProjet).where(
                EncadrementProjet.projet_id == projet_id,
                EncadrementProjet.enseignant_id == enseignant_id,
            )
        )
        assert encadrement is not None
        return encadrement.id


def test_enseignant_voit_ses_encadrements_et_le_detail(client: TestClient, suffixe: str):
    with SessionLocale() as session:
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert enseignant is not None
        enseignant_id = enseignant.id
    projet_id, _ = _creer_projet([enseignant_id], suffixe, "reseaux")
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")

    liste = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token))
    assert liste.status_code == 200
    elements = liste.json()["donnees"]["elements"]
    element = next(item for item in elements if item["projet"]["id"] == projet_id)
    assert element["type_projet"] == "reseaux"
    assert element["type_projet_libelle"] == "Reseaux"
    assert element["etudiant"]["matricule"] == "SF-L2-0001"
    assert element["role_encadrement"] == "principal"

    detail = client.get(
        f"/api/v1/enseignants/moi/encadrements/{element['id']}",
        headers=_headers(token),
    )
    assert detail.status_code == 200
    assert detail.json()["donnees"]["projet"]["id"] == projet_id


def test_enseignant_sans_encadrement_obtient_liste_vide(client: TestClient, token_admin: str, suffixe: str):
    email, _enseignant_id, _utilisateur_id = _creer_enseignant(client, token_admin, suffixe)
    token = _connexion(client, email, "enseignant")
    reponse = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token))
    assert reponse.status_code == 200
    assert reponse.json()["donnees"] == {"elements": [], "total": 0}


def test_enseignant_a_ne_voit_pas_les_projets_de_b(client: TestClient, token_admin: str, suffixe: str):
    email_b, enseignant_b, _ = _creer_enseignant(client, token_admin, suffixe)
    projet_id, _ = _creer_projet([enseignant_b], f"b-{suffixe}")
    token_a = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    liste = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_a))
    assert liste.status_code == 200
    assert all(item["projet"]["id"] != projet_id for item in liste.json()["donnees"]["elements"])
    token_b = _connexion(client, email_b, "enseignant")
    assert any(
        item["projet"]["id"] == projet_id
        for item in client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_b)).json()["donnees"]["elements"]
    )


def test_encadrements_refusent_absence_de_token_et_autre_role(client: TestClient, token_etudiant: str):
    assert client.get("/api/v1/enseignants/moi/encadrements").status_code == 401
    assert client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_etudiant)).status_code == 403


def test_role_actif_falsifie_et_compte_enseignant_inactif_refuses(client: TestClient, token_admin: str, suffixe: str):
    with SessionLocale() as session:
        etudiant = session.scalar(select(Utilisateur).where(Utilisateur.email == "etudiant@smartfaculty.test"))
        assert etudiant is not None
        token_falsifie = creer_access_token(str(etudiant.id), "enseignant")
    email, _enseignant_id, _ = _creer_enseignant(client, token_admin, suffixe, statut="suspendu")
    token_inactif = _connexion(client, email, "enseignant")
    assert client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_falsifie)).status_code == 401
    assert client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_inactif)).status_code == 403


def test_encadrement_non_attribue_est_introuvable(client: TestClient, token_admin: str, suffixe: str):
    email_b, _enseignant_b, _ = _creer_enseignant(client, token_admin, suffixe)
    with SessionLocale() as session:
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert enseignant is not None
    projet_id, _ = _creer_projet([enseignant.id], suffixe)
    encadrement_id = _encadrement_id(projet_id, enseignant.id)
    token_b = _connexion(client, email_b, "enseignant")
    assert client.get(f"/api/v1/enseignants/moi/encadrements/{encadrement_id}", headers=_headers(token_b)).status_code == 404


@pytest.mark.parametrize("type_projet", ["reseaux", "systemes_embarques", "intelligence_artificielle", "genie_logiciel"])
def test_types_projets_controles(client: TestClient, suffixe: str, type_projet: str):
    with SessionLocale() as session:
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert enseignant is not None
    _creer_projet([enseignant.id], f"{type_projet}-{suffixe}", type_projet)
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    reponse = client.get(f"/api/v1/enseignants/moi/encadrements?type_projet={type_projet}", headers=_headers(token))
    assert reponse.status_code == 200
    assert all(item["type_projet"] == type_projet for item in reponse.json()["donnees"]["elements"])
    invalide = client.get("/api/v1/enseignants/moi/encadrements?type_projet=arbitraire", headers=_headers(token))
    assert invalide.status_code == 400


def test_plusieurs_encadreurs_sans_doublon_et_sans_donnee_sensible(client: TestClient, token_admin: str, suffixe: str):
    email_b, enseignant_b, _ = _creer_enseignant(client, token_admin, suffixe)
    with SessionLocale() as session:
        enseignant_a = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert enseignant_a is not None
    projet_id, _ = _creer_projet([enseignant_a.id, enseignant_b], suffixe)
    token_a = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    liste = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token_a))
    element = next(item for item in liste.json()["donnees"]["elements"] if item["projet"]["id"] == projet_id)
    assert len(element["autres_encadreurs"]) == 1
    contenu = json.dumps(element)
    assert "mot_de_passe" not in contenu
    assert "mot_de_passe_hash" not in contenu
    assert "access_token" not in contenu
    assert email_b not in contenu


def test_filtres_backend_par_type_statut_annee_et_recherche(client: TestClient, suffixe: str):
    with SessionLocale() as session:
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        assert enseignant and annee
    _creer_projet([enseignant.id], suffixe, "systemes_embarques")
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    url = "/api/v1/enseignants/moi/encadrements?type_projet=systemes_embarques&statut=en_cours&annee_academique_id=" f"{annee.id}&recherche=Projet"
    reponse = client.get(url, headers=_headers(token))
    assert reponse.status_code == 200
    assert all(item["type_projet"] == "systemes_embarques" for item in reponse.json()["donnees"]["elements"])
    assert client.get("/api/v1/enseignants/moi/encadrements?statut=invalide", headers=_headers(token)).status_code == 400


def test_encadrement_inactif_n_est_plus_visible(client: TestClient, suffixe: str):
    with SessionLocale() as session:
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert enseignant is not None
    projet_id, _ = _creer_projet([enseignant.id], suffixe)
    with SessionLocale() as session:
        encadrement = session.scalar(select(EncadrementProjet).where(EncadrementProjet.projet_id == projet_id, EncadrementProjet.enseignant_id == enseignant.id))
        assert encadrement is not None
        encadrement.actif = False
        session.commit()
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    reponse = client.get("/api/v1/enseignants/moi/encadrements", headers=_headers(token))
    assert reponse.status_code == 200
    assert all(item["projet"]["id"] != projet_id for item in reponse.json()["donnees"]["elements"])
