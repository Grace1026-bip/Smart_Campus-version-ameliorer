from __future__ import annotations

from datetime import date
from decimal import Decimal

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import (
    AnneeAcademique,
    Cours,
    Evaluation,
    Etudiant,
    InscriptionCours,
    ResultatCours,
    Semestre,
    TypeEvaluation,
    Utilisateur,
)


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": "Smart@123456", "role": role},
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _references() -> tuple[int, int, int, int, int]:
    with SessionLocale() as session:
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        semestre_1 = session.scalar(select(Semestre).where(Semestre.numero == 1))
        semestre_2 = session.scalar(select(Semestre).where(Semestre.numero == 2))
        cours = session.scalar(select(Cours).where(Cours.code == "BD201"))
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        assert etudiant and semestre_1 and semestre_2 and cours and annee
        return etudiant.id, semestre_1.id, semestre_2.id, cours.id, annee.id


def _seed_resultat(
    cours_id: int,
    etudiant_id: int,
    moyenne: Decimal | int,
    statut: str,
    *,
    credits_obtenus: int,
    evaluations_publiees: bool = True,
    suffixe: str = "resultat",
) -> None:
    with SessionLocale() as session:
        cours = session.get(Cours, cours_id)
        type_evaluation = session.scalar(select(TypeEvaluation).limit(1))
        enseignant = session.scalar(select(Utilisateur).where(Utilisateur.email == "enseignant@smartfaculty.test"))
        assert cours and type_evaluation and enseignant
        session.add(
            Evaluation(
                cours_id=cours_id,
                type_evaluation_id=type_evaluation.id,
                titre=f"Evaluation {suffixe}",
                note_maximale=Decimal("20"),
                ponderation=Decimal("100"),
                statut="publiee" if evaluations_publiees else "brouillon",
                cree_par=enseignant.id,
                date_evaluation=date.today(),
                est_verrouillee=evaluations_publiees,
            )
        )
        session.flush()
        session.add(
            ResultatCours(
                etudiant_id=etudiant_id,
                cours_id=cours_id,
                moyenne=moyenne,
                credits_obtenus=credits_obtenus,
                statut_resultat=statut,
            )
        )
        session.commit()


def _creer_second_cours_semestre_1(etudiant_id: int, annee_id: int, semestre_id: int, suffixe: str) -> int:
    with SessionLocale() as session:
        etudiant = session.get(Etudiant, etudiant_id)
        cours = Cours(
            code=f"MAT{suffixe[-6:]}",
            intitule="Mathematiques appliquees",
            nombre_heures=45,
            nombre_credits=3,
            semestre_id=semestre_id,
            promotion_id=etudiant.promotion_id,
            est_actif=True,
        )
        session.add(cours)
        session.flush()
        session.add(
            InscriptionCours(
                etudiant_id=etudiant_id,
                cours_id=cours.id,
                annee_academique_id=annee_id,
                date_inscription=date.today(),
                statut="active",
            )
        )
        session.commit()
        return cours.id


def _apercu(client: TestClient, token: str, etudiant_id: int, semestre_id: int):
    return client.get(
        f"/api/v1/resultats/etudiants/{etudiant_id}/semestres/{semestre_id}/apercu",
        headers={"Authorization": f"Bearer {token}"},
    )


