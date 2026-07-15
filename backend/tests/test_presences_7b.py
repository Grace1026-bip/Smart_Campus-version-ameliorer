from __future__ import annotations

from datetime import date

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.configuration.securite import hacher_mot_de_passe
from app.modeles import (
    AnneeAcademique,
    CorrectionPresenceAcademique,
    Cours,
    Etudiant,
    PresenceAcademique,
    Promotion,
    Role,
    Utilisateur,
    UtilisateurRole,
)

from tests.test_presences_academiques import (
    _connecter,
    _creer_seance,
    _enrolement,
    _entetes,
    _inscription,
    _references,
)


@pytest.fixture()
def token_surveillant(client: TestClient) -> str:
    return _connecter(client, "surveillant@smartfaculty.test", "surveillant")


@pytest.fixture()
def token_enseignant(client: TestClient) -> str:
    return _token_enseignant(client)


def _ouvrir(client: TestClient, token: str, seance_id: int) -> None:
    reponse = client.post(f"/api/v1/surveillant/seances/{seance_id}/ouvrir", headers=_entetes(token))
    assert reponse.status_code == 200, reponse.text


def _controler(client: TestClient, token: str, seance_id: int, statut: str = "present") -> dict:
    reponse = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/controle-acces",
        json={"matricule": "SF-L2-0001", "statut": statut},
        headers=_entetes(token),
    )
    assert reponse.status_code == 200, reponse.text
    return reponse.json()["donnees"]


def _token_enseignant(client: TestClient) -> str:
    return _connecter(client, "enseignant@smartfaculty.test", "enseignant")


def _token_chef(client: TestClient) -> str:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        role = session.scalar(select(Role).where(Role.nom == "chef_promotion"))
        assert etudiant is not None and role is not None
        if session.execute(
            select(UtilisateurRole).where(
                UtilisateurRole.utilisateur_id == etudiant.utilisateur_id,
                UtilisateurRole.role_id == role.id,
            )
        ).scalar_one_or_none() is None:
            session.add(UtilisateurRole(utilisateur_id=etudiant.utilisateur_id, role_id=role.id))
            session.commit()
        email = etudiant.utilisateur.email
    return _connecter(client, email, "chef_promotion")


def test_fermeture_genere_absences_manquantes(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)

    reponse = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["resume"]["absences_creees"] == 1
    assert reponse.json()["donnees"]["resume"]["absents"] == 1


