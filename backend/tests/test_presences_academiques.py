from __future__ import annotations

from datetime import date
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from passlib.context import CryptContext
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import hacher_mot_de_passe
from app.modeles import (
    AnneeAcademique,
    Cours,
    EnrolementAcademique,
    Etudiant,
    InscriptionCours,
    Role,
    Utilisateur,
    UtilisateurRole,
)


MOT_DE_PASSE = "Smart@123456"
contexte_mot_de_passe = CryptContext(schemes=["bcrypt"], deprecated="auto")


def _entetes(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def _connecter(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": MOT_DE_PASSE, "role": role},
    )
    assert reponse.status_code == 200, reponse.text
    return reponse.json()["donnees"]["access_token"]


def _references() -> tuple[int, int, int, int, int]:
    with SessionLocale() as session:
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        cours = session.scalar(select(Cours).where(Cours.code == "BD201"))
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        appariteur = session.scalar(select(Utilisateur).where(Utilisateur.email == "appariteur@smartfaculty.test"))
        assert annee is not None and cours is not None and etudiant is not None and appariteur is not None
        return annee.id, cours.id, cours.promotion_id, etudiant.id, appariteur.id


def _enrolement(pourcentage: str, suffixe: str) -> int:
    annee_id, cours_id, promotion_id, etudiant_id, appariteur_id = _references()
    with SessionLocale() as session:
        enrolement = EnrolementAcademique(
            etudiant_id=etudiant_id,
            promotion_id=promotion_id,
            annee_academique_id=annee_id,
            date_enrolement=date.today(),
            statut="valide",
            cree_par_utilisateur_id=appariteur_id,
            valide_par_utilisateur_id=appariteur_id,
            reference_fiche=f"ENR-7A-{suffixe}",
            pourcentage_paiement=Decimal(pourcentage),
            date_validation=None,
            cle_doublon_actif=f"{etudiant_id}:{promotion_id}:{annee_id}:7a:{suffixe}",
        )
        session.add(enrolement)
        session.commit()
        return enrolement.id


def _inscription() -> None:
    annee_id, cours_id, _, etudiant_id, _ = _references()
    with SessionLocale() as session:
        if session.scalar(
            select(InscriptionCours.id).where(
                InscriptionCours.etudiant_id == etudiant_id,
                InscriptionCours.cours_id == cours_id,
                InscriptionCours.annee_academique_id == annee_id,
            )
        ) is None:
            session.add(
                InscriptionCours(
                    etudiant_id=etudiant_id,
                    cours_id=cours_id,
                    annee_academique_id=annee_id,
                    date_inscription=date.today(),
                    statut="active",
                )
            )
            session.commit()


def _creer_seance(client: TestClient, token: str, type_cours: str = "cours_1") -> int:
    annee_id, cours_id, _, _, _ = _references()
    assert annee_id
    reponse = client.post(
        "/api/v1/surveillant/seances",
        json={
            "cours_id": cours_id,
            "date_seance": "2026-07-10",
            "heure_debut": "08:00:00",
            "heure_fin": "12:00:00",
            "type_cours": type_cours,
        },
        headers=_entetes(token),
    )
    assert reponse.status_code == 201, reponse.text
    return reponse.json()["donnees"]["id"]


@pytest.fixture()
def token_surveillant(client: TestClient) -> str:
    return _connecter(client, "surveillant@smartfaculty.test", "surveillant")


def test_surveillant_cree_ouvre_et_ferme_une_seance(client: TestClient, token_surveillant: str):
    seance_id = _creer_seance(client, token_surveillant)
    ouverte = client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    assert ouverte.status_code == 200
    assert ouverte.json()["donnees"]["statut"] == "ouverte"
    fermee = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))
    assert fermee.status_code == 200
    assert fermee.json()["donnees"]["statut"] == "fermee"


def test_presence_autorisee_a_50_pourcent_et_unique(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50.00", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    payload = {"matricule": "SF-L2-0001"}
    premiere = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json=payload,
        headers=_entetes(token_surveillant),
    )
    assert premiere.status_code == 200
    assert premiere.json()["donnees"]["acces_autorise"] is True
    assert premiere.json()["donnees"]["presence"]["pourcentage_paiement_observe"] == 50.0
    seconde = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json=payload,
        headers=_entetes(token_surveillant),
    )
    assert seconde.status_code == 200
    assert seconde.json()["donnees"]["motif"] == "deja_enregistre"
    assert len(client.get(f"/api/v1/surveillant/seances/{seance_id}/presences", headers=_entetes(token_surveillant)).json()["donnees"]["elements"]) == 1


def test_paiement_sous_50_refuse_et_observe(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("49.99", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    reponse = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json={"matricule": "SF-L2-0001"},
        headers=_entetes(token_surveillant),
    )
    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["acces_autorise"] is False
    assert reponse.json()["donnees"]["motif"] == "paiement_insuffisant"
    assert reponse.json()["donnees"]["presence"]["statut"] == "refuse"


def test_controle_refuse_non_enrole_et_seance_fermee(client: TestClient, token_surveillant: str):
    seance_id = _creer_seance(client, token_surveillant)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    non_enrole = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json={"matricule": "SF-L2-0001"},
        headers=_entetes(token_surveillant),
    )
    assert non_enrole.json()["donnees"]["motif"] == "non_enrole"
    client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))
    assert client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json={"matricule": "SF-L2-0001"},
        headers=_entetes(token_surveillant),
    ).json()["donnees"]["motif"] == "seance_fermee"


def test_roles_et_identification_inconnue_refuses(client: TestClient, token_etudiant: str, token_surveillant: str):
    assert client.get("/api/v1/surveillant/seances").status_code == 401
    assert client.get("/api/v1/surveillant/seances", headers=_entetes(token_etudiant)).status_code == 403
    seance_id = _creer_seance(client, token_surveillant)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    reponse = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json={"matricule": "INCONNU-7A"},
        headers=_entetes(token_surveillant),
    )
    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["motif"] == "etudiant_introuvable"


def test_chef_promotion_confirme_cours_2_de_sa_promotion(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        role = session.scalar(select(Role).where(Role.nom == "chef_promotion"))
        assert etudiant is not None and role is not None
        if session.scalar(
            select(UtilisateurRole).where(
                UtilisateurRole.utilisateur_id == etudiant.utilisateur_id,
                UtilisateurRole.role_id == role.id,
            )
        ) is None:
            session.add(UtilisateurRole(utilisateur_id=etudiant.utilisateur_id, role_id=role.id))
            session.commit()
        email = etudiant.utilisateur.email
    token_chef = _connecter(client, email, "chef_promotion")
    seance_id = _creer_seance(client, token_surveillant, "cours_2")
    client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token_surveillant))
    reponse = client.post(
        f"/api/v1/chef-promotion/seances/{seance_id}/confirmer-cours-2",
        headers=_entetes(token_chef),
    )
    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["confirme_cours_2"] is True


def test_migration_ne_retourne_aucune_donnee_sensible(client: TestClient, token_surveillant: str):
    reponse = client.get("/api/v1/surveillant/seances", headers=_entetes(token_surveillant))
    assert reponse.status_code == 200
    assert "mot_de_passe" not in reponse.text
    assert "mot_de_passe_hash" not in reponse.text
    assert "token" not in reponse.text.lower()
