from __future__ import annotations

from datetime import date
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import AnneeAcademique, Cours, Enseignant, Etudiant, Evaluation, InscriptionCours, ResultatCours, Semestre, TypeEvaluation, Utilisateur
from app.services.resultats_academiques import determiner_decision


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post("/api/v1/auth/connexion", json={"email": email, "mot_de_passe": "Smart@123456", "role": role})
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _references() -> tuple[int, int, int, int, int, int]:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        semestre = session.scalar(select(Semestre).where(Semestre.numero == 1))
        cours = session.scalar(select(Cours).where(Cours.code == "BD201"))
        doyen = session.scalar(select(Utilisateur).where(Utilisateur.email == "doyen@smartfaculty.test"))
        enseignant = session.scalar(select(Enseignant).join(Enseignant.utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert etudiant and annee and semestre and cours and doyen and enseignant
        return etudiant.id, annee.id, semestre.id, cours.id, doyen.id, enseignant.utilisateur_id


def _preparer_semestre_30(etudiant_id: int, annee_id: int, semestre_id: int, premier_cours_id: int, suffixe: str, valeurs: list[tuple[int, str]]) -> None:
    with SessionLocale() as session:
        cours = [session.get(Cours, premier_cours_id)]
        etudiant = session.get(Etudiant, etudiant_id)
        type_evaluation = session.scalar(select(TypeEvaluation).limit(1))
        enseignant = session.scalar(select(Utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert etudiant and type_evaluation and enseignant and cours[0]
        while len(cours) < 6:
            cours.append(Cours(code=f"JUR{suffixe[-5:]}{len(cours)}", intitule="Cours de deliberation", nombre_heures=45, nombre_credits=5, semestre_id=semestre_id, promotion_id=etudiant.promotion_id, est_actif=True))
        session.add_all(cours[1:])
        session.flush()
        for index, cours_item in enumerate(cours):
            if index > 0:
                session.add(InscriptionCours(etudiant_id=etudiant_id, cours_id=cours_item.id, annee_academique_id=annee_id, date_inscription=date.today(), statut="active"))
            valeur, statut = valeurs[index]
            session.add(Evaluation(cours_id=cours_item.id, type_evaluation_id=type_evaluation.id, titre=f"Jury {suffixe}-{index}", note_maximale=Decimal("20"), ponderation=Decimal("100"), statut="publiee", cree_par=enseignant.id, date_evaluation=date.today(), est_verrouillee=True))
            session.add(ResultatCours(etudiant_id=etudiant_id, cours_id=cours_item.id, moyenne=valeur, credits_obtenus=cours_item.nombre_credits if statut == "reussi" else 0, statut_resultat=statut))
        session.commit()


def _creer_session(client: TestClient, token_doyen: str, annee_id: int, semestre_id: int, promotion_id: int) -> int:
    reponse = client.post("/api/v1/deliberations", headers={"Authorization": f"Bearer {token_doyen}"}, json={"promotion_id": promotion_id, "annee_academique_id": annee_id, "semestre_id": semestre_id})
    assert reponse.status_code == 201
    return reponse.json()["donnees"]["id"]


def test_decisions_lmd_adm_comp_def_aj():
    assert determiner_decision(complet=True, moyenne_sur_20=Decimal("12"), credits_acquis=30, credits_prevus=30) == "ADM"
    assert determiner_decision(complet=True, moyenne_sur_20=Decimal("10"), credits_acquis=25, credits_prevus=30) == "COMP"
    assert determiner_decision(complet=False, moyenne_sur_20=None, credits_acquis=0, credits_prevus=30, raisons=["resultat_non_publie"]) == "DEF"
    assert determiner_decision(complet=True, moyenne_sur_20=Decimal("9.99"), credits_acquis=0, credits_prevus=30) == "AJ"


@pytest.mark.parametrize(
    ("valeur", "statut", "credits"),
    [(50, "reussi", 5), (49, "echoue", 0), (0, "echoue", 0)],
)
def test_seuil_cours_50_sur_100_et_capitalisation(valeur: int, statut: str, credits: int):
    assert (valeur >= 50) == (statut == "reussi")
    assert credits == (5 if statut == "reussi" else 0)


def test_doyen_cree_et_vice_doyen_est_autorise(client: TestClient):
    _etudiant_id, annee_id, semestre_id, _cours_id, _doyen_id, _enseignant_id = _references()
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.matricule == "SF-L2-0001"))
    sid = _creer_session(client, _connexion(client, "doyen@smartfaculty.test", "doyen"), annee_id, semestre_id, promotion_id)
    assert sid > 0
    assert client.get("/api/v1/deliberations", headers={"Authorization": f"Bearer {_connexion(client, 'vice.doyen@smartfaculty.test', 'vice_doyen')}"}).status_code == 200


def test_appariteur_ne_cree_pas_de_session(client: TestClient):
    _etudiant_id, annee_id, semestre_id, _cours_id, _doyen_id, _enseignant_id = _references()
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.matricule == "SF-L2-0001"))
    reponse = client.post("/api/v1/deliberations", headers={"Authorization": f"Bearer {_connexion(client, 'appariteur@smartfaculty.test', 'appariteur')}"}, json={"promotion_id": promotion_id, "annee_academique_id": annee_id, "semestre_id": semestre_id})
    assert reponse.status_code == 403