def test_moyenne_un_cours_credits_et_decision_non_officielle(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    reponse = _apercu(client, token, etudiant_id, semestre_1)
    assert reponse.status_code == 200
    donnees = reponse.json()["donnees"]
    assert donnees["moyenne_semestre_sur_100"] == 80
    assert donnees["credits_prevus"] == 5
    assert donnees["credits_acquis"] == 5
    assert donnees["credits_non_acquis"] == 0
    assert donnees["decision_provisoire"] == "en_attente_de_validation"
    assert donnees["decision_officielle"] is False


def test_moyenne_ponderee_plusieurs_cours_et_credits_non_acquis(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, annee_id = _references()
    second_cours = _creer_second_cours_semestre_1(etudiant_id, annee_id, semestre_1, suffixe)
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, suffixe=f"{suffixe}a")
    _seed_resultat(second_cours, etudiant_id, 40, "echoue", credits_obtenus=0, suffixe=f"{suffixe}b")
    token = _connexion(client, "appariteur@smartfaculty.test", "appariteur")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["moyenne_semestre_sur_100"] == 65
    assert donnees["moyenne_semestre_sur_20"] == 13
    assert donnees["credits_prevus"] == 8
    assert donnees["credits_acquis"] == 5
    assert donnees["credits_non_acquis"] == 3
    assert {item["statut_validation"] for item in donnees["cours"]} == {"acquis", "non_acquis"}


def test_precision_decimal_et_arrondi_final(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, annee_id = _references()
    second_cours = _creer_second_cours_semestre_1(etudiant_id, annee_id, semestre_1, suffixe)
    _seed_resultat(cours_id, etudiant_id, Decimal("66.67"), "reussi", credits_obtenus=5, suffixe=f"{suffixe}a")
    _seed_resultat(second_cours, etudiant_id, Decimal("33.33"), "echoue", credits_obtenus=0, suffixe=f"{suffixe}b")
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["moyenne_semestre_sur_100"] == 54.15
    assert donnees["moyenne_semestre_sur_20"] == 10.83


def test_semestre_incomplet_resultat_manquant(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, annee_id = _references()
    second_cours = _creer_second_cours_semestre_1(etudiant_id, annee_id, semestre_1, suffixe)
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert donnees["moyenne_semestre_sur_100"] is None
    assert "resultat_non_publie" in donnees["raisons_incompletude"]
    assert any(item["cours_id"] == second_cours and item["resultat_publie_sur_100"] is None for item in donnees["cours"])


def test_note_zero_et_echec_n_attribuent_pas_de_credit(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 0, "echoue", credits_obtenus=0, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["moyenne_semestre_sur_100"] == 0
    assert donnees["credits_acquis"] == 0
    assert donnees["cours"][0]["raison_non_validation"] == "seuil_non_atteint"


def test_resultat_en_attente_bloque_la_consolidation(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "en_attente", credits_obtenus=0, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert donnees["decision_provisoire"] is None


def test_resultat_non_verrouille_bloque_la_consolidation(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, evaluations_publiees=False, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert "resultat_non_publie" in donnees["raisons_incompletude"]


def test_credits_incoherents_bloquent_la_consolidation(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=1, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert "credits_incoherents" in donnees["raisons_incompletude"]


def test_autre_semestre_est_isole(client: TestClient, suffixe: str):
    etudiant_id, _semestre_1, semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_2).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert all(item["cours_id"] != cours_id for item in donnees["cours"])
    assert all(item["resultat_publie_sur_100"] is None for item in donnees["cours"])


def test_acces_etudiant_a_son_propre_apercu(client: TestClient, token_etudiant: str, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    reponse = _apercu(client, token_etudiant, etudiant_id, semestre_1)
    assert reponse.status_code == 200


def test_etudiant_ne_voit_pas_un_autre_etudiant(client: TestClient, token_etudiant: str, semestre_id: int = 0):
    etudiant_id, semestre_1, _semestre_2, _cours_id, _annee_id = _references()
    autre_id = etudiant_id + 999999
    assert _apercu(client, token_etudiant, autre_id, semestre_id or semestre_1).status_code == 403


def test_enseignant_n_est_pas_responsable_du_semestre(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    assert _apercu(client, token, etudiant_id, semestre_1).status_code == 403


def test_acces_sans_token_refuse(client: TestClient):
    etudiant_id, semestre_1, _semestre_2, _cours_id, _annee_id = _references()
    assert _apercu(client, "invalide", etudiant_id, semestre_1).status_code == 401


def test_role_falsifie_refuse_par_backend(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    assert _apercu(client, token, etudiant_id, semestre_1).status_code == 403


def test_annee_inactive_refusee(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, _cours_id, _annee_id = _references()
    with SessionLocale() as session:
        annee = AnneeAcademique(
            libelle=f"2024-2025-{suffixe[-6:]}",
            date_debut=date(2024, 9, 1),
            date_fin=date(2025, 7, 31),
            est_active=False,
        )
        session.add(annee)
        session.flush()
        semestre = Semestre(nom="Semestre historique", numero=1, annee_academique_id=annee.id)
        session.add(semestre)
        session.commit()
        token = _connexion(client, "doyen@smartfaculty.test", "doyen")
        assert _apercu(client, token, etudiant_id, semestre.id).status_code == 400


def test_liste_semestres_etudiants_sans_donnee_sensible(client: TestClient, token_admin: str):
    etudiant_id, _semestre_1, _semestre_2, _cours_id, _annee_id = _references()
    reponse = client.get(
        "/api/v1/resultats/etudiants",
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    assert reponse.status_code == 200
    assert all("email" not in item and "mot_de_passe" not in item for item in reponse.json()["donnees"]["etudiants"])
    semestres = client.get(
        f"/api/v1/resultats/etudiants/{etudiant_id}/semestres",
        headers={"Authorization": f"Bearer {token_admin}"},
    )
    assert semestres.status_code == 200


def test_recalcul_idempotent_et_aucun_doublon(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    premier = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    second = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert premier == second
    with SessionLocale() as session:
        assert session.scalar(
            select(ResultatCours).where(
                ResultatCours.etudiant_id == etudiant_id,
                ResultatCours.cours_id == cours_id,
            )
        ) is not None


@pytest.mark.parametrize(
    ("statut", "credits", "attendu"),
    [("reussi", 5, "acquis"), ("echoue", 0, "non_acquis")],
)
def test_validation_credits_selon_seuil(client: TestClient, suffixe: str, statut: str, credits: int, attendu: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    moyenne = 50 if statut == "reussi" else 49.99
    _seed_resultat(cours_id, etudiant_id, moyenne, statut, credits_obtenus=credits, suffixe=f"{suffixe}{statut}")
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["cours"][0]["statut_validation"] == attendu


def test_aucune_compensation_ou_decision_admis_ajourne(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 80, "reussi", credits_obtenus=5, suffixe=suffixe)
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["decision_provisoire"] == "en_attente_de_validation"
    assert "admis" not in donnees
    assert "ajourne" not in donnees
    assert "compensation" not in donnees


def test_inscription_inactive_bloque_la_consolidation(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, _annee_id = _references()
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    with SessionLocale() as session:
        inscription = session.scalar(
            select(InscriptionCours).where(
                InscriptionCours.etudiant_id == etudiant_id,
                InscriptionCours.cours_id == cours_id,
            )
        )
        assert inscription is not None
        inscription.statut = "retiree"
        session.commit()
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "incomplet"
    assert "inscription_cours_invalide" in donnees["raisons_incompletude"]


def test_etudiant_inactif_refuse(client: TestClient):
    etudiant_id, semestre_1, _semestre_2, _cours_id, _annee_id = _references()
    with SessionLocale() as session:
        etudiant = session.get(Etudiant, etudiant_id)
        assert etudiant is not None
        etudiant.statut_academique = "suspendu"
        session.commit()
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    assert _apercu(client, token, etudiant_id, semestre_1).status_code == 403


def test_cours_archive_exclu_du_programme(client: TestClient, suffixe: str):
    etudiant_id, semestre_1, _semestre_2, cours_id, annee_id = _references()
    cours_archive = _creer_second_cours_semestre_1(etudiant_id, annee_id, semestre_1, suffixe)
    _seed_resultat(cours_id, etudiant_id, 70, "reussi", credits_obtenus=5, suffixe=suffixe)
    with SessionLocale() as session:
        cours = session.get(Cours, cours_archive)
        assert cours is not None
        cours.est_actif = False
        session.commit()
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_1).json()["donnees"]
    assert donnees["etat"] == "provisoire"
    assert all(item["cours_id"] != cours_archive for item in donnees["cours"])


def test_semestre_sans_cours_retourne_un_etat_dedie(client: TestClient, suffixe: str):
    etudiant_id, _semestre_1, _semestre_2, _cours_id, annee_id = _references()
    with SessionLocale() as session:
        semestre = Semestre(
            nom=f"Semestre vide {suffixe}",
            numero=3,
            annee_academique_id=annee_id,
        )
        session.add(semestre)
        session.commit()
        semestre_id = semestre.id
    token = _connexion(client, "doyen@smartfaculty.test", "doyen")
    donnees = _apercu(client, token, etudiant_id, semestre_id).json()["donnees"]
    assert donnees["etat"] == "aucun_cours"
    assert donnees["moyenne_semestre_sur_100"] is None
