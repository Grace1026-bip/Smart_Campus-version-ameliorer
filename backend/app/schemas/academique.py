from datetime import date

from pydantic import BaseModel, Field, field_validator


class PromotionCreation(BaseModel):
    nom: str = Field(min_length=2, max_length=150)
    niveau: str = Field(min_length=1, max_length=60)
    description: str | None = None
    annee_academique_id: int = Field(gt=0)
    est_active: bool = True


class PromotionModification(BaseModel):
    nom: str | None = Field(default=None, min_length=2, max_length=150)
    niveau: str | None = Field(default=None, min_length=1, max_length=60)
    description: str | None = None
    annee_academique_id: int | None = Field(default=None, gt=0)
    est_active: bool | None = None


class CoursCreation(BaseModel):
    code: str = Field(min_length=2, max_length=40)
    intitule: str = Field(min_length=2, max_length=180)
    description: str | None = None
    nombre_heures: int = Field(gt=0)
    nombre_credits: int = Field(gt=0)
    semestre_id: int = Field(gt=0)
    promotion_id: int = Field(gt=0)
    est_actif: bool = True

    @field_validator("code")
    @classmethod
    def normaliser_code(cls, valeur: str) -> str:
        return valeur.strip().upper()


class CoursModification(BaseModel):
    code: str | None = Field(default=None, min_length=2, max_length=40)
    intitule: str | None = Field(default=None, min_length=2, max_length=180)
    description: str | None = None
    nombre_heures: int | None = Field(default=None, gt=0)
    nombre_credits: int | None = Field(default=None, gt=0)
    semestre_id: int | None = Field(default=None, gt=0)
    promotion_id: int | None = Field(default=None, gt=0)
    est_actif: bool | None = None

    @field_validator("code")
    @classmethod
    def normaliser_code(cls, valeur: str | None) -> str | None:
        return valeur.strip().upper() if valeur else valeur


class CompteUtilisateurCreation(BaseModel):
    nom: str = Field(min_length=2, max_length=100)
    postnom: str | None = Field(default=None, max_length=100)
    prenom: str | None = Field(default=None, max_length=100)
    email: str = Field(min_length=3, max_length=190)
    mot_de_passe: str = Field(min_length=8, max_length=128)
    telephone: str | None = Field(default=None, max_length=30)

    @field_validator("email")
    @classmethod
    def normaliser_email(cls, valeur: str) -> str:
        email = valeur.strip().lower()
        if "@" not in email or "." not in email.split("@")[-1]:
            raise ValueError("Email invalide")
        return email


class EtudiantCreation(BaseModel):
    utilisateur: CompteUtilisateurCreation
    matricule: str = Field(min_length=2, max_length=80)
    promotion_id: int = Field(gt=0)
    date_inscription: date
    statut_academique: str = Field(default="actif", pattern="^(actif|suspendu|diplome|abandon|archive)$")


class EtudiantModification(BaseModel):
    nom: str | None = Field(default=None, min_length=2, max_length=100)
    postnom: str | None = Field(default=None, max_length=100)
    prenom: str | None = Field(default=None, max_length=100)
    telephone: str | None = Field(default=None, max_length=30)
    matricule: str | None = Field(default=None, min_length=2, max_length=80)
    promotion_id: int | None = Field(default=None, gt=0)
    date_inscription: date | None = None
    statut_academique: str | None = Field(default=None, pattern="^(actif|suspendu|diplome|abandon|archive)$")


class EnseignantCreation(BaseModel):
    utilisateur: CompteUtilisateurCreation
    matricule_agent: str | None = Field(default=None, max_length=80)
    grade: str | None = Field(default=None, max_length=100)
    departement: str | None = Field(default=None, max_length=150)
    statut: str = Field(default="actif", pattern="^(actif|suspendu|archive)$")


class EnseignantModification(BaseModel):
    nom: str | None = Field(default=None, min_length=2, max_length=100)
    postnom: str | None = Field(default=None, max_length=100)
    prenom: str | None = Field(default=None, max_length=100)
    telephone: str | None = Field(default=None, max_length=30)
    matricule_agent: str | None = Field(default=None, max_length=80)
    grade: str | None = Field(default=None, max_length=100)
    departement: str | None = Field(default=None, max_length=150)
    statut: str | None = Field(default=None, pattern="^(actif|suspendu|archive)$")


class AffectationEnseignantCreation(BaseModel):
    enseignant_id: int = Field(gt=0)
    type_intervenant: str = Field(pattern="^(professeur|assistant|charge_de_cours)$")
    est_responsable: bool = False


class AffectationEnseignantModification(BaseModel):
    type_intervenant: str | None = Field(default=None, pattern="^(professeur|assistant|charge_de_cours)$")
    est_responsable: bool | None = None


class InscriptionCoursCreation(BaseModel):
    etudiant_id: int = Field(gt=0)
    cours_id: int = Field(gt=0)
    annee_academique_id: int = Field(gt=0)
    date_inscription: date
    statut: str = Field(default="active", pattern="^(active|retiree|validee|archivee)$")


class InscriptionCoursModification(BaseModel):
    statut: str = Field(pattern="^(active|retiree|validee|archivee)$")


class EnrolementCreation(BaseModel):
    etudiant_id: int = Field(gt=0)
    promotion_id: int = Field(gt=0)
    annee_academique_id: int = Field(gt=0)
    date_enrolement: date = Field(default_factory=date.today)


class EnrolementModification(BaseModel):
    etudiant_id: int | None = Field(default=None, gt=0)
    promotion_id: int | None = Field(default=None, gt=0)
    annee_academique_id: int | None = Field(default=None, gt=0)
    date_enrolement: date | None = None


class EnrolementAnnulation(BaseModel):
    motif: str | None = Field(default=None, max_length=500)
