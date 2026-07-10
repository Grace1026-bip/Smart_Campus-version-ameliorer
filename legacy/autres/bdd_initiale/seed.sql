SET NAMES utf8mb4;
SET time_zone = '+00:00';

INSERT IGNORE INTO roles (id, code, libelle) VALUES
    (1, 'ADMIN', 'Administrateur'),
    (2, 'ETUDIANT', 'Etudiant'),
    (3, 'ENSEIGNANT', 'Enseignant'),
    (4, 'CHEF_PROMOTION', 'Chef de promotion'),
    (5, 'DOYEN', 'Doyen');

INSERT IGNORE INTO utilisateurs (id, nom, prenom, email, mot_de_passe_hash, telephone, actif) VALUES
    (1, 'Systeme', 'Admin', 'admin@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000001', 1),
    (2, 'Mbala', 'Claire', 'doyen@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000002', 1),
    (3, 'Nsimba', 'David', 'david.nsimba@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000003', 1),
    (4, 'Diallo', 'Mariam', 'mariam.diallo@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000004', 1),
    (5, 'Kabasele', 'Amina', 'amina.kabasele@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000005', 1),
    (6, 'Mbuyi', 'Jean', 'jean.mbuyi@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000006', 1),
    (7, 'Ilunga', 'Ruth', 'ruth.ilunga@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000007', 1),
    (8, 'Kanku', 'Patrick', 'patrick.kanku@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000008', 1),
    (9, 'Mukendi', 'Lila', 'lila.mukendi@smartfaculty.test', '$2y$10$demo.hash.for.frontend.only', '+243810000009', 1);

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id) VALUES
    (1, 1),
    (2, 5),
    (3, 3),
    (4, 3),
    (5, 2),
    (5, 4),
    (6, 2),
    (7, 2),
    (8, 2),
    (9, 2);

INSERT IGNORE INTO facultes (id, nom, sigle) VALUES
    (1, 'Faculte des Sciences Informatiques', 'FSI');

INSERT IGNORE INTO departements (id, faculte_id, nom, sigle) VALUES
    (1, 1, 'Informatique', 'INFO');

INSERT IGNORE INTO annees_academiques (id, libelle, date_debut, date_fin, active) VALUES
    (1, '2025-2026', '2025-09-15', '2026-07-31', 1);

INSERT IGNORE INTO promotions (id, departement_id, annee_academique_id, code, libelle, niveau) VALUES
    (1, 1, 1, 'L2-INFO', 'Licence 2 Informatique', 'L2'),
    (2, 1, 1, 'L3-GL', 'Licence 3 Genie Logiciel', 'L3');

INSERT IGNORE INTO etudiants (
    id,
    utilisateur_id,
    promotion_id,
    matricule,
    date_naissance,
    sexe,
    adresse,
    statut
) VALUES
    (1, 5, 1, 'FSI-L2-2026-001', '2003-02-14', 'F', 'Kinshasa, Gombe', 'REGULIER'),
    (2, 6, 1, 'FSI-L2-2026-002', '2002-11-30', 'M', 'Kinshasa, Limete', 'REGULIER'),
    (3, 7, 1, 'FSI-L2-2026-003', '2004-05-08', 'F', 'Kinshasa, Ngaliema', 'REGULIER'),
    (4, 8, 2, 'FSI-L3-2026-001', '2001-09-21', 'M', 'Kinshasa, Matete', 'REGULIER'),
    (5, 9, 2, 'FSI-L3-2026-002', '2002-01-12', 'F', 'Kinshasa, Kasa-Vubu', 'REGULIER');

INSERT IGNORE INTO enseignants (id, utilisateur_id, departement_id, matricule, grade, specialite) VALUES
    (1, 3, 1, 'ENS-FSI-001', 'Chef de travaux', 'Bases de donnees'),
    (2, 4, 1, 'ENS-FSI-002', 'Professeure associee', 'Genie logiciel');

INSERT IGNORE INTO chefs_promotion (id, etudiant_id, promotion_id, annee_academique_id) VALUES
    (1, 1, 1, 1);

INSERT IGNORE INTO cours (id, departement_id, code, intitule, credits, semestre, actif) VALUES
    (1, 1, 'INFO-L2-ALG2', 'Algorithmique II', 5, 3, 1),
    (2, 1, 'INFO-L2-BDD1', 'Bases de donnees I', 5, 3, 1),
    (3, 1, 'INFO-L3-GL1', 'Genie logiciel I', 6, 5, 1),
    (4, 1, 'INFO-L3-RES1', 'Reseaux informatiques', 4, 5, 1);

INSERT IGNORE INTO cours_promotions (id, cours_id, promotion_id, annee_academique_id) VALUES
    (1, 1, 1, 1),
    (2, 2, 1, 1),
    (3, 3, 2, 1),
    (4, 4, 2, 1);

