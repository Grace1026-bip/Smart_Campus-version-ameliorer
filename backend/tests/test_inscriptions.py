from __future__ import annotations

import json
from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import hacher_mot_de_passe, verifier_mot_de_passe
from app.modeles import DemandeInscription, Enseignant, Etudiant, Promotion, Role, Utilisateur, UtilisateurRole


MOT_DE_PASSE = "Smart@123456"


def _payload_etudiant(suffixe: str, **extras):
    donnees = {
        "type_demande": "etudiant",
        "email": f"demande.etudiant.{suffixe}@smartfaculty.test",
        "mot_de_passe": MOT_DE_PASSE,
        "nom": "Demande",
        "prenom": "Etudiant",
        "matricule": f"SF-D-{suffixe}",
        "promotion_id": _promotion_id(),
    }
    donnees.update(extras)
    return donnees


def _payload_enseignant(suffixe: str, **extras):
    donnees = {
        "type_demande": "enseignant",
        "email": f"demande.enseignant.{suffixe}@smartfaculty.test",
        "mot_de_passe": MOT_DE_PASSE,
        "nom": "Demande",
        "prenom": "Enseignant",
        "matricule_agent": f"ENS-D-{suffixe}",
        "grade": "Assistant",
        "departement": "Informatique",
    }
    donnees.update(extras)
    return donnees


def _promotion_id() -> int:
    with SessionLocale() as session:
        promotion = session.scalar(select(Promotion).where(Promotion.est_active.is_(True)).order_by(Promotion.id))
        assert promotion is not None
        return promotion.id


def _connecter(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": MOT_DE_PASSE, "role": role},
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _creer_demande(client: TestClient, payload: dict) -> dict:
    reponse = client.post("/api/v1/inscriptions/demandes", json=payload)
    assert reponse.status_code == 201
    return reponse.json()["donnees"]


def _creer_chef_promotion(suffixe: str, promotion_id: int) -> str:
    email = f"chef.approbation.{suffixe}@smartfaculty.test"
    with SessionLocale() as session:
        role_etudiant = session.scalar(select(Role).where(Role.nom == "etudiant"))
        role_chef = session.scalar(select(Role).where(Role.nom == "chef_promotion"))
        assert role_etudiant is not None
        assert role_chef is not None
        utilisateur = Utilisateur(
            nom="Chef",
            postnom=None,
            prenom="Promotion",
            email=email,
            mot_de_passe_hash=hacher_mot_de_passe(MOT_DE_PASSE),
            statut="actif",
        )
        session.add(utilisateur)
        session.flush()
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role_etudiant.id))
        session.add(UtilisateurRole(utilisateur_id=utilisateur.id, role_id=role_chef.id))
        session.add(
            Etudiant(
                utilisateur_id=utilisateur.id,
                matricule=f"CHEF-{suffixe}",
                promotion_id=promotion_id,
                date_inscription=date(2025, 10, 10),
                statut_academique="actif",
            )
        )
        session.commit()
    return email


def test_creation_demande_etudiant_valide(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_etudiant(suffixe))

    assert donnees["statut"] == "en_attente"
    assert donnees["type_demande"] == "etudiant"
    assert "mot_de_passe" not in json.dumps(donnees)
    assert "hash" not in json.dumps(donnees)


def test_creation_demande_enseignant_valide(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_enseignant(suffixe))

    assert donnees["statut"] == "en_attente"
    assert donnees["type_demande"] == "enseignant"


def test_refus_role_public_interdit(client: TestClient, suffixe: str):
    reponse = client.post("/api/v1/inscriptions/demandes", json=_payload_etudiant(suffixe, type_demande="doyen"))

    assert reponse.status_code == 422


def test_refus_email_invalide(client: TestClient, suffixe: str):
    reponse = client.post("/api/v1/inscriptions/demandes", json=_payload_etudiant(suffixe, email="invalid"))

    assert reponse.status_code == 422


def test_email_normalise_et_mot_de_passe_hache(client: TestClient, suffixe: str):
    email = f"  MIXTE.{suffixe}@SMARTFACULTY.TEST  "
    donnees = _creer_demande(client, _payload_etudiant(suffixe, email=email))

    assert donnees["email"] == f"mixte.{suffixe}@smartfaculty.test"
    with SessionLocale() as session:
        demande = session.scalar(select(DemandeInscription).where(DemandeInscription.reference == donnees["reference"]))
        assert demande is not None
        assert demande.mot_de_passe_hash != MOT_DE_PASSE
        assert verifier_mot_de_passe(MOT_DE_PASSE, demande.mot_de_passe_hash)


def test_refus_email_deja_utilise_par_compte(client: TestClient, suffixe: str):
    reponse = client.post(
        "/api/v1/inscriptions/demandes",
        json=_payload_etudiant(suffixe, email="etudiant@smartfaculty.test"),
    )

    assert reponse.status_code == 409


def test_refus_demande_dupliquee(client: TestClient, suffixe: str):
    payload = _payload_etudiant(suffixe)
    _creer_demande(client, payload)
    reponse = client.post("/api/v1/inscriptions/demandes", json=payload)

    assert reponse.status_code == 409


def test_refus_matricule_deja_utilise(client: TestClient, suffixe: str):
    reponse = client.post(
        "/api/v1/inscriptions/demandes",
        json=_payload_etudiant(suffixe, matricule="SF-L2-0001"),
    )

    assert reponse.status_code == 409


