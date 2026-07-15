"""Modeles SQLAlchemy du MVP Smart Faculty."""

from app.modeles.academique import (
    AnneeAcademique,
    Cours,
    CoursEnseignant,
    Enseignant,
    Etudiant,
    InscriptionCours,
    Promotion,
    Semestre,
)
from app.modeles.audit import JournalAudit
from app.modeles.biometrie import EncodageFacial, ProfilBiometrique
from app.modeles.deliberations import DecisionJury, MembreJury, ResultatSemestrielOfficiel, SessionDeliberation
from app.modeles.enrolements import EnrolementAcademique
from app.modeles.inscriptions import DemandeInscription
from app.modeles.notes import Evaluation, Note, ResultatCours, TypeEvaluation
from app.modeles.notifications import Notification
from app.modeles.projets import EncadrementProjet, ProjetAcademique
from app.modeles.presences_academiques import CorrectionPresenceAcademique, PresenceAcademique, SeanceAcademique
from app.modeles.specialites import SpecialiteEncadrementEnseignant
from app.modeles.reclamations import HistoriqueReclamation, MessageReclamation, Reclamation
from app.modeles.securite import JetonActualisation, Permission, Role, RolePermission, Utilisateur, UtilisateurRole
from app.modeles.suivi import EvaluationRisque, Presence
from app.modeles.valve import LecturePublication, PieceJointePublication, PublicationValve

__all__ = [
    "AnneeAcademique",
    "EncodageFacial",
    "Cours",
    "CoursEnseignant",
    "CorrectionPresenceAcademique",
    "DemandeInscription",
    "EncadrementProjet",
    "DecisionJury",
    "Enseignant",
    "EnrolementAcademique",
    "Etudiant",
    "Evaluation",
    "EvaluationRisque",
    "HistoriqueReclamation",
    "InscriptionCours",
    "JetonActualisation",
    "JournalAudit",
    "LecturePublication",
    "MessageReclamation",
    "MembreJury",
    "Note",
    "Notification",
    "Permission",
    "PieceJointePublication",
    "Presence",
    "PresenceAcademique",
    "ProfilBiometrique",
    "Promotion",
    "PublicationValve",
    "ProjetAcademique",
    "Reclamation",
    "ResultatCours",
    "ResultatSemestrielOfficiel",
    "Role",
    "RolePermission",
    "Semestre",
    "SeanceAcademique",
    "SessionDeliberation",
    "SpecialiteEncadrementEnseignant",
    "TypeEvaluation",
    "Utilisateur",
    "UtilisateurRole",
]
