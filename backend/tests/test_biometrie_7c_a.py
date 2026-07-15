from __future__ import annotations

from io import BytesIO

import pytest
from PIL import Image
from fastapi.testclient import TestClient

from app.services import biometrie
from app.services.moteur_faciale import AnalyseVisage
from tests.test_presences_academiques import _connecter, _entetes, _enrolement, _inscription, _references
from tests.test_presences_7b import _creer_seance, _ouvrir


class FauxMoteur:
    version = "faux-test-7c-a"

    def __init__(self, encodages: list[tuple[float, ...]]):
        self.encodages = encodages
        self.index = 0

    def analyser(self, _image: bytes) -> AnalyseVisage:
        valeur = self.encodages[min(self.index, len(self.encodages) - 1)]
        self.index += 1
        return AnalyseVisage(valeur)


def _image() -> bytes:
    sortie = BytesIO()
    Image.new("RGB", (160, 160), color=(180, 140, 110)).save(sortie, format="PNG")
    return sortie.getvalue()


def _fichiers() -> list[tuple[str, tuple[str, bytes, str]]]:
    return [("images", (f"capture-{index}.png", _image(), "image/png")) for index in range(3)]


@pytest.fixture()
def token_surveillant(client: TestClient) -> str:
    return _connecter(client, "surveillant@smartfaculty.test", "surveillant")


def test_appariteur_enrole_sans_exposer_encodage(client: TestClient, monkeypatch, suffixe: str):
    _, _, _, etudiant_id, _ = _references()
    _enrolement("50", suffixe)
    moteur = FauxMoteur([(0.1, 0.2), (0.1, 0.2), (0.1, 0.2)])
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: moteur)
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")

    reponse = client.post(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}/enroler",
        data={"consentement": "true"},
        files=_fichiers(),
        headers=_entetes(token),
    )

    assert reponse.status_code == 201, reponse.text
    donnees = reponse.json()["donnees"]
    assert donnees["statut"] == "actif"
    assert donnees["nombre_encodages"] == 3
    assert "encodage_binaire" not in reponse.text

    profil = client.get(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}", headers=_entetes(token)
    )
    assert profil.status_code == 200
    assert "encodage_binaire" not in profil.text


def test_enrolement_refuse_capture_invalide(client: TestClient, monkeypatch, suffixe: str):
    _, _, _, etudiant_id, _ = _references()
    _enrolement("50", suffixe)
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: FauxMoteur([(0.1, 0.2)] * 3))
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    fichiers = [("images", ("capture.txt", b"secret", "text/plain")) for _ in range(3)]

    reponse = client.post(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}/enroler",
        data={"consentement": "true"},
        files=fichiers,
        headers=_entetes(token),
    )

    assert reponse.status_code == 409
    assert "secret" not in reponse.text


def test_reenrolement_revoque_ancienne_version(client: TestClient, monkeypatch, suffixe: str):
    _, _, _, etudiant_id, _ = _references()
    _enrolement("50", suffixe)
    token = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: FauxMoteur([(0.1, 0.2)] * 3))
    url = f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}/enroler"
    assert client.post(url, data={"consentement": "true"}, files=_fichiers(), headers=_entetes(token)).status_code == 201

    moteur = FauxMoteur([(0.2, 0.3)] * 3)
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: moteur)
    reponse = client.post(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}/reenroler",
        data={"consentement": "true", "motif": "Nouvelle captation valide"},
        files=_fichiers(),
        headers=_entetes(token),
    )
    assert reponse.status_code == 201, reponse.text
    profil = client.get(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}", headers=_entetes(token)
    )
    assert profil.status_code == 200
    profils = profil.json()["donnees"]["profils"]
    assert [item["statut"] for item in profils[:2]] == ["actif", "revoque"]


def test_reconnaissance_reutilise_controle_acces_et_ne_double_pas(client: TestClient, monkeypatch, suffixe: str, token_surveillant: str):
    _enrolement("50", suffixe)
    _inscription()
    _, _, _, etudiant_id, _ = _references()
    token_appariteur = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: FauxMoteur([(0.1, 0.2)] * 3))
    enrollement = client.post(
        f"/api/v1/appariteur/biometrie/etudiants/{etudiant_id}/enroler",
        data={"consentement": "true"},
        files=_fichiers(),
        headers=_entetes(token_appariteur),
    )
    assert enrollement.status_code == 201, enrollement.text
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    reconnaissance = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/reconnaissance-faciale",
        files=_fichiers(),
        headers=_entetes(token_surveillant),
    )
    assert reconnaissance.status_code == 200, reconnaissance.text
    donnees = reconnaissance.json()["donnees"]
    assert donnees["visage_reconnu"] is True
    assert donnees["presence"]["methode_identification"] == "reconnaissance_faciale"
    seconde = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/reconnaissance-faciale",
        files=_fichiers(),
        headers=_entetes(token_surveillant),
    )
    assert seconde.status_code == 200
    assert seconde.json()["donnees"]["motif"] == "deja_enregistre"


def test_visage_inconnu_ne_cree_pas_presence(client: TestClient, monkeypatch, suffixe: str, token_surveillant: str):
    _enrolement("50", suffixe)
    _inscription()
    _, _, _, _, _ = _references()
    token_appariteur = _connecter(client, "appariteur@smartfaculty.test", "appariteur")
    monkeypatch.setattr(biometrie, "obtenir_moteur", lambda: FauxMoteur([(0.1, 0.2)] * 3))
    seance_id = _creer_seance(client, token_surveillant)
    _ouvrir(client, token_surveillant, seance_id)
    # No active biometric profile exists, so this must be a refusal without a row.
    reponse = client.post(
        f"/api/v1/surveillant/seances/{seance_id}/reconnaissance-faciale",
        files=_fichiers(),
        headers=_entetes(token_surveillant),
    )
    assert reponse.status_code == 200
    assert reponse.json()["donnees"]["motif"] == "visage_inconnu"
    assert token_appariteur