def test_consultation_statut_securisee(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_etudiant(suffixe))

    statut = client.get(
        "/api/v1/inscriptions/demandes/statut",
        params={"reference": donnees["reference"], "email": donnees["email"]},
    )
    autre_email = client.get(
        "/api/v1/inscriptions/demandes/statut",
        params={"reference": donnees["reference"], "email": "autre@smartfaculty.test"},
    )

    assert statut.status_code == 200
    assert statut.json()["donnees"]["statut"] == "en_attente"
    assert "mot_de_passe" not in json.dumps(statut.json())
    assert autre_email.status_code == 404


def test_approbation_etudiant_par_appariteur_cree_compte_role_et_profil(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_etudiant(suffixe))
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")

    approbation = client.post(
        f"/api/v1/inscriptions/demandes/{donnees['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    )
    connexion = client.post(
        "/api/v1/auth/connexion",
        json={"email": donnees["email"], "mot_de_passe": MOT_DE_PASSE, "role": "etudiant"},
    )

    assert approbation.status_code == 200
    assert approbation.json()["donnees"]["statut"] == "approuvee"
    assert connexion.status_code == 200
    with SessionLocale() as session:
        utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == donnees["email"]))
        assert utilisateur is not None
        assert utilisateur.statut == "actif"
        assert session.scalar(select(Etudiant).where(Etudiant.utilisateur_id == utilisateur.id)) is not None


def test_approbation_etudiant_par_chef_promotion_autorise(client: TestClient, suffixe: str):
    promotion_id = _promotion_id()
    donnees = _creer_demande(client, _payload_etudiant(suffixe, promotion_id=promotion_id))
    email_chef = _creer_chef_promotion(suffixe, promotion_id)
    token = _connecter(client, email_chef, "chef_promotion")

    approbation = client.post(
        f"/api/v1/inscriptions/demandes/{donnees['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert approbation.status_code == 200


def test_refus_chef_promotion_hors_perimetre(client: TestClient, suffixe: str, references_academiques: tuple[int, int]):
    annee_id, _ = references_academiques
    with SessionLocale() as session:
        autre = Promotion(
            nom=f"Autre promotion {suffixe}",
            niveau="L3",
            description=None,
            annee_academique_id=annee_id,
            est_active=True,
        )
        session.add(autre)
        session.commit()
        autre_id = autre.id
    donnees = _creer_demande(client, _payload_etudiant(suffixe, promotion_id=autre_id))
    email_chef = _creer_chef_promotion(f"hors.{suffixe}", _promotion_id())
    token = _connecter(client, email_chef, "chef_promotion")

    reponse = client.post(
        f"/api/v1/inscriptions/demandes/{donnees['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert reponse.status_code == 403


def test_approbation_enseignant_par_appariteur_et_doyen(client: TestClient, suffixe: str):
    demande_appariteur = _creer_demande(client, _payload_enseignant(f"app.{suffixe}"))
    demande_doyen = _creer_demande(client, _payload_enseignant(f"doyen.{suffixe}"))
    token_appariteur = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    token_doyen = _connecter(client, "doyen@smartfaculty.test", "doyen")

    reponse_appariteur = client.post(
        f"/api/v1/inscriptions/demandes/{demande_appariteur['id']}/approuver",
        headers={"Authorization": f"Bearer {token_appariteur}"},
    )
    reponse_doyen = client.post(
        f"/api/v1/inscriptions/demandes/{demande_doyen['id']}/approuver",
        headers={"Authorization": f"Bearer {token_doyen}"},
    )

    assert reponse_appariteur.status_code == 200
    assert reponse_doyen.status_code == 200
    with SessionLocale() as session:
        utilisateur = session.scalar(select(Utilisateur).where(Utilisateur.email == demande_doyen["email"]))
        assert utilisateur is not None
        assert session.scalar(select(Enseignant).where(Enseignant.utilisateur_id == utilisateur.id)) is not None


def test_refus_approbation_par_role_interdit(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_enseignant(suffixe))
    token = _connecter(client, "etudiant@smartfaculty.test", "etudiant")

    reponse = client.post(
        f"/api/v1/inscriptions/demandes/{donnees['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    )

    assert reponse.status_code == 403


def test_rejet_demande_et_connexion_impossible(client: TestClient, suffixe: str):
    donnees = _creer_demande(client, _payload_etudiant(suffixe))
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")

    rejet = client.post(
        f"/api/v1/inscriptions/demandes/{donnees['id']}/rejeter",
        json={"motif": "Dossier incomplet"},
        headers={"Authorization": f"Bearer {token}"},
    )
    connexion = client.post(
        "/api/v1/auth/connexion",
        json={"email": donnees["email"], "mot_de_passe": MOT_DE_PASSE, "role": "etudiant"},
    )

    assert rejet.status_code == 200
    assert rejet.json()["donnees"]["statut"] == "rejetee"
    assert connexion.status_code == 401


def test_impossibilite_retraiter_demande_approuvee_ou_rejetee(client: TestClient, suffixe: str):
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    approuvee = _creer_demande(client, _payload_etudiant(f"ok.{suffixe}"))
    rejetee = _creer_demande(client, _payload_etudiant(f"ko.{suffixe}"))

    assert client.post(
        f"/api/v1/inscriptions/demandes/{approuvee['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    ).status_code == 200
    assert client.post(
        f"/api/v1/inscriptions/demandes/{rejetee['id']}/rejeter",
        json={"motif": "Non conforme"},
        headers={"Authorization": f"Bearer {token}"},
    ).status_code == 200

    assert client.post(
        f"/api/v1/inscriptions/demandes/{approuvee['id']}/rejeter",
        json={"motif": "Trop tard"},
        headers={"Authorization": f"Bearer {token}"},
    ).status_code == 409
    assert client.post(
        f"/api/v1/inscriptions/demandes/{rejetee['id']}/approuver",
        headers={"Authorization": f"Bearer {token}"},
    ).status_code == 409
