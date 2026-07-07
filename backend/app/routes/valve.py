from __future__ import annotations

from datetime import date

from fastapi import APIRouter, Depends, File, Query, UploadFile, status
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import ContexteUtilisateur, exiger_un_des_roles
from app.schemas.pagination import ParametresPagination
from app.schemas.valve import PublicationValveCreation, PublicationValveModification
from app.services import valve as service
from app.utilitaires.reponses import reponse_succes


routeur_valve = APIRouter(tags=["valve"])


def _pagination(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
) -> ParametresPagination:
    return ParametresPagination(page=page, taille=taille, recherche=recherche)


def _reponse_fichier(session: Session, contexte: ContexteUtilisateur, piece_id: int) -> FileResponse:
    chemin, nom_original, type_mime = service.obtenir_piece_jointe_autorisee(
        session,
        contexte.utilisateur.id,
        contexte.role_actif,
        piece_id,
    )
    return FileResponse(path=chemin, filename=nom_original, media_type=type_mime)


@routeur_valve.get("/enseignant/valve")
def route_valve_enseignant(
    pagination: ParametresPagination = Depends(_pagination),
    cours_id: int | None = Query(default=None, gt=0),
    type_publication: str | None = Query(default=None, max_length=60),
    date_debut: date | None = None,
    date_fin: date | None = None,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.lister_valve_enseignant(
        session,
        contexte.utilisateur.id,
        pagination,
        cours_id,
        type_publication,
        date_debut,
        date_fin,
    )
    return reponse_succes("Publications recuperees", donnees)


@routeur_valve.post("/enseignant/valve/publications", status_code=status.HTTP_201_CREATED)
def route_creer_publication(
    donnees: PublicationValveCreation,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.creer_publication(session, contexte.utilisateur.id, donnees)
    return reponse_succes("Publication creee", {"publication": publication}, status.HTTP_201_CREATED)


@routeur_valve.get("/enseignant/valve/publications/{publication_id}")
def route_obtenir_publication_enseignant(
    publication_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.obtenir_publication_enseignant(session, contexte.utilisateur.id, publication_id)
    return reponse_succes("Publication recuperee", {"publication": publication})


@routeur_valve.put("/enseignant/valve/publications/{publication_id}")
def route_modifier_publication(
    publication_id: int,
    donnees: PublicationValveModification,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.modifier_publication(session, contexte.utilisateur.id, publication_id, donnees)
    return reponse_succes("Publication modifiee", {"publication": publication})


@routeur_valve.delete("/enseignant/valve/publications/{publication_id}")
def route_supprimer_publication(
    publication_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.archiver_publication(session, contexte.utilisateur.id, publication_id)
    return reponse_succes("Publication archivee", {"publication": publication})


@routeur_valve.post("/enseignant/valve/publications/{publication_id}/publier")
def route_publier_publication(
    publication_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.publier_publication(session, contexte.utilisateur.id, publication_id)
    return reponse_succes("Publication publiee", {"publication": publication})


@routeur_valve.post("/enseignant/valve/publications/{publication_id}/archiver")
def route_archiver_publication(
    publication_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.archiver_publication(session, contexte.utilisateur.id, publication_id)
    return reponse_succes("Publication archivee", {"publication": publication})


@routeur_valve.post(
    "/enseignant/valve/publications/{publication_id}/pieces-jointes",
    status_code=status.HTTP_201_CREATED,
)
def route_ajouter_piece_jointe(
    publication_id: int,
    fichier: UploadFile = File(...),
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    piece = service.ajouter_piece_jointe(session, contexte.utilisateur.id, publication_id, fichier)
    return reponse_succes("Piece jointe ajoutee", {"piece_jointe": piece}, status.HTTP_201_CREATED)


@routeur_valve.delete("/enseignant/valve/pieces-jointes/{piece_id}")
def route_archiver_piece_jointe(
    piece_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    piece = service.archiver_piece_jointe(session, contexte.utilisateur.id, piece_id)
    return reponse_succes("Piece jointe archivee", {"piece_jointe": piece})


@routeur_valve.get("/enseignant/valve/pieces-jointes/{piece_id}/telecharger")
def route_telecharger_piece_enseignant(
    piece_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("enseignant")),
    session: Session = Depends(obtenir_session),
):
    return _reponse_fichier(session, contexte, piece_id)


@routeur_valve.get("/etudiant/valve")
def route_valve_etudiant(
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Valve etudiante recuperee", service.lister_valve_etudiant(session, contexte.utilisateur.id))


@routeur_valve.get("/etudiant/valve/cours/{cours_id}")
def route_valve_cours_etudiant(
    cours_id: int,
    pagination: ParametresPagination = Depends(_pagination),
    type_publication: str | None = Query(default=None, max_length=60),
    date_debut: date | None = None,
    date_fin: date | None = None,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    donnees = service.obtenir_cours_valve_etudiant(
        session,
        contexte.utilisateur.id,
        cours_id,
        pagination,
        type_publication,
        date_debut,
        date_fin,
    )
    return reponse_succes("Cours et publications recuperes", donnees)


@routeur_valve.get("/etudiant/valve/publications/{publication_id}")
def route_obtenir_publication_etudiant(
    publication_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    publication = service.obtenir_publication_etudiant(session, contexte.utilisateur.id, publication_id)
    return reponse_succes("Publication recuperee", {"publication": publication})


@routeur_valve.get("/etudiant/valve/pieces-jointes/{piece_id}/telecharger")
def route_telecharger_piece_etudiant(
    piece_id: int,
    contexte: ContexteUtilisateur = Depends(exiger_un_des_roles("etudiant")),
    session: Session = Depends(obtenir_session),
):
    return _reponse_fichier(session, contexte, piece_id)
