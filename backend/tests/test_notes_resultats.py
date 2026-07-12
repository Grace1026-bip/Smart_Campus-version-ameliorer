from __future__ import annotations

from datetime import date

from fastapi.testclient import TestClient
from sqlalchemy import select

from app.base_de_donnees.connexion import SessionLocale
from app.modeles import Cours, Etudiant, TypeEvaluation


def _connexion(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": email,
            "mot_de_passe": "Smart@123456",
            "role": role,
        },
    )
    assert reponse.status_code == 200
    return reponse.json()["donnees"]["access_token"]


def _references_notes(code_cours: str = "BD201") -> tuple[int, int, int]:
    with SessionLocale() as session:
        cours = session.scalar(select(Cours).where(Cours.code == code_cours))
        type_evaluation = session.scalar(select(TypeEvaluation).where(TypeEvaluation.nom == "examen"))
        etudiant = session.scalar(select(Etudiant).where(Etudiant.matricule == "SF-L2-0001"))
        assert cours is not None
        assert type_evaluation is not None
        assert etudiant is not None
        return cours.id, type_evaluation.id, etudiant.id


def _type_evaluation_id(nom: str) -> int:
    with SessionLocale() as session:
        type_evaluation = session.scalar(select(TypeEvaluation).where(TypeEvaluation.nom == nom))
        assert type_evaluation is not None
        return type_evaluation.id


def test_cycle_notes_publication_resultats_etudiant(client: TestClient, token_etudiant: str, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_enseignant = {"Authorization": f"Bearer {token_enseignant}"}
    headers_etudiant = {"Authorization": f"Bearer {token_etudiant}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes()

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Examen pytest {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
            "date_evaluation": str(date.today()),
        },
        headers=headers_enseignant,
    )
    assert creation.status_code == 201
    evaluation = creation.json()["donnees"]["evaluation"]
    evaluation_id = evaluation["id"]
    assert evaluation["statut"] == "brouillon"

    notes_avant_publication = client.get("/api/v1/etudiant/notes", headers=headers_etudiant)
    assert notes_avant_publication.status_code == 200
    assert all(
        ligne["evaluation"]["id"] != evaluation_id
        for ligne in notes_avant_publication.json()["donnees"]["notes"]
    )

    encodage = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={
            "notes": [
                {
                    "etudiant_id": etudiant_id,
                    "note_obtenue": 16,
                    "commentaire": "Bonne maitrise",
                }
            ]
        },
        headers=headers_enseignant,
    )
    assert encodage.status_code == 200
    assert encodage.json()["donnees"]["notes"][0]["note_obtenue"] == 16

    publication = client.post(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/publier",
        json={"confirmer_notes_manquantes": False},
        headers=headers_enseignant,
    )
    assert publication.status_code == 200
    assert publication.json()["donnees"]["evaluation"]["statut"] == "publiee"

    notes_publiees = client.get(f"/api/v1/etudiant/cours/{cours_id}/notes", headers=headers_etudiant)
    assert notes_publiees.status_code == 200
    lignes_notes = notes_publiees.json()["donnees"]["notes"]
    assert any(ligne["evaluation"]["id"] == evaluation_id for ligne in lignes_notes)

    resultats = client.get("/api/v1/etudiant/resultats", headers=headers_etudiant)
    assert resultats.status_code == 200
    ligne_resultat = next(
        resultat for resultat in resultats.json()["donnees"]["resultats"] if resultat["cours_id"] == cours_id
    )
    assert ligne_resultat["moyenne"] == 80
    assert ligne_resultat["statut_resultat"] == "reussi"
    assert ligne_resultat["credits_obtenus"] == 5

    verrouillage = client.post(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/verrouiller",
        headers=headers_enseignant,
    )
    assert verrouillage.status_code == 200
    assert verrouillage.json()["donnees"]["evaluation"]["est_verrouillee"] is True

    modification_apres_publication = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 18}]},
        headers=headers_enseignant,
    )
    assert modification_apres_publication.status_code == 403


def test_notes_refuse_note_superieure_au_maximum(client: TestClient, suffixe: str):
    token_enseignant = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token_enseignant}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes("WEB202")

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Controle maximum {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
        },
        headers=headers,
    )
    assert creation.status_code == 201
    evaluation_id = creation.json()["donnees"]["evaluation"]["id"]

    encodage = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 21}]},
        headers=headers,
    )
    assert encodage.status_code == 400
    assert "note maximale" in encodage.json()["message"]


def test_enseignant_non_affecte_ou_sans_profil_refuse(client: TestClient, suffixe: str):
    token_doyen_enseignant = _connexion(client, "doyen@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token_doyen_enseignant}"}
    cours_id, type_evaluation_id, _etudiant_id = _references_notes()

    reponse = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Refus profil {suffixe}",
            "note_maximale": 20,
            "ponderation": 10,
        },
        headers=headers,
    )
    assert reponse.status_code == 403


