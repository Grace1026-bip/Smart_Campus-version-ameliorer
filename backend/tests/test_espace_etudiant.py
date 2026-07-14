from __future__ import annotations

from datetime import date
from time import time

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import creer_access_token
from app.modeles import (
    AnneeAcademique,
    EncadrementProjet,
    Enseignant,
    Etudiant,
    ProjetAcademique,
    Promotion,
    Utilisateur,
)


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


def _references(client: TestClient) -> tuple[int, int, int, int]:
    with SessionLocale() as session:
        premier = session.scalar(
            select(Etudiant)
            .join(Etudiant.utilisateur)
            .where(Utilisateur.email == "etudiant@smartfaculty.test")
        )
        second = session.scalar(
            select(Etudiant)
            .where(Etudiant.id != (premier.id if premier else 0))
            .order_by(Etudiant.id)
        )
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        appariteur = session.scalar(select(Utilisateur).where(Utilisateur.email == "appariteur@smartfaculty.test"))
        assert premier and annee and appariteur
        premier_id = premier.id
        promotion_id = premier.promotion_id
        annee_id = annee.id
        second_id = second.id if second is not None else None
    if second_id is None:
        token_admin = _connexion(client, "admin@smartfaculty.test", "administrateur")
        suffixe = int(time() * 1000)
        creation = client.post(
            "/api/v1/etudiants",
            headers=_headers(token_admin),
            json={
                "utilisateur": {
                    "nom": "Second",
                    "postnom": "Test",
                    "prenom": "Etudiant",
                    "email": f"second.etudiant.{suffixe}@smartfaculty.test",
                    "mot_de_passe": MOT_DE_PASSE,
                },
                "matricule": f"ST-SECOND-{suffixe}",
                "promotion_id": promotion_id,
                "date_inscription": str(date.today()),
            },
        )
        assert creation.status_code == 201
        second_id = creation.json()["donnees"]["id"]
    return premier_id, second_id, promotion_id, annee_id


def _creer_enrolement(client: TestClient, token_appariteur: str, etudiant_id: int) -> int:
    _etudiant_id, _second_id, promotion_id, annee_id = _references(client)
    if etudiant_id != _etudiant_id:
        with SessionLocale() as session:
            etudiant = session.get(Etudiant, etudiant_id)
            assert etudiant is not None
            promotion_id = etudiant.promotion_id
            promotion = session.get(Promotion, promotion_id)
            assert promotion is not None
            annee_id = promotion.annee_academique_id
    reponse = client.post(
        "/api/v1/appariteur/enrolements",
        headers=_headers(token_appariteur),
        json={
            "etudiant_id": etudiant_id,
            "promotion_id": promotion_id,
            "annee_academique_id": annee_id,
            "date_enrolement": "2026-07-14",
        },
    )
    assert reponse.status_code == 201
    return reponse.json()["donnees"]["id"]


