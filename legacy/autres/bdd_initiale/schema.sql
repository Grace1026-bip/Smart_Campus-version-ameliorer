SET NAMES utf8mb4;
SET time_zone = '+00:00';

CREATE TABLE IF NOT EXISTS roles (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    libelle VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    mot_de_passe_hash VARCHAR(255) NOT NULL,
    telephone VARCHAR(30) NULL,
    actif TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS utilisateur_roles (
    utilisateur_id INT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (utilisateur_id, role_id),
    CONSTRAINT fk_utilisateur_roles_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_utilisateur_roles_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS facultes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(180) NOT NULL,
    sigle VARCHAR(30) NOT NULL UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departements (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    faculte_id INT UNSIGNED NOT NULL,
    nom VARCHAR(180) NOT NULL,
    sigle VARCHAR(30) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_departement_faculte_sigle (faculte_id, sigle),
    CONSTRAINT fk_departements_faculte
        FOREIGN KEY (faculte_id) REFERENCES facultes(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS annees_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(20) NOT NULL UNIQUE,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_annee_dates CHECK (date_fin > date_debut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promotions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    departement_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    code VARCHAR(40) NOT NULL,
    libelle VARCHAR(120) NOT NULL,
    niveau VARCHAR(30) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_promotion_annee_code (annee_academique_id, code),
    KEY idx_promotions_departement (departement_id),
    CONSTRAINT fk_promotions_departement
        FOREIGN KEY (departement_id) REFERENCES departements(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_promotions_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etudiants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL UNIQUE,
    promotion_id INT UNSIGNED NOT NULL,
    matricule VARCHAR(60) NOT NULL UNIQUE,
    date_naissance DATE NULL,
    sexe ENUM('M', 'F', 'AUTRE') NULL,
    adresse VARCHAR(255) NULL,
    statut ENUM('REGULIER', 'SUSPENDU', 'DIPLOME', 'ABANDON') NOT NULL DEFAULT 'REGULIER',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_etudiants_promotion (promotion_id),
    CONSTRAINT fk_etudiants_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_etudiants_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enseignants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL UNIQUE,
    departement_id INT UNSIGNED NOT NULL,
    matricule VARCHAR(60) NOT NULL UNIQUE,
    grade VARCHAR(80) NULL,
    specialite VARCHAR(160) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_enseignants_departement (departement_id),
    CONSTRAINT fk_enseignants_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enseignants_departement
        FOREIGN KEY (departement_id) REFERENCES departements(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chefs_promotion (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    promotion_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_chef_promotion_annee (promotion_id, annee_academique_id),
    CONSTRAINT fk_chefs_promotion_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_chefs_promotion_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_chefs_promotion_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    departement_id INT UNSIGNED NOT NULL,
    code VARCHAR(40) NOT NULL UNIQUE,
    intitule VARCHAR(180) NOT NULL,
    credits TINYINT UNSIGNED NOT NULL,
    semestre TINYINT UNSIGNED NOT NULL,
    actif TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_cours_departement (departement_id),
    CONSTRAINT chk_cours_credits CHECK (credits > 0),
    CONSTRAINT chk_cours_semestre CHECK (semestre BETWEEN 1 AND 12),
    CONSTRAINT fk_cours_departement
        FOREIGN KEY (departement_id) REFERENCES departements(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cours_promotions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cours_id INT UNSIGNED NOT NULL,
    promotion_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_cours_promotion_annee (cours_id, promotion_id, annee_academique_id),
    CONSTRAINT fk_cours_promotions_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cours_promotions_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_cours_promotions_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enseignant_cours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    enseignant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NOT NULL,
    promotion_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_enseignant_cours (enseignant_id, cours_id, promotion_id, annee_academique_id),
    CONSTRAINT fk_enseignant_cours_enseignant
        FOREIGN KEY (enseignant_id) REFERENCES enseignants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enseignant_cours_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enseignant_cours_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_enseignant_cours_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    type_evaluation ENUM('TP', 'INTERROGATION', 'EXAMEN', 'RATTRAPAGE', 'FINAL') NOT NULL DEFAULT 'FINAL',
    note DECIMAL(5,2) NOT NULL,
    coefficient DECIMAL(4,2) NOT NULL DEFAULT 1.00,
    statut ENUM('BROUILLON', 'PUBLIEE', 'CORRIGEE', 'ANNULEE') NOT NULL DEFAULT 'BROUILLON',
    publie_par_enseignant_id INT UNSIGNED NULL,
    date_publication DATETIME NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_notes_etudiant (etudiant_id),
    KEY idx_notes_cours (cours_id),
    CONSTRAINT chk_notes_note CHECK (note >= 0 AND note <= 20),
    CONSTRAINT chk_notes_coefficient CHECK (coefficient > 0),
    CONSTRAINT fk_notes_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_notes_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_notes_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_notes_enseignant
        FOREIGN KEY (publie_par_enseignant_id) REFERENCES enseignants(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS resultats_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    moyenne DECIMAL(5,2) NOT NULL,
    credits_valides SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    decision ENUM('ADMIS', 'AJOURNE', 'REDOUBLE', 'EN_COURS') NOT NULL DEFAULT 'EN_COURS',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_resultat_etudiant_annee (etudiant_id, annee_academique_id),
    CONSTRAINT chk_resultats_moyenne CHECK (moyenne >= 0 AND moyenne <= 20),
    CONSTRAINT fk_resultats_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_resultats_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS types_reclamation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS statuts_reclamation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(100) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reclamations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reference VARCHAR(40) NOT NULL UNIQUE,
    etudiant_id INT UNSIGNED NULL,
    cree_par_utilisateur_id INT UNSIGNED NOT NULL,
    type_id INT UNSIGNED NOT NULL,
    statut_id INT UNSIGNED NOT NULL,
    titre VARCHAR(180) NOT NULL,
    description TEXT NOT NULL,
    priorite ENUM('BASSE', 'NORMALE', 'HAUTE', 'URGENTE') NOT NULL DEFAULT 'NORMALE',
    assignee_a_utilisateur_id INT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_reclamations_etudiant (etudiant_id),
    KEY idx_reclamations_statut (statut_id),
    KEY idx_reclamations_type (type_id),
    CONSTRAINT fk_reclamations_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_reclamations_createur
        FOREIGN KEY (cree_par_utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reclamations_type
        FOREIGN KEY (type_id) REFERENCES types_reclamation(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reclamations_statut
        FOREIGN KEY (statut_id) REFERENCES statuts_reclamation(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reclamations_assignee
        FOREIGN KEY (assignee_a_utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS traitements_reclamation (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reclamation_id INT UNSIGNED NOT NULL,
    statut_id INT UNSIGNED NOT NULL,
    traite_par_utilisateur_id INT UNSIGNED NULL,
    commentaire TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_traitements_reclamation (reclamation_id),
    CONSTRAINT fk_traitements_reclamation
        FOREIGN KEY (reclamation_id) REFERENCES reclamations(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_traitements_statut
        FOREIGN KEY (statut_id) REFERENCES statuts_reclamation(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_traitements_utilisateur
        FOREIGN KEY (traite_par_utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS projets_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_id INT UNSIGNED NOT NULL,
    encadreur_id INT UNSIGNED NULL,
    titre VARCHAR(180) NOT NULL,
    description TEXT NULL,
    statut ENUM('PROPOSE', 'VALIDE', 'EN_COURS', 'SUSPENDU', 'TERMINE') NOT NULL DEFAULT 'PROPOSE',
    progression TINYINT UNSIGNED NOT NULL DEFAULT 0,
    date_debut DATE NULL,
    date_fin_prevue DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_projets_promotion (promotion_id),
    CONSTRAINT chk_projets_progression CHECK (progression BETWEEN 0 AND 100),
    CONSTRAINT fk_projets_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_projets_encadreur
        FOREIGN KEY (encadreur_id) REFERENCES enseignants(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS projet_membres (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projet_id INT UNSIGNED NOT NULL,
    etudiant_id INT UNSIGNED NOT NULL,
    role_membre VARCHAR(80) NOT NULL DEFAULT 'Membre',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_projet_membre (projet_id, etudiant_id),
    CONSTRAINT fk_projet_membres_projet
        FOREIGN KEY (projet_id) REFERENCES projets_academiques(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_projet_membres_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS livrables_projet (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    projet_id INT UNSIGNED NOT NULL,
    depose_par_etudiant_id INT UNSIGNED NULL,
    titre VARCHAR(180) NOT NULL,
    type_fichier VARCHAR(50) NULL,
    chemin_fichier VARCHAR(255) NULL,
    statut ENUM('DEPOSE', 'VALIDE', 'REJETE') NOT NULL DEFAULT 'DEPOSE',
    date_depot TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_livrables_projet
        FOREIGN KEY (projet_id) REFERENCES projets_academiques(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_livrables_etudiant
        FOREIGN KEY (depose_par_etudiant_id) REFERENCES etudiants(id)
        ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS entreprises (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(180) NOT NULL,
    secteur VARCHAR(120) NULL,
    adresse VARCHAR(255) NULL,
    email_contact VARCHAR(190) NULL,
    telephone_contact VARCHAR(30) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS offres_stage (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    entreprise_id INT UNSIGNED NOT NULL,
    titre VARCHAR(180) NOT NULL,
    description TEXT NULL,
    lieu VARCHAR(150) NULL,
    duree VARCHAR(80) NULL,
    statut ENUM('OUVERTE', 'SELECTION', 'FERMEE') NOT NULL DEFAULT 'OUVERTE',
    date_publication DATE NOT NULL,
    date_limite DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_offres_entreprise (entreprise_id),
    CONSTRAINT fk_offres_entreprise
        FOREIGN KEY (entreprise_id) REFERENCES entreprises(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS candidatures_stage (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    offre_id INT UNSIGNED NOT NULL,
    etudiant_id INT UNSIGNED NOT NULL,
    statut ENUM('ENVOYEE', 'ENTRETIEN', 'ACCEPTEE', 'REFUSEE', 'ANNULEE') NOT NULL DEFAULT 'ENVOYEE',
    message TEXT NULL,
    date_candidature TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_candidature_offre_etudiant (offre_id, etudiant_id),
    CONSTRAINT fk_candidatures_offre
        FOREIGN KEY (offre_id) REFERENCES offres_stage(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_candidatures_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stages (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    entreprise_id INT UNSIGNED NOT NULL,
    offre_id INT UNSIGNED NULL,
    encadreur_id INT UNSIGNED NULL,
    sujet VARCHAR(180) NOT NULL,
    maitre_stage VARCHAR(150) NULL,
    statut ENUM('PROPOSE', 'VALIDE', 'EN_COURS', 'TERMINE', 'REFUSE') NOT NULL DEFAULT 'PROPOSE',
    date_debut DATE NULL,
    date_fin DATE NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
    KEY idx_stages_etudiant (etudiant_id),
    CONSTRAINT fk_stages_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_stages_entreprise
        FOREIGN KEY (entreprise_id) REFERENCES entreprises(id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_stages_offre
        FOREIGN KEY (offre_id) REFERENCES offres_stage(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_stages_encadreur
        FOREIGN KEY (encadreur_id) REFERENCES enseignants(id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_stages_dates CHECK (date_fin IS NULL OR date_debut IS NULL OR date_fin >= date_debut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS alertes_risque (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    annee_academique_id INT UNSIGNED NOT NULL,
    moyenne DECIMAL(5,2) NOT NULL,
    nombre_echecs TINYINT UNSIGNED NOT NULL DEFAULT 0,
    niveau ENUM('FAIBLE', 'MOYEN', 'ELEVE') NOT NULL,
    commentaire TEXT NULL,
    detecte_le TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_alertes_etudiant (etudiant_id),
    KEY idx_alertes_niveau (niveau),
    CONSTRAINT chk_alertes_moyenne CHECK (moyenne >= 0 AND moyenne <= 20),
    CONSTRAINT fk_alertes_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_alertes_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL,
    titre VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    lu TINYINT(1) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    KEY idx_notifications_utilisateur_lu (utilisateur_id, lu),
    CONSTRAINT fk_notifications_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