def test_jury_cloture_snapshot_publication_etudiant(client: TestClient, suffixe: str):
    etudiant_id, annee_id, semestre_id, premier_cours_id, _doyen_id, enseignant_id = _references()
    _preparer_semestre_30(etudiant_id, annee_id, semestre_id, premier_cours_id, suffixe, [(80, "reussi")] * 6)
    token_doyen = _connexion(client, "doyen@smartfaculty.test", "doyen")
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.id == etudiant_id))
    session_id = _creer_session(client, token_doyen, annee_id, semestre_id, promotion_id)
    ajout = client.post(f"/api/v1/deliberations/{session_id}/membres", headers={"Authorization": f"Bearer {token_doyen}"}, json={"utilisateur_id": enseignant_id, "qualite": "president", "present": True})
    assert ajout.status_code == 200
    assert client.post(f"/api/v1/deliberations/{session_id}/ouvrir", headers={"Authorization": f"Bearer {token_doyen}"}).status_code == 200
    grille = client.get(f"/api/v1/deliberations/{session_id}/grille", headers={"Authorization": f"Bearer {token_doyen}"})
    assert grille.status_code == 200
    assert grille.json()["donnees"]["etudiants"][0]["proposition_decision"] == "ADM"
    president_token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    assert client.post(f"/api/v1/deliberations/{session_id}/decisions/{etudiant_id}", headers={"Authorization": f"Bearer {president_token}"}, json={"decision": "ADM"}).status_code == 200
    cloture = client.post(f"/api/v1/deliberations/{session_id}/cloturer", headers={"Authorization": f"Bearer {president_token}"})
    assert cloture.status_code == 200
    assert cloture.json()["donnees"]["snapshots"] == 1
    assert client.post(f"/api/v1/deliberations/{session_id}/cloturer", headers={"Authorization": f"Bearer {president_token}"}).status_code == 200
    token_etudiant = _connexion(client, "etudiant@smartfaculty.test", "etudiant")
    avant = client.get(f"/api/v1/resultats/mes-semestres/{semestre_id}/officiel", headers={"Authorization": f"Bearer {token_etudiant}"})
    assert avant.status_code == 200
    assert avant.json()["donnees"]["resultats"] == []
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    assert client.post(f"/api/v1/deliberations/{session_id}/publier", headers={"Authorization": f"Bearer {token_appariteur}"}).status_code == 200
    assert client.post(f"/api/v1/deliberations/{session_id}/publier", headers={"Authorization": f"Bearer {token_appariteur}"}).status_code == 200
    officiel = client.get(f"/api/v1/resultats/mes-semestres/{semestre_id}/officiel", headers={"Authorization": f"Bearer {token_etudiant}"})
    donnees = officiel.json()["donnees"]["resultats"][0]
    assert donnees["decision"] == "ADM"
    assert donnees["moyenne_ponderee_sur_20"] == 16
    assert donnees["credits_capitalises"] == 30
    assert "mot_de_passe" not in officiel.text and "notes" not in officiel.text


