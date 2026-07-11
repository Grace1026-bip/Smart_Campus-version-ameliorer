from pydantic import BaseModel, Field, field_validator, model_validator


ROLES_PUBLICS_INSCRIPTION = {"etudiant", "enseignant"}


class DemandeInscriptionCreation(BaseModel):
    type_demande: str = Field(min_length=3, max_length=60)
    email: str = Field(min_length=3, max_length=190)
    mot_de_passe: str = Field(min_length=8, max_length=128)
    nom: str = Field(min_length=2, max_length=100)
    postnom: str | None = Field(default=None, max_length=100)
    prenom: str | None = Field(default=None, max_length=100)
    telephone: str | None = Field(default=None, max_length=30)
    matricule: str | None = Field(default=None, min_length=2, max_length=80)
    promotion_id: int | None = Field(default=None, gt=0)
    matricule_agent: str | None = Field(default=None, min_length=2, max_length=80)
    grade: str | None = Field(default=None, max_length=100)
    departement: str | None = Field(default=None, max_length=150)

    @field_validator("type_demande")
    @classmethod
    def valider_type_demande(cls, valeur: str) -> str:
        role = valeur.strip().lower()
        if role not in ROLES_PUBLICS_INSCRIPTION:
            raise ValueError("Role public non autorise")
        return role

    @field_validator("email")
    @classmethod
    def normaliser_email(cls, valeur: str) -> str:
        email = valeur.strip().lower()
        if "@" not in email or "." not in email.split("@")[-1]:
            raise ValueError("Email invalide")
        return email

    @field_validator("matricule", "matricule_agent", "grade", "departement", "postnom", "prenom", "telephone")
    @classmethod
    def nettoyer_texte_optionnel(cls, valeur: str | None) -> str | None:
        if valeur is None:
            return None
        valeur = valeur.strip()
        return valeur or None

    @model_validator(mode="after")
    def valider_champs_metier(self):
        if self.type_demande == "etudiant":
            if not self.matricule or not self.promotion_id:
                raise ValueError("Matricule et promotion requis pour une demande etudiant")
        if self.type_demande == "enseignant":
            if not self.matricule_agent or not self.departement:
                raise ValueError("Matricule agent et departement requis pour une demande enseignant")
        return self


class ConsultationStatutDemande(BaseModel):
    reference: str = Field(min_length=6, max_length=40)
    email: str = Field(min_length=3, max_length=190)

    @field_validator("email")
    @classmethod
    def normaliser_email(cls, valeur: str) -> str:
        return valeur.strip().lower()


class RejetDemandeInscription(BaseModel):
    motif: str | None = Field(default=None, max_length=500)


class DemandeInscriptionReponse(BaseModel):
    id: int | None = None
    reference: str
    type_demande: str
    email: str
    nom: str
    postnom: str | None = None
    prenom: str | None = None
    telephone: str | None = None
    matricule: str | None = None
    promotion_id: int | None = None
    matricule_agent: str | None = None
    grade: str | None = None
    departement: str | None = None
    statut: str
    motif_rejet: str | None = None
    utilisateur_id: int | None = None
    cree_le: str | None = None
    traite_le: str | None = None