def _creer_projet(etudiant_id: int, enseignant_ids: list[int], suffixe: str) -> int:
    with SessionLocale() as session:
        etudiant = session.get(Etudiant, etudiant_id)
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        appariteur = session.scalar(select(Utilisateur).where(Utilisateur.email == "appariteur@smartfaculty.test"))
        assert etudiant and annee and appariteur
        projet = ProjetAcademique(
            etudiant_id=etudiant.id,
            titre=f"Projet etudiant {suffixe}",
            type_projet="genie_logiciel",
            description="Description visible par l etudiant.",
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
        return projet.id


def _enseignant_ids(client: TestClient) -> list[int]:
    with SessionLocale() as session:
        enseignants = session.scalars(select(Enseignant).order_by(Enseignant.id)).all()
        if len(enseignants) >= 2:
            return [item.id for item in enseignants]
    token_admin = _connexion(client, "admin@smartfaculty.test", "administrateur")
    creation = client.post(
        "/api/v1/enseignants",
        headers=_headers(token_admin),
        json={
            "utilisateur": {
                "nom": "Second",
                "postnom": "Test",
                "prenom": "Enseignant",
                "email": f"second.enseignant.{int(time() * 1000)}@smartfaculty.test",
                "mot_de_passe": MOT_DE_PASSE,
            },
            "matricule_agent": f"ENS-SECOND-{int(time() * 1000)}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
    )
    assert creation.status_code == 201
    with SessionLocale() as session:
        enseignants = session.scalars(select(Enseignant).order_by(Enseignant.id)).all()
        return [item.id for item in enseignants]


def test_etudiant_liste_ses_enrolements_sans_donnees_internes(client: TestClient):
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    premier_id, second_id, _promotion_id, _annee_id = _references(client)
    enrolement = _creer_enrolement(client, token_appariteur, premier_id)
    _creer_enrolement(client, token_appariteur, second_id)
    token_etudiant = _connexion(client, "etudiant@smartfaculty.test", "etudiant")

    reponse = client.get("/api/v1/etudiants/moi/enrolements", headers=_headers(token_etudiant))
    assert reponse.status_code == 200
    elements = reponse.json()["donnees"]
    assert [item["id"] for item in elements] == [enrolement]
    assert "appariteur_responsable_id" not in elements[0]
    assert "mot_de_passe" not in str(elements[0]).lower()
    assert elements[0]["fiche_disponible"] is False


def test_etudiant_statuts_et_fiche_seulement_apres_validation(client: TestClient):
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    premier_id, _second_id, _promotion_id, _annee_id = _references(client)
    en_attente = _creer_enrolement(client, token_appariteur, premier_id)
    annule = client.post(
        f"/api/v1/appariteur/enrolements/{en_attente}/annuler",
        headers=_headers(token_appariteur),
        json={"motif": "Correction de fiche"},
    )
    assert annule.status_code == 200
    valide = _creer_enrolement(client, token_appariteur, premier_id)
    validation = client.post(
        f"/api/v1/appariteur/enrolements/{valide}/valider",
        headers=_headers(token_appariteur),
    )
    assert validation.status_code == 200
    token_etudiant = _connexion(client, "etudiant@smartfaculty.test", "etudiant")

    attente = client.get(f"/api/v1/etudiants/moi/enrolements/{en_attente}", headers=_headers(token_etudiant))
    assert attente.status_code == 200
    assert attente.json()["donnees"]["statut"] == "annule"
    valide_detail = client.get(f"/api/v1/etudiants/moi/enrolements/{valide}", headers=_headers(token_etudiant))
    assert valide_detail.status_code == 200
    assert valide_detail.json()["donnees"]["fiche_disponible"] is True
    assert valide_detail.json()["donnees"]["credits_prevus"] >= 0

    fiche = client.get(f"/api/v1/etudiants/moi/enrolements/{valide}/fiche", headers=_headers(token_etudiant))
    assert fiche.status_code == 200
    assert fiche.headers["content-type"].startswith("application/pdf")
    assert "attachment" in fiche.headers["content-disposition"]
    assert fiche.headers["cache-control"] == "private, no-store"
    assert fiche.content.startswith(b"%PDF-")
    assert len(fiche.content) > 500
    assert MOT_DE_PASSE.encode() not in fiche.content

    fiche_annulee = client.get(f"/api/v1/etudiants/moi/enrolements/{en_attente}/fiche", headers=_headers(token_etudiant))
    assert fiche_annulee.status_code == 409


def test_etudiant_ne_voit_pas_enrolement_d_un_autre_compte(client: TestClient):
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    premier_id, second_id, _promotion_id, _annee_id = _references(client)
    _creer_enrolement(client, token_appariteur, second_id)
    token_etudiant = _connexion(client, "etudiant@smartfaculty.test", "etudiant")

    liste = client.get("/api/v1/etudiants/moi/enrolements", headers=_headers(token_etudiant))
    assert liste.status_code == 200
    assert liste.json()["donnees"] == []
    assert client.get("/api/v1/etudiants/moi/enrolements/999999", headers=_headers(token_etudiant)).status_code == 404
    assert premier_id != second_id


def test_routes_etudiant_refusent_roles_absents_et_falsifies(client: TestClient, token_admin: str):
    assert client.get("/api/v1/etudiants/moi/enrolements").status_code == 401
    assert client.get("/api/v1/etudiants/moi/projets", headers=_headers(token_admin)).status_code == 403
    with SessionLocale() as session:
        utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == "etudiant@smartfaculty.test"))
        assert utilisateur is not None
        token_falsifie = creer_access_token(str(utilisateur.id), "appariteur")
    assert client.get("/api/v1/etudiants/moi/projets", headers=_headers(token_falsifie)).status_code == 401