def test_evaluations_types_ponderation_et_roster_securises(client: TestClient, suffixe: str):
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes("WEB202")

    types = client.get("/api/v1/enseignant/types-evaluations", headers=headers)
    assert types.status_code == 200
    assert {item["nom"] for item in types.json()["donnees"]["types"]} >= {
        "interrogation",
        "travail_pratique",
        "examen",
        "autre",
    }

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Evaluation complete {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
        },
        headers=headers,
    )
    assert creation.status_code == 201
    evaluation = creation.json()["donnees"]["evaluation"]
    evaluation_id = evaluation["id"]
    assert evaluation["cree_par"] > 0
    assert evaluation["statut"] == "brouillon"
    assert evaluation["type_evaluation"]["nom"] == "examen"

    depassement = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": "Ponderation depassee",
            "note_maximale": 20,
            "ponderation": 1,
        },
        headers=headers,
    )
    assert depassement.status_code == 400

    for payload in (
        {"titre": ""},
        {"ponderation": 0},
        {"note_maximale": 0},
    ):
        invalide = {
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Validation {suffixe}",
            "note_maximale": 20,
            "ponderation": 1,
            **payload,
        }
        reponse = client.post(
            f"/api/v1/enseignant/cours/{cours_id}/evaluations",
            json=invalide,
            headers=headers,
        )
        assert reponse.status_code == 422

    type_invalide = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": 999999,
            "titre": "Type absent",
            "note_maximale": 20,
            "ponderation": 1,
        },
        headers=headers,
    )
    assert type_invalide.status_code == 404

    modification = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}",
        json={"ponderation": 50},
        headers=headers,
    )
    assert modification.status_code == 200
    assert modification.json()["donnees"]["evaluation"]["ponderation"] == 50

    notes = client.get(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        headers=headers,
    )
    assert notes.status_code == 200
    roster = notes.json()["donnees"]["etudiants"]
    assert any(item["id"] == etudiant_id for item in roster)
    assert all("mot_de_passe" not in item and "email" not in item for item in roster)

    note_zero = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 0}]},
        headers=headers,
    )
    assert note_zero.status_code == 200
    assert note_zero.json()["donnees"]["notes"][0]["note_obtenue"] == 0

    note_modifiee = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 15}]},
        headers=headers,
    )
    assert note_modifiee.status_code == 200
    assert note_modifiee.json()["donnees"]["notes"][0]["note_obtenue"] == 15

    note_negative = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": -1}]},
        headers=headers,
    )
    assert note_negative.status_code == 422

    note_trop_haute = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 21}]},
        headers=headers,
    )
    assert note_trop_haute.status_code == 400

    doublon = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={
            "notes": [
                {"etudiant_id": etudiant_id, "note_obtenue": 12},
                {"etudiant_id": etudiant_id, "note_obtenue": 13},
            ]
        },
        headers=headers,
    )
    assert doublon.status_code == 422

    etudiant_hors_cours = 999999
    hors_cours = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_hors_cours, "note_obtenue": 12}]},
        headers=headers,
    )
    assert hors_cours.status_code == 400


def test_evaluations_et_notes_reservees_a_leur_enseignant(client: TestClient, token_admin: str, suffixe: str):
    token_auteur = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers_auteur = {"Authorization": f"Bearer {token_auteur}"}
    headers_admin = {"Authorization": f"Bearer {token_admin}"}
    cours_id, type_evaluation_id, etudiant_id = _references_notes("WEB202")

    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": f"Evaluation auteur {suffixe}",
            "note_maximale": 20,
            "ponderation": 100,
        },
        headers=headers_auteur,
    )
    assert creation.status_code == 201
    evaluation_id = creation.json()["donnees"]["evaluation"]["id"]

    enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Notes",
                "postnom": "Second",
                "prenom": "Prof",
                "email": f"second.notes.{suffixe}@smartfaculty.test",
                "mot_de_passe": "Smart@123456",
            },
            "matricule_agent": f"ENS-NOTES-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers=headers_admin,
    )
    assert enseignant.status_code == 201
    enseignant_id = enseignant.json()["donnees"]["id"]

    affectation = client.post(
        f"/api/v1/cours/{cours_id}/enseignants",
        json={
            "enseignant_id": enseignant_id,
            "type_intervenant": "assistant",
            "est_responsable": False,
        },
        headers=headers_admin,
    )
    assert affectation.status_code == 201

    token_second = _connexion(
        client,
        f"second.notes.{suffixe}@smartfaculty.test",
        "enseignant",
    )
    headers_second = {"Authorization": f"Bearer {token_second}"}
    assert client.get(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        headers=headers_second,
    ).status_code == 200

    modification = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}",
        json={"titre": "Modification interdite"},
        headers=headers_second,
    )
    assert modification.status_code == 403

    notes = client.put(
        f"/api/v1/enseignant/evaluations/{evaluation_id}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 12}]},
        headers=headers_second,
    )
    assert notes.status_code == 403

    cours_non_affecte, _, _ = _references_notes("WEB202")
    token_enseignant_sans_cours = _connexion(client, "doyen@smartfaculty.test", "enseignant")
    cours_refuse = client.get(
        f"/api/v1/enseignant/cours/{cours_non_affecte}/evaluations",
        headers={"Authorization": f"Bearer {token_enseignant_sans_cours}"},
    )
    assert cours_refuse.status_code == 403