def test_compensation_ne_capitalise_pas_le_cours_echoue(client: TestClient, suffixe: str):
    etudiant_id, annee_id, semestre_id, premier_cours_id, _doyen_id, enseignant_id = _references()
    _preparer_semestre_30(etudiant_id, annee_id, semestre_id, premier_cours_id, suffixe, [(80, "reussi"), (40, "echoue"), (80, "reussi"), (80, "reussi"), (80, "reussi"), (80, "reussi")])
    token_doyen = _connexion(client, "doyen@smartfaculty.test", "doyen")
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.id == etudiant_id))
    sid = _creer_session(client, token_doyen, annee_id, semestre_id, promotion_id)
    client.post(f"/api/v1/deliberations/{sid}/membres", headers={"Authorization": f"Bearer {token_doyen}"}, json={"utilisateur_id": enseignant_id, "qualite": "president"})
    client.post(f"/api/v1/deliberations/{sid}/ouvrir", headers={"Authorization": f"Bearer {token_doyen}"})
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    grille = client.get(f"/api/v1/deliberations/{sid}/grille", headers={"Authorization": f"Bearer {token_doyen}"}).json()["donnees"]["etudiants"][0]
    assert grille["proposition_decision"] == "COMP"
    assert grille["credits_capitalises"] == 25
    assert client.post(f"/api/v1/deliberations/{sid}/decisions/{etudiant_id}", headers={"Authorization": f"Bearer {token_enseignant}"}, json={"decision": "COMP"}).status_code == 200


def test_decision_incompatible_enseignant_non_membre_et_publication_avant_cloture_refuses(client: TestClient, suffixe: str):
    etudiant_id, annee_id, semestre_id, premier_cours_id, _doyen_id, enseignant_id = _references()
    _preparer_semestre_30(etudiant_id, annee_id, semestre_id, premier_cours_id, suffixe, [(80, "reussi")] * 6)
    token_doyen = _connexion(client, "doyen@smartfaculty.test", "doyen")
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.id == etudiant_id))
    sid = _creer_session(client, token_doyen, annee_id, semestre_id, promotion_id)
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    assert client.post(f"/api/v1/deliberations/{sid}/decisions/{etudiant_id}", headers={"Authorization": f"Bearer {token_enseignant}"}, json={"decision": "AJ"}).status_code == 403
    token_appariteur = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    assert client.post(f"/api/v1/deliberations/{sid}/publier", headers={"Authorization": f"Bearer {token_appariteur}"}).status_code == 409
    assert client.post(f"/api/v1/deliberations/{sid}/membres", headers={"Authorization": f"Bearer {token_doyen}"}, json={"utilisateur_id": enseignant_id, "qualite": "president"}).status_code == 200


def test_reouverture_exige_motif_et_conserve_version(client: TestClient, suffixe: str):
    etudiant_id, annee_id, semestre_id, premier_cours_id, _doyen_id, enseignant_id = _references()
    _preparer_semestre_30(etudiant_id, annee_id, semestre_id, premier_cours_id, suffixe, [(80, "reussi")] * 6)
    token_doyen = _connexion(client, "doyen@smartfaculty.test", "doyen")
    with SessionLocale() as session:
        promotion_id = session.scalar(select(Etudiant.promotion_id).where(Etudiant.id == etudiant_id))
    sid = _creer_session(client, token_doyen, annee_id, semestre_id, promotion_id)
    client.post(f"/api/v1/deliberations/{sid}/membres", headers={"Authorization": f"Bearer {token_doyen}"}, json={"utilisateur_id": enseignant_id, "qualite": "president"})
    client.post(f"/api/v1/deliberations/{sid}/ouvrir", headers={"Authorization": f"Bearer {token_doyen}"})
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    client.post(f"/api/v1/deliberations/{sid}/decisions/{etudiant_id}", headers={"Authorization": f"Bearer {token_enseignant}"}, json={"decision": "ADM"})
    client.post(f"/api/v1/deliberations/{sid}/cloturer", headers={"Authorization": f"Bearer {token_enseignant}"})
    assert client.post(f"/api/v1/deliberations/{sid}/demander-reouverture", headers={"Authorization": f"Bearer {token_doyen}"}, json={"motif": ""}).status_code == 422
    nouvelle = client.post(f"/api/v1/deliberations/{sid}/demander-reouverture", headers={"Authorization": f"Bearer {token_doyen}"}, json={"motif": "Correction administrative documentee"})
    assert nouvelle.status_code == 201
    assert nouvelle.json()["donnees"]["version"] == 2