def test_fermeture_conserve_une_presence_existante(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    _controler(client, token_surveillant, seance_id)

    reponse = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    resume = reponse.json()["donnees"]["resume"]
    assert resume["presents"] == 1
    assert resume["absents"] == 0
    assert resume["absences_creees"] == 0


def test_refus_distinct_d_une_absence(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("49.99", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    _controler(client, token_surveillant, seance_id)

    reponse = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    resume = reponse.json()["donnees"]["resume"]
    assert resume["refuses"] == 1
    assert resume["absents"] == 0


def test_seconde_fermeture_idempotente(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    premiere = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))
    seconde = client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    assert premiere.status_code == seconde.status_code == 200
    assert seconde.json()["donnees"]["resume"]["absences_creees"] == 0
    assert len(client.get(f"/api/v1/surveillant/seances/{seance_id}/presences", headers=_entetes(token_surveillant)).json()["donnees"]["elements"]) == 1


def test_etudiant_voit_ses_presences_et_le_taux_backend(client: TestClient, token_surveillant: str, token_etudiant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    _controler(client, token_surveillant, seance_id)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    reponse = client.get("/api/v1/etudiants/moi/presences", headers=_entetes(token_etudiant))

    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["resume"]["taux_presence"] == 100.0
    assert reponse.json()["donnees"]["elements"][0]["etudiant"]["matricule"] == "SF-L2-0001"


def test_etudiant_ne_voit_pas_une_presence_d_un_autre(client: TestClient, token_surveillant: str, token_etudiant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    with SessionLocale() as session:
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        promotion = session.scalar(select(Promotion).where(Promotion.id == _references()[2]))
        surveillant = session.scalar(select(Utilisateur).where(Utilisateur.email == "surveillant@smartfaculty.test"))
        assert annee is not None and promotion is not None and surveillant is not None
        utilisateur = Utilisateur(
            nom="Autre",
            prenom="Etudiant",
            email=f"autre.7b.{suffixe}@smartfaculty.test",
            mot_de_passe_hash=hacher_mot_de_passe("Fake@123456"),
            statut="actif",
        )
        session.add(utilisateur)
        session.flush()
        autre = Etudiant(
            utilisateur_id=utilisateur.id,
            matricule=f"OTHER-7B-{suffixe}",
            promotion_id=promotion.id,
            date_inscription=date.today(),
            statut_academique="actif",
        )
        session.add(autre)
        session.flush()
        session.add(PresenceAcademique(seance_id=seance_id, etudiant_id=autre.id, statut="present", enregistre_par_utilisateur_id=surveillant.id))
        session.commit()

    reponse = client.get("/api/v1/etudiants/moi/presences", headers=_entetes(token_etudiant))

    assert reponse.status_code == 200
    assert all(item["etudiant"]["matricule"] == "SF-L2-0001" for item in reponse.json()["donnees"]["elements"])


def test_enseignant_voit_les_seances_de_ses_cours(client: TestClient, token_surveillant: str, suffixe: str):
    seance_id = _creer_seance(client, token_surveillant)
    token_enseignant = _token_enseignant(client)

    reponse = client.get("/api/v1/enseignants/moi/seances", headers=_entetes(token_enseignant))

    assert reponse.status_code == 200
    assert seance_id in [element["id"] for element in reponse.json()["donnees"]["elements"]]


def test_enseignant_ne_peut_pas_modifier_une_presence(client: TestClient, token_surveillant: str, token_enseignant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    presence = _controler(client, token_surveillant, seance_id)["presence"]

    reponse = client.patch(
        f"/api/v1/surveillant/seances/{seance_id}/presences/{presence['id']}",
        json={"nouveau_statut": "retard", "motif": "Correction interdite"},
        headers=_entetes(token_enseignant),
    )

    assert reponse.status_code == 403


def test_chef_de_promotion_est_limite_a_sa_promotion(client: TestClient, token_surveillant: str):
    seance_id = _creer_seance(client, token_surveillant)
    token_chef = _token_chef(client)
    promotion_l2 = _references()[2]

    reponse = client.get("/api/v1/chef-promotion/seances", headers=_entetes(token_chef))

    assert reponse.status_code == 200
    assert all(element["promotion_id"] == promotion_l2 for element in reponse.json()["donnees"]["elements"])
    assert seance_id in [element["id"] for element in reponse.json()["donnees"]["elements"]]


def test_correction_avec_motif_reussit_apres_fermeture(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))
    presence = client.get(f"/api/v1/surveillant/seances/{seance_id}/presences", headers=_entetes(token_surveillant)).json()["donnees"]["elements"][0]

    reponse = client.patch(
        f"/api/v1/surveillant/seances/{seance_id}/presences/{presence['id']}",
        json={"nouveau_statut": "present", "motif": "Justification administrative verifiee"},
        headers=_entetes(token_surveillant),
    )

    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["statut"] == "present"
    assert reponse.json()["donnees"]["correction"]["ancien_statut"] == "absent"


def test_correction_sans_motif_refusee(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    presence = _controler(client, token_surveillant, seance_id)["presence"]

    reponse = client.patch(
        f"/api/v1/surveillant/seances/{seance_id}/presences/{presence['id']}",
        json={"nouveau_statut": "retard", "motif": ""},
        headers=_entetes(token_surveillant),
    )

    assert reponse.status_code == 422


def test_correction_conserve_ancienne_et_nouvelle_valeur(client: TestClient, token_surveillant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    presence = _controler(client, token_surveillant, seance_id)["presence"]
    client.patch(
        f"/api/v1/surveillant/seances/{seance_id}/presences/{presence['id']}",
        json={"nouveau_statut": "retard", "motif": "Arrivee tardive confirmee"},
        headers=_entetes(token_surveillant),
    )

    with SessionLocale() as session:
        correction = session.scalar(select(CorrectionPresenceAcademique).where(CorrectionPresenceAcademique.presence_id == presence["id"]))
        assert correction is not None
        assert correction.ancien_statut == "present"
        assert correction.nouveau_statut == "retard"
        assert correction.motif == "Arrivee tardive confirmee"


def test_taux_presence_est_calcule_par_le_backend(client: TestClient, token_surveillant: str, token_etudiant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    _controler(client, token_surveillant, seance_id)
    client.post(f"/api/v1/surveillant/seances/{seance_id}/fermer", headers=_entetes(token_surveillant))

    reponse = client.get("/api/v1/etudiants/moi/presences", headers=_entetes(token_etudiant))

    assert reponse.json()["donnees"]["resume"]["taux_presence"] == 100.0


def test_vues_enseignant_et_etudiant_n_exposent_pas_le_paiement(client: TestClient, token_surveillant: str, token_etudiant: str, suffixe: str):
    _enrolement("75", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    _controler(client, token_surveillant, seance_id)
    token_enseignant = _token_enseignant(client)

    enseignant = client.get(f"/api/v1/enseignants/moi/seances/{seance_id}/presences", headers=_entetes(token_enseignant))
    etudiant = client.get("/api/v1/etudiants/moi/presences", headers=_entetes(token_etudiant))

    assert "pourcentage_paiement_observe" not in enseignant.text
    assert "pourcentage_paiement_observe" not in etudiant.text


def test_correction_refusee_a_un_role_non_autorise(client: TestClient, token_surveillant: str, token_etudiant: str, suffixe: str):
    _enrolement("50", suffixe)
    _inscription()
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    presence = _controler(client, token_surveillant, seance_id)["presence"]

    reponse = client.patch(
        f"/api/v1/surveillant/seances/{seance_id}/presences/{presence['id']}",
        json={"nouveau_statut": "retard", "motif": "Tentative interdite"},
        headers=_entetes(token_etudiant),
    )

    assert reponse.status_code == 403


def test_routes_presence_refusent_absence_de_token(client: TestClient):
    assert client.get("/api/v1/etudiants/moi/presences").status_code == 401
    assert client.get("/api/v1/enseignants/moi/seances").status_code == 401


def test_tests_7b_utilisent_une_base_de_test():
    from app.configuration.parametres import obtenir_parametres

    assert obtenir_parametres().mysql_database.endswith("_test")
