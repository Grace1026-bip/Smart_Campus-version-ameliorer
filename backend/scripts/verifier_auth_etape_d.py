from __future__ import annotations

import sys
from pathlib import Path

from fastapi.testclient import TestClient

RACINE_BACKEND = Path(__file__).resolve().parents[1]
if str(RACINE_BACKEND) not in sys.path:
    sys.path.insert(0, str(RACINE_BACKEND))

from app.main import app


def afficher(label: str, reponse):
    corps = reponse.json()
    print(f"{label}: {reponse.status_code} - {corps.get('message')}")
    return corps


def main() -> None:
    client = TestClient(app)

    connexion = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
            "appareil": "testclient",
        },
    )
    corps_connexion = afficher("login_ok", connexion)
    assert connexion.status_code == 200

    donnees = corps_connexion["donnees"]
    access_token = donnees["access_token"]
    refresh_token = donnees["refresh_token"]

    moi = client.get(
        "/api/v1/auth/moi",
        headers={"Authorization": f"Bearer {access_token}"},
    )
    afficher("moi_ok", moi)
    assert moi.status_code == 200

    sans_token = client.get("/api/v1/auth/moi")
    afficher("moi_without_token", sans_token)
    assert sans_token.status_code == 401

    doyen_enseignant = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "doyen@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "enseignant",
        },
    )
    afficher("multi_role_login_ok", doyen_enseignant)
    assert doyen_enseignant.status_code == 200

    mauvais_mot_de_passe = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "faux",
            "role": "etudiant",
        },
    )
    afficher("bad_password", mauvais_mot_de_passe)
    assert mauvais_mot_de_passe.status_code == 401

    mauvais_role = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "enseignant",
        },
    )
    afficher("bad_role", mauvais_role)
    assert mauvais_role.status_code == 401

    actualisation = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": refresh_token, "role": "etudiant"},
    )
    corps_actualisation = afficher("refresh_ok", actualisation)
    assert actualisation.status_code == 200

    reutilisation_refresh = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": refresh_token, "role": "etudiant"},
    )
    afficher("refresh_reuse_old", reutilisation_refresh)
    assert reutilisation_refresh.status_code == 401

    nouveau_access_token = corps_actualisation["donnees"]["access_token"]
    nouveau_refresh_token = corps_actualisation["donnees"]["refresh_token"]
    deconnexion = client.post(
        "/api/v1/auth/deconnexion",
        json={"refresh_token": nouveau_refresh_token},
        headers={"Authorization": f"Bearer {nouveau_access_token}"},
    )
    afficher("logout_ok", deconnexion)
    assert deconnexion.status_code == 200

    refresh_apres_deconnexion = client.post(
        "/api/v1/auth/actualiser",
        json={"refresh_token": nouveau_refresh_token, "role": "etudiant"},
    )
    afficher("refresh_after_logout", refresh_apres_deconnexion)
    assert refresh_apres_deconnexion.status_code == 401

    connexion_mdp = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    corps_mdp = afficher("password_change_login", connexion_mdp)
    assert connexion_mdp.status_code == 200
    token_mdp = corps_mdp["donnees"]["access_token"]

    changement = client.put(
        "/api/v1/auth/mot-de-passe",
        json={
            "ancien_mot_de_passe": "Smart@123456",
            "nouveau_mot_de_passe": "Smart@123456Temp",
        },
        headers={"Authorization": f"Bearer {token_mdp}"},
    )
    afficher("password_change_ok", changement)
    assert changement.status_code == 200

    ancien_mdp_refuse = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456",
            "role": "etudiant",
        },
    )
    afficher("old_password_rejected", ancien_mdp_refuse)
    assert ancien_mdp_refuse.status_code == 401

    nouveau_mdp = client.post(
        "/api/v1/auth/connexion",
        json={
            "email": "etudiant@smartfaculty.test",
            "mot_de_passe": "Smart@123456Temp",
            "role": "etudiant",
        },
    )
    corps_nouveau_mdp = afficher("new_password_login_ok", nouveau_mdp)
    assert nouveau_mdp.status_code == 200

    restauration = client.put(
        "/api/v1/auth/mot-de-passe",
        json={
            "ancien_mot_de_passe": "Smart@123456Temp",
            "nouveau_mot_de_passe": "Smart@123456",
        },
        headers={"Authorization": f"Bearer {corps_nouveau_mdp['donnees']['access_token']}"},
    )
    afficher("password_restore_ok", restauration)
    assert restauration.status_code == 200

    print("Verification auth etape D terminee avec succes.")


if __name__ == "__main__":
    main()