INSERT IGNORE INTO enseignant_cours (id, enseignant_id, cours_id, promotion_id, annee_academique_id) VALUES
    (1, 1, 2, 1, 1),
    (2, 1, 4, 2, 1),
    (3, 2, 1, 1, 1),
    (4, 2, 3, 2, 1);

INSERT IGNORE INTO notes (
    id,
    etudiant_id,
    cours_id,
    annee_academique_id,
    type_evaluation,
    note,
    coefficient,
    statut,
    publie_par_enseignant_id,
    date_publication
) VALUES
    (1, 1, 1, 1, 'FINAL', 15.50, 1.00, 'PUBLIEE', 2, '2026-02-10 09:30:00'),
    (2, 1, 2, 1, 'FINAL', 14.00, 1.00, 'PUBLIEE', 1, '2026-02-11 10:00:00'),
    (3, 2, 1, 1, 'FINAL', 9.25, 1.00, 'PUBLIEE', 2, '2026-02-10 09:30:00'),
    (4, 2, 2, 1, 'FINAL', 8.75, 1.00, 'PUBLIEE', 1, '2026-02-11 10:00:00'),
    (5, 3, 1, 1, 'FINAL', 12.00, 1.00, 'PUBLIEE', 2, '2026-02-10 09:30:00'),
    (6, 3, 2, 1, 'FINAL', 10.50, 1.00, 'PUBLIEE', 1, '2026-02-11 10:00:00'),
    (7, 4, 3, 1, 'FINAL', 16.75, 1.00, 'PUBLIEE', 2, '2026-02-12 14:00:00'),
    (8, 5, 3, 1, 'FINAL', 13.25, 1.00, 'PUBLIEE', 2, '2026-02-12 14:00:00');

INSERT IGNORE INTO resultats_academiques (
    id,
    etudiant_id,
    annee_academique_id,
    moyenne,
    credits_valides,
    decision
) VALUES
    (1, 1, 1, 14.75, 60, 'ADMIS'),
    (2, 2, 1, 9.00, 34, 'AJOURNE'),
    (3, 3, 1, 11.25, 48, 'EN_COURS'),
    (4, 4, 1, 16.10, 60, 'ADMIS'),
    (5, 5, 1, 13.25, 54, 'EN_COURS');

INSERT IGNORE INTO types_reclamation (id, code, libelle) VALUES
    (1, 'ERREUR_NOTE', 'Erreur de note'),
    (2, 'INSCRIPTION', 'Probleme inscription'),
    (3, 'ADMINISTRATIF', 'Probleme administratif'),
    (4, 'PAIEMENT', 'Paiement'),
    (5, 'HORAIRE', 'Horaire'),
    (6, 'DOCUMENT_ACADEMIQUE', 'Document academique');

INSERT IGNORE INTO statuts_reclamation (id, code, libelle) VALUES
    (1, 'EN_ATTENTE', 'En attente'),
    (2, 'EN_COURS', 'En cours'),
    (3, 'RESOLUE', 'Resolue'),
    (4, 'REJETEE', 'Rejetee');

INSERT IGNORE INTO reclamations (
    id,
    reference,
    etudiant_id,
    cree_par_utilisateur_id,
    type_id,
    statut_id,
    titre,
    description,
    priorite,
    assignee_a_utilisateur_id
) VALUES
    (1, 'REC-2026-0001', 2, 6, 1, 2, 'Verification note BDD', 'La note affichee ne correspond pas au resultat communique en classe.', 'HAUTE', 3),
    (2, 'REC-2026-0002', 1, 5, 6, 1, 'Attestation de frequentation', 'Demande de suivi pour une attestation non encore disponible.', 'NORMALE', 1),
    (3, 'REC-2026-0003', 4, 8, 5, 3, 'Conflit horaire de TP', 'Le TP de reseaux chevauche une seance de projet.', 'NORMALE', 4);

INSERT IGNORE INTO traitements_reclamation (
    id,
    reclamation_id,
    statut_id,
    traite_par_utilisateur_id,
    commentaire,
    created_at
) VALUES
    (1, 1, 1, NULL, 'Reclamation creee par etudiant.', '2026-02-15 08:20:00'),
    (2, 1, 2, 3, 'Verification lancee avec le releve de notes.', '2026-02-15 11:00:00'),
    (3, 2, 1, NULL, 'Demande recue par le secretariat.', '2026-02-16 09:10:00'),
    (4, 3, 1, NULL, 'Signalement transmis au departement.', '2026-02-12 16:30:00'),
    (5, 3, 3, 4, 'Horaire corrige pour la promotion L3.', '2026-02-14 12:45:00');

INSERT IGNORE INTO projets_academiques (
    id,
    promotion_id,
    encadreur_id,
    titre,
    description,
    statut,
    progression,
    date_debut,
    date_fin_prevue
) VALUES
    (1, 1, 2, 'Portail de gestion des reclamations', 'Prototype mobile et web pour le suivi des demandes academiques.', 'EN_COURS', 65, '2026-01-10', '2026-05-20'),
    (2, 2, 1, 'Tableau de bord analytique', 'Application de visualisation des indicateurs de performance academique.', 'VALIDE', 35, '2026-01-18', '2026-06-10');