def test_apercu_resultats_cours_distingue_absence_zero_et_publication(
    client: TestClient,
    suffixe: str,
):
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token}"}
    cours_id, _type_examen_id, etudiant_id = _references_notes("WEB202")
    type_interrogation_id = _type_evaluation_id("interrogation")
    type_examen_id = _type_evaluation_id("examen")

    evaluations = []
    for type_id, titre, ponderation in (
        (type_interrogation_id, f"Interrogation resultat {suffixe}", 40),
        (type_examen_id, f"Examen resultat {suffixe}", 60),
    ):
        creation = client.post(
            f"/api/v1/enseignant/cours/{cours_id}/evaluations",
            json={
                "type_evaluation_id": type_id,
                "titre": titre,
                "note_maximale": 20,
                "ponderation": ponderation,
            },
            headers=headers,
        )
        assert creation.status_code == 201
        evaluations.append(creation.json()["donnees"]["evaluation"]["id"])

    note_zero = client.put(
        f"/api/v1/enseignant/evaluations/{evaluations[0]}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 0}]},
        headers=headers,
    )
    assert note_zero.status_code == 200

    apercu_incomplet = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/apercu",
        headers=headers,
    )
    assert apercu_incomplet.status_code == 200
    donnees_incompletes = apercu_incomplet.json()["donnees"]
    assert donnees_incompletes["etat"] == "incomplet"
    assert donnees_incompletes["total_ponderation"] == 100
    assert donnees_incompletes["notes_manquantes"] == 1
    etudiant_incomplet = donnees_incompletes["etudiants"][0]
    assert etudiant_incomplet["resultat_provisoire_sur_100"] == 0
    assert etudiant_incomplet["resultat_officiel_sur_100"] is None
    assert etudiant_incomplet["notes_manquantes"][0]["evaluation_id"] == evaluations[1]
    assert "credits_obtenus" not in etudiant_incomplet
    assert "statut_resultat" not in etudiant_incomplet

    note_complete = client.put(
        f"/api/v1/enseignant/evaluations/{evaluations[1]}/notes",
        json={"notes": [{"etudiant_id": etudiant_id, "note_obtenue": 20}]},
        headers=headers,
    )
    assert note_complete.status_code == 200

    apercu_calculable = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/apercu",
        headers=headers,
    )
    assert apercu_calculable.json()["donnees"]["etat"] == "incomplet"
    assert apercu_calculable.json()["donnees"]["peut_publier"] is True

    publication = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/publier",
        headers=headers,
    )
    assert publication.status_code == 200
    resultat = publication.json()["donnees"]
    assert resultat["etat"] == "verrouille"
    assert resultat["etudiants"][0]["resultat_officiel_sur_100"] == 60
    assert resultat["evaluations_verrouillees"] is True
    assert all(item["statut"] == "publiee" for item in resultat["evaluations"])
    assert all(item["est_verrouillee"] is True for item in resultat["evaluations"])

    publication_rejouee = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/publier",
        headers=headers,
    )
    assert publication_rejouee.status_code == 200
    assert publication_rejouee.json()["donnees"]["etat"] == "verrouille"

    valve = client.get("/api/v1/enseignant/valve", headers=headers)
    assert valve.status_code == 200
    annonces_resultats = [
        item
        for item in valve.json()["donnees"]["elements"]
        if item["titre"] == "Resultats du cours disponibles"
    ]
    assert len(annonces_resultats) == 1
    assert "notes" not in annonces_resultats[0]


def test_publication_resultats_refuse_incomplet_et_autorisations(client: TestClient, token_etudiant: str):
    token = _connexion(client, "enseignant@smartfaculty.test", "enseignant")
    headers = {"Authorization": f"Bearer {token}"}
    cours_id, type_evaluation_id, _etudiant_id = _references_notes("WEB202")
    creation = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/evaluations",
        json={
            "type_evaluation_id": type_evaluation_id,
            "titre": "Publication incomplete",
            "note_maximale": 20,
            "ponderation": 100,
        },
        headers=headers,
    )
    assert creation.status_code == 201

    publication_incomplete = client.post(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/publier",
        headers=headers,
    )
    assert publication_incomplete.status_code == 400

    refus_etudiant = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/apercu",
        headers={"Authorization": f"Bearer {token_etudiant}"},
    )
    assert refus_etudiant.status_code == 403

    token_sans_cours = _connexion(client, "doyen@smartfaculty.test", "enseignant")
    refus_autre_enseignant = client.get(
        f"/api/v1/enseignant/cours/{cours_id}/resultats/apercu",
        headers={"Authorization": f"Bearer {token_sans_cours}"},
    )
    assert refus_autre_enseignant.status_code == 403
