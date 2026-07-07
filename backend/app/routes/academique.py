from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.orm import Session

from app.base_de_donnees.connexion import obtenir_session
from app.dependances.authentification import exiger_un_des_roles, obtenir_utilisateur_connecte
from app.schemas.academique import (
    AffectationEnseignantCreation,
    AffectationEnseignantModification,
    CoursCreation,
    CoursModification,
    EnseignantCreation,
    EnseignantModification,
    EtudiantCreation,
    EtudiantModification,
    InscriptionCoursCreation,
    InscriptionCoursModification,
    PromotionCreation,
    PromotionModification,
)
from app.schemas.pagination import ParametresPagination
from app.services import academique as service
from app.utilitaires.reponses import reponse_succes


routeur_academique = APIRouter(tags=["gestion academique"])
lecture_auth = Depends(obtenir_utilisateur_connecte)
ecriture_academique = Depends(exiger_un_des_roles("appariteur", "administrateur"))


@routeur_academique.get("/promotions")
def route_lister_promotions(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
    annee_academique_id: int | None = Query(default=None, gt=0),
    est_active: bool | None = None,
    _contexte=lecture_auth,
    session: Session = Depends(obtenir_session),
):
    pagination = ParametresPagination(page=page, taille=taille, recherche=recherche)
    donnees = service.lister_promotions(session, pagination, annee_academique_id, est_active)
    return reponse_succes("Promotions recuperees", donnees)


@routeur_academique.get("/promotions/{promotion_id}")
def route_obtenir_promotion(
    promotion_id: int,
    _contexte=lecture_auth,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Promotion recuperee", service.obtenir_promotion(session, promotion_id))


@routeur_academique.post("/promotions", status_code=status.HTTP_201_CREATED)
def route_creer_promotion(
    donnees: PromotionCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Promotion creee", service.creer_promotion(session, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/promotions/{promotion_id}")
def route_modifier_promotion(
    promotion_id: int,
    donnees: PromotionModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Promotion modifiee", service.modifier_promotion(session, promotion_id, donnees))


@routeur_academique.delete("/promotions/{promotion_id}")
def route_desactiver_promotion(
    promotion_id: int,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    service.desactiver_promotion(session, promotion_id)
    return reponse_succes("Promotion desactivee")


@routeur_academique.get("/cours")
def route_lister_cours(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
    promotion_id: int | None = Query(default=None, gt=0),
    semestre_id: int | None = Query(default=None, gt=0),
    est_actif: bool | None = None,
    _contexte=lecture_auth,
    session: Session = Depends(obtenir_session),
):
    pagination = ParametresPagination(page=page, taille=taille, recherche=recherche)
    donnees = service.lister_cours(session, pagination, promotion_id, semestre_id, est_actif)
    return reponse_succes("Cours recuperes", donnees)


@routeur_academique.get("/cours/{cours_id}")
def route_obtenir_cours(
    cours_id: int,
    _contexte=lecture_auth,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Cours recupere", service.obtenir_cours(session, cours_id))


@routeur_academique.post("/cours", status_code=status.HTTP_201_CREATED)
def route_creer_cours(
    donnees: CoursCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Cours cree", service.creer_cours(session, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/cours/{cours_id}")
def route_modifier_cours(
    cours_id: int,
    donnees: CoursModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Cours modifie", service.modifier_cours(session, cours_id, donnees))


@routeur_academique.delete("/cours/{cours_id}")
def route_desactiver_cours(
    cours_id: int,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    service.desactiver_cours(session, cours_id)
    return reponse_succes("Cours desactive")


@routeur_academique.get("/etudiants")
def route_lister_etudiants(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
    promotion_id: int | None = Query(default=None, gt=0),
    _contexte=Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    pagination = ParametresPagination(page=page, taille=taille, recherche=recherche)
    return reponse_succes("Etudiants recuperes", service.lister_etudiants(session, pagination, promotion_id))


@routeur_academique.get("/etudiants/{etudiant_id}")
def route_obtenir_etudiant(
    etudiant_id: int,
    _contexte=Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etudiant recupere", service.obtenir_etudiant(session, etudiant_id))


@routeur_academique.post("/etudiants", status_code=status.HTTP_201_CREATED)
def route_creer_etudiant(
    donnees: EtudiantCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etudiant cree", service.creer_etudiant(session, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/etudiants/{etudiant_id}")
def route_modifier_etudiant(
    etudiant_id: int,
    donnees: EtudiantModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etudiant modifie", service.modifier_etudiant(session, etudiant_id, donnees))


@routeur_academique.get("/enseignants")
def route_lister_enseignants(
    page: int = Query(default=1, ge=1),
    taille: int = Query(default=20, ge=1, le=100),
    recherche: str | None = Query(default=None, max_length=120),
    departement: str | None = Query(default=None, max_length=150),
    _contexte=Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    pagination = ParametresPagination(page=page, taille=taille, recherche=recherche)
    return reponse_succes("Enseignants recuperes", service.lister_enseignants(session, pagination, departement))


@routeur_academique.get("/enseignants/{enseignant_id}")
def route_obtenir_enseignant(
    enseignant_id: int,
    _contexte=Depends(exiger_un_des_roles("appariteur", "doyen", "administrateur")),
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enseignant recupere", service.obtenir_enseignant(session, enseignant_id))


@routeur_academique.post("/enseignants", status_code=status.HTTP_201_CREATED)
def route_creer_enseignant(
    donnees: EnseignantCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enseignant cree", service.creer_enseignant(session, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/enseignants/{enseignant_id}")
def route_modifier_enseignant(
    enseignant_id: int,
    donnees: EnseignantModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enseignant modifie", service.modifier_enseignant(session, enseignant_id, donnees))


@routeur_academique.post("/cours/{cours_id}/enseignants", status_code=status.HTTP_201_CREATED)
def route_affecter_enseignant(
    cours_id: int,
    donnees: AffectationEnseignantCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Enseignant affecte au cours", service.affecter_enseignant(session, cours_id, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/affectations/{affectation_id}")
def route_modifier_affectation(
    affectation_id: int,
    donnees: AffectationEnseignantModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Affectation modifiee", service.modifier_affectation(session, affectation_id, donnees))


@routeur_academique.delete("/affectations/{affectation_id}")
def route_retirer_affectation(
    affectation_id: int,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    service.retirer_affectation(session, affectation_id)
    return reponse_succes("Affectation retiree")


@routeur_academique.post("/inscriptions-cours", status_code=status.HTTP_201_CREATED)
def route_inscrire_etudiant_cours(
    donnees: InscriptionCoursCreation,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Etudiant inscrit au cours", service.inscrire_etudiant_cours(session, donnees), status.HTTP_201_CREATED)


@routeur_academique.put("/inscriptions-cours/{inscription_id}")
def route_modifier_inscription(
    inscription_id: int,
    donnees: InscriptionCoursModification,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Inscription modifiee", service.modifier_inscription(session, inscription_id, donnees))


@routeur_academique.delete("/inscriptions-cours/{inscription_id}")
def route_retirer_inscription(
    inscription_id: int,
    _contexte=ecriture_academique,
    session: Session = Depends(obtenir_session),
):
    return reponse_succes("Inscription retiree", service.retirer_inscription(session, inscription_id))
