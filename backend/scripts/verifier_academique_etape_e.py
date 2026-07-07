from __future__ import annotations

import sys
from datetime import date
from pathlib import Path
from time import time

from fastapi.testclient import TestClient
from sqlalchemy import select

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.base_de_donnees.connexion import SessionLocale
from app.main import app
from app.modeles import AnneeAcademique, Semestre


def afficher(label: str, reponse):
    corps = reponse.json()
    print(f"{label}: {reponse.status_code} - {corps.get('message')}")
    return corps


def connecter(client: TestClient, email: str, role: str) -> str:
    reponse = client.post(
        "/api/v1/auth/connexion",
        json={"email": email, "mot_de_passe": "Smart@123456", "role": role},
    )
    corps = afficher(f"login_{role}", reponse)
    assert reponse.status_code == 200
    return corps["donnees"]["access_token"]


def references_academiques() -> tuple[int, int]:
    with SessionLocale() as session:
        annee = session.scalar(select(AnneeAcademique).where(AnneeAcademique.est_active.is_(True)))
        semestre = session.scalar(select(Semestre).order_by(Semestre.id))
        assert annee is not None
        assert semestre is not None
        return annee.id, semestre.id


def main() -> None:
    client = TestClient(app)
    suffixe = str(int(time()))
    annee_id, semestre_id = references_academiques()

    admin_token = connecter(client, "admin@smartfaculty.test", "administrateur")
    etudiant_token = connecter(client, "etudiant@smartfaculty.test", "etudiant")
    headers_admin = {"Authorization": f"Bearer {admin_token}"}
    headers_etudiant = {"Authorization": f"Bearer {etudiant_token}"}

    refus_etudiant = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"Test refus {suffixe}",
            "niveau": "L0",
            "annee_academique_id": annee_id,
        },
        headers=headers_etudiant,
    )
    afficher("student_cannot_create_promotion", refus_etudiant)
    assert refus_etudiant.status_code == 403

    creation_promotion = client.post(
        "/api/v1/promotions",
        json={
            "nom": f"L3 Test {suffixe}",
            "niveau": "L3",
            "description": "Promotion de verification etape E",
            "annee_academique_id": annee_id,
        },
        headers=headers_admin,
    )
    corps_promotion = afficher("create_promotion", creation_promotion)
    assert creation_promotion.status_code == 201
    promotion_id = corps_promotion["donnees"]["id"]

    liste_promotions = client.get("/api/v1/promotions?page=1&taille=5&recherche=L3", headers=headers_admin)
    corps_liste_promotions = afficher("list_promotions", liste_promotions)
    assert liste_promotions.status_code == 200
    assert corps_liste_promotions["donnees"]["total"] >= 1

    modification_promotion = client.put(
        f"/api/v1/promotions/{promotion_id}",
        json={"description": "Promotion modifiee par verification"},
        headers=headers_admin,
    )
    afficher("update_promotion", modification_promotion)
    assert modification_promotion.status_code == 200

    creation_cours = client.post(
        "/api/v1/cours",
        json={
            "code": f"TST{suffixe[-5:]}",
            "intitule": "Cours verification etape E",
            "description": "Cours cree par test HTTP",
            "nombre_heures": 30,
            "nombre_credits": 3,
            "semestre_id": semestre_id,
            "promotion_id": promotion_id,
        },
        headers=headers_admin,
    )
    corps_cours = afficher("create_cours", creation_cours)
    assert creation_cours.status_code == 201
    cours_id = corps_cours["donnees"]["id"]

    modification_cours = client.put(
        f"/api/v1/cours/{cours_id}",
        json={"nombre_heures": 36, "nombre_credits": 4},
        headers=headers_admin,
    )
    afficher("update_cours", modification_cours)
    assert modification_cours.status_code == 200

    creation_enseignant = client.post(
        "/api/v1/enseignants",
        json={
            "utilisateur": {
                "nom": "Test",
                "postnom": "EtapeE",
                "prenom": "Enseignant",
                "email": f"enseignant.e{suffixe}@smartfaculty.test",
                "mot_de_passe": "Smart@123456",
                "telephone": "+243000000001",
            },
            "matricule_agent": f"ENS-E-{suffixe}",
            "grade": "Assistant",
            "departement": "Informatique",
        },
        headers=headers_admin,
    )
    corps_enseignant = afficher("create_enseignant", creation_enseignant)
    assert creation_enseignant.status_code == 201
    enseignant_id = corps_enseignant["donnees"]["id"]

    creation_etudiant = client.post(
        "/api/v1/etudiants",
        json={
            "utilisateur": {
                "nom": "Test",
                "postnom": "EtapeE",
                "prenom": "Etudiant",
                "email": f"etudiant.e{suffixe}@smartfaculty.test",
                "mot_de_passe": "Smart@123456",
                "telephone": "+243000000002",
            },
            "matricule": f"SF-E-{suffixe}",
            "promotion_id": promotion_id,
            "date_inscription": str(date.today()),
        },
        headers=headers_admin,
    )
    corps_etudiant = afficher("create_etudiant", creation_etudiant)
    assert creation_etudiant.status_code == 201
    etudiant_id = corps_etudiant["donnees"]["id"]

    affectation = client.post(
        f"/api/v1/cours/{cours_id}/enseignants",
        json={
            "enseignant_id": enseignant_id,
            "type_intervenant": "professeur",
            "est_responsable": True,
        },
        headers=headers_admin,
    )
    corps_affectation = afficher("assign_teacher", affectation)
    assert affectation.status_code == 201
    affectation_id = corps_affectation["donnees"]["id"]

    modification_affectation = client.put(
        f"/api/v1/affectations/{affectation_id}",
        json={"type_intervenant": "charge_de_cours", "est_responsable": False},
        headers=headers_admin,
    )
    afficher("update_assignment", modification_affectation)
    assert modification_affectation.status_code == 200

    inscription = client.post(
        "/api/v1/inscriptions-cours",
        json={
            "etudiant_id": etudiant_id,
            "cours_id": cours_id,
            "annee_academique_id": annee_id,
            "date_inscription": str(date.today()),
        },
        headers=headers_admin,
    )
    corps_inscription = afficher("enroll_student", inscription)
    assert inscription.status_code == 201
    inscription_id = corps_inscription["donnees"]["id"]

    retrait_inscription = client.delete(f"/api/v1/inscriptions-cours/{inscription_id}", headers=headers_admin)
    afficher("withdraw_enrollment", retrait_inscription)
    assert retrait_inscription.status_code == 200
    assert retrait_inscription.json()["donnees"]["statut"] == "retiree"

    retrait_affectation = client.delete(f"/api/v1/affectations/{affectation_id}", headers=headers_admin)
    afficher("delete_assignment", retrait_affectation)
    assert retrait_affectation.status_code == 200

    desactivation_cours = client.delete(f"/api/v1/cours/{cours_id}", headers=headers_admin)
    afficher("deactivate_cours", desactivation_cours)
    assert desactivation_cours.status_code == 200

    desactivation_promotion = client.delete(f"/api/v1/promotions/{promotion_id}", headers=headers_admin)
    afficher("deactivate_promotion", desactivation_promotion)
    assert desactivation_promotion.status_code == 200

    print("Verification academique etape E terminee avec succes.")


if __name__ == "__main__":
    main()