INSERT IGNORE INTO projet_membres (id, projet_id, etudiant_id, role_membre) VALUES
    (1, 1, 1, 'Cheffe de groupe'),
    (2, 1, 2, 'Developpeur'),
    (3, 1, 3, 'Analyste'),
    (4, 2, 4, 'Developpeur'),
    (5, 2, 5, 'Designer UI');

INSERT IGNORE INTO livrables_projet (
    id,
    projet_id,
    depose_par_etudiant_id,
    titre,
    type_fichier,
    chemin_fichier,
    statut,
    date_depot
) VALUES
    (1, 1, 1, 'Cahier des charges', 'PDF', '/uploads/projets/1/cahier-des-charges.pdf', 'VALIDE', '2026-01-25 18:00:00'),
    (2, 1, 2, 'Prototype frontend', 'ZIP', '/uploads/projets/1/prototype-frontend.zip', 'DEPOSE', '2026-02-20 21:15:00'),
    (3, 2, 4, 'Maquette dashboard', 'PDF', '/uploads/projets/2/maquette-dashboard.pdf', 'DEPOSE', '2026-02-08 17:35:00');

INSERT IGNORE INTO entreprises (
    id,
    nom,
    secteur,
    adresse,
    email_contact,
    telephone_contact
) VALUES
    (1, 'TechNova RDC', 'Developpement logiciel', 'Kinshasa, Gombe', 'stages@technova.test', '+243820000001'),
    (2, 'DataVision Lab', 'Data et analytics', 'Kinshasa, Limete', 'rh@datavision.test', '+243820000002');

INSERT IGNORE INTO offres_stage (
    id,
    entreprise_id,
    titre,
    description,
    lieu,
    duree,
    statut,
    date_publication,
    date_limite
) VALUES
    (1, 1, 'Stage developpeur Flutter', 'Participation au developpement mobile avec Flutter.', 'Kinshasa', '3 mois', 'OUVERTE', '2026-02-01', '2026-03-15'),
    (2, 2, 'Stage assistant data analyst', 'Nettoyage de donnees et creation de tableaux de bord.', 'Kinshasa', '4 mois', 'SELECTION', '2026-01-20', '2026-02-28');

INSERT IGNORE INTO candidatures_stage (
    id,
    offre_id,
    etudiant_id,
    statut,
    message,
    date_candidature
) VALUES
    (1, 1, 4, 'ENVOYEE', 'Je souhaite rejoindre votre equipe mobile.', '2026-02-05 10:30:00'),
    (2, 2, 5, 'ENTRETIEN', 'Interessee par les projets analytics.', '2026-02-02 15:45:00');

INSERT IGNORE INTO stages (
    id,
    etudiant_id,
    entreprise_id,
    offre_id,
    encadreur_id,
    sujet,
    maitre_stage,
    statut,
    date_debut,
    date_fin
) VALUES
    (1, 5, 2, 2, 1, 'Automatisation des rapports academiques', 'Sarah Kalala', 'VALIDE', '2026-04-01', '2026-07-31');

INSERT IGNORE INTO alertes_risque (
    id,
    etudiant_id,
    annee_academique_id,
    moyenne,
    nombre_echecs,
    niveau,
    commentaire,
    detecte_le
) VALUES
    (1, 2, 1, 9.00, 3, 'ELEVE', 'Moyenne faible et plusieurs echecs dans les cours fondamentaux.', '2026-02-18 08:00:00'),
    (2, 3, 1, 11.25, 1, 'MOYEN', 'Suivi recommande avant les examens finaux.', '2026-02-18 08:05:00'),
    (3, 5, 1, 13.25, 0, 'FAIBLE', 'Progression correcte, aucun risque majeur.', '2026-02-18 08:10:00');

INSERT IGNORE INTO notifications (
    id,
    utilisateur_id,
    titre,
    message,
    lu,
    created_at
) VALUES
    (1, 5, 'Reclamation enregistree', 'Votre demande concernant le document academique a ete recue.', 0, '2026-02-16 09:12:00'),
    (2, 6, 'Reclamation en cours', 'Votre reclamation de note est en cours de verification.', 0, '2026-02-15 11:02:00'),
    (3, 3, 'Nouvelle reclamation assignee', 'Une reclamation de note attend votre traitement.', 0, '2026-02-15 10:58:00'),
    (4, 2, 'Rapport analytics disponible', 'Les indicateurs de performance de la semaine sont prets.', 1, '2026-02-18 07:30:00'),
    (5, 8, 'Candidature envoyee', 'Votre candidature au stage Flutter a ete enregistree.', 0, '2026-02-05 10:31:00');