def test_etudiant_voit_son_projet_et_encadreurs_actifs(client: TestClient, suffixe: str):
    with SessionLocale() as session:
        etudiant = session.scalar(
            select(Etudiant)
            .join(Etudiant.utilisateur)
            .where(Utilisateur.email == "etudiant@smartfaculty.test")
        )
        assert etudiant
    enseignants = _enseignant_ids(client)
    projet_id = _creer_projet(etudiant.id, [enseignants[0], enseignants[1]], suffixe)
    token = _connexion(client, "etudiant@smartfaculty.test", "etudiant")

    liste = client.get("/api/v1/etudiants/moi/projets", headers=_headers(token))
    assert liste.status_code == 200
    projet = next(item for item in liste.json()["donnees"]["elements"] if item["id"] == projet_id)
    assert projet["type_projet"] == "genie_logiciel"
    assert projet["nombre_encadreurs"] == 2
    assert {item["role_encadrement"] for item in projet["encadreurs"]} == {"principal", "co_encadreur"}
    assert "attribue_par_utilisateur_id" not in str(projet)
    assert "desactive_par_utilisateur_id" not in str(projet)

    detail = client.get(f"/api/v1/etudiants/moi/projets/{projet_id}", headers=_headers(token))
    assert detail.status_code == 200
    encadreurs = client.get(f"/api/v1/etudiants/moi/projets/{projet_id}/encadreurs", headers=_headers(token))
    assert encadreurs.status_code == 200
    assert len(encadreurs.json()["donnees"]["encadreurs"]) == 2


def test_etudiant_ne_voit_pas_le_projet_d_un_autre_etudiant(client: TestClient, suffixe: str):
    premier_id, second_id, _promotion_id, _annee_id = _references(client)
    enseignants = _enseignant_ids(client)
    projet_id = _creer_projet(second_id, [enseignants[0]], suffixe)
    token = _connexion(client, "etudiant@smartfaculty.test", "etudiant")
    assert client.get(f"/api/v1/etudiants/moi/projets/{projet_id}", headers=_headers(token)).status_code == 404
    assert premier_id != second_id


def test_projet_sans_encadreur_et_encadrement_inactif_sont_exclus(client: TestClient, suffixe: str):
    premier_id, _second_id, _promotion_id, _annee_id = _references(client)
    enseignants = _enseignant_ids(client)
    with SessionLocale() as session:
        appariteur = session.scalar(select(Utilisateur).where(Utilisateur.email == "appariteur@smartfaculty.test"))
        assert appariteur
    projet_id = _creer_projet(premier_id, [enseignants[0]], suffixe)
    with SessionLocale() as session:
        session.add(
            EncadrementProjet(
                projet_id=projet_id,
                enseignant_id=enseignants[1],
                attribue_par_utilisateur_id=appariteur.id,
                role_encadrement="coencadreur",
                actif=False,
            )
        )
        session.commit()
    projet_vide = _creer_projet(premier_id, [], f"vide-{suffixe}")
    token = _connexion(client, "etudiant@smartfaculty.test", "etudiant")
    liste = client.get("/api/v1/etudiants/moi/projets", headers=_headers(token))
    assert liste.status_code == 200
    elements = {item["id"]: item for item in liste.json()["donnees"]["elements"]}
    assert elements[projet_id]["nombre_encadreurs"] == 1
    assert elements[projet_vide]["encadreurs"] == []
