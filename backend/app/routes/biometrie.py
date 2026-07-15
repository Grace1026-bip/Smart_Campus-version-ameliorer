from __future__ import annotations

from fastapi import APIRouter, Depends, File, Form, UploadFile, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_role
from app.exceptions.erreurs import ConflitDonnees
from app.schemas.biometrie import MotifBiometrique
from app.services import biometrie as service
from app.utilitaires.reponses import reponse_succes


routeur_biometrie = APIRouter(tags=["biometrie"])


async def _captures(fichiers: list[UploadFile]) -> list[tuple[bytes, str | None]]:
    if not service.MIN_CAPTURES <= len(fichiers) <= service.MAX_CAPTURES:
        raise ConflitDonnees("Le nombre de captures doit etre compris entre 3 et 5")
    captures: list[tuple[bytes, str | None]] = []
    for fichier in fichiers:
        if (fichier.filename or "").lower().endswith(".pkl"):
            raise ConflitDonnees("Les fichiers pickle sont interdits")
        captures.append((await fichier.read(), fichier.content_type))
    return captures


@routeur_biometrie.get("/appariteur/biometrie/etudiants/{etudiant_id}")
def obtenir_profil(
    etudiant_id: int,
    _contexte: ContexteUtilisateur = Depends(exiger_role("appariteur")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etat biometrique recupere", service.obtenir_profil(session, etudiant_id))


@routeur_biometrie.post("/appariteur/biometrie/etudiants/{etudiant_id}/enroler", status_code=status.HTTP_201_CREATED)
async def enroler(
    etudiant_id: int,
    fichiers: list[UploadFile] = File(..., alias="images"),
    consentement: bool = Form(...),
    contexte: ContexteUtilisateur = Depends(exiger_role("appariteur")),
    session: Session = Depends(obtenir_session),
):
    captures = await _captures(fichiers)
    return reponse_succes(
        "Profil biometrique enregistre",
        service.enroler(session, contexte.utilisateur.id, etudiant_id, captures, consentement),
        status.HTTP_201_CREATED,
    )


@routeur_biometrie.post("/appariteur/biometrie/etudiants/{etudiant_id}/reenroler", status_code=status.HTTP_201_CREATED)
async def reenroler(
    etudiant_id: int,
    fichiers: list[UploadFile] = File(..., alias="images"),
    consentement: bool = Form(...),
    motif: str = Form(...),
    contexte: ContexteUtilisateur = Depends(exiger_role("appariteur")),
    session: Session = Depends(obtenir_session),
):
    captures = await _captures(fichiers)
    return reponse_succes(
        "Profil biometrique versionne",
        service.enroler(
            session,
            contexte.utilisateur.id,
            etudiant_id,
            captures,
            consentement,
            reenrollement=True,
            motif=motif,
        ),
        status.HTTP_201_CREATED,
    )


@routeur_biometrie.post("/appariteur/biometrie/etudiants/{etudiant_id}/suspendre")
def suspendre(
    etudiant_id: int,
    donnees: MotifBiometrique,
    contexte: ContexteUtilisateur = Depends(exiger_role("appariteur")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Profil biometrique suspendu", service.changer_statut(session, contexte.utilisateur.id, etudiant_id, "suspendu", donnees.motif))


@routeur_biometrie.post("/appariteur/biometrie/etudiants/{etudiant_id}/revoquer")
def revoquer(
    etudiant_id: int,
    donnees: MotifBiometrique,
    contexte: ContexteUtilisateur = Depends(exiger_role("appariteur")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Profil biometrique revoque", service.changer_statut(session, contexte.utilisateur.id, etudiant_id, "revoque", donnees.motif))


@routeur_biometrie.post("/surveillant/seances/{seance_id}/reconnaissance-faciale")
async def reconnaissance_faciale(
    seance_id: int,
    fichiers: list[UploadFile] = File(..., alias="images"),
    contexte: ContexteUtilisateur = Depends(exiger_role("surveillant")),
    session: Session = Depends(obtenir_session),
):
    captures = await _captures(fichiers)
    return reponse_succes(
        "Reconnaissance faciale traitee",
        service.reconnaitre(session, contexte.utilisateur.id, seance_id, captures),
    )
