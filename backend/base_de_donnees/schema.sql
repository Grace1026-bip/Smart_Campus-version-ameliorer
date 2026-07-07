CREATE DATABASE IF NOT EXISTS smart_faculty
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_faculty;

CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    postnom VARCHAR(100) NULL,
    prenom VARCHAR(100) NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    mot_de_passe VARCHAR(255) NOT NULL,
    photo_url VARCHAR(255) NULL,
    statut ENUM('en_attente', 'approuve', 'rejete', 'bloque') NOT NULL DEFAULT 'en_attente',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_utilisateurs_statut (statut)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET @smart_faculty_add_photo_url = (
    SELECT IF(
        COUNT(*) = 0,
        'ALTER TABLE utilisateurs ADD COLUMN photo_url VARCHAR(255) NULL AFTER mot_de_passe',
        'SELECT 1'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'utilisateurs'
      AND COLUMN_NAME = 'photo_url'
);
PREPARE smart_faculty_stmt FROM @smart_faculty_add_photo_url;
EXECUTE smart_faculty_stmt;
DEALLOCATE PREPARE smart_faculty_stmt;

CREATE TABLE IF NOT EXISTS roles (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom_role VARCHAR(60) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS utilisateur_roles (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    date_attribution TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_utilisateur_role (utilisateur_id, role_id),
    CONSTRAINT fk_utilisateur_roles_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_utilisateur_roles_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departements (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promotions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(150) NOT NULL UNIQUE,
    niveau VARCHAR(60) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS demandes_inscription (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL,
    type_demande ENUM('etudiant', 'enseignant') NOT NULL,
    statut ENUM('en_attente', 'approuve', 'rejete') NOT NULL DEFAULT 'en_attente',
    message TEXT NULL,
    approuve_par INT UNSIGNED NULL,
    date_demande TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_traitement DATETIME NULL,
    INDEX idx_demandes_statut (statut),
    INDEX idx_demandes_type (type_demande),
    CONSTRAINT fk_demandes_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_demandes_approbateur
        FOREIGN KEY (approuve_par) REFERENCES utilisateurs(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS sessions_utilisateurs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL,
    token VARCHAR(64) NOT NULL UNIQUE,
    date_expiration DATETIME NOT NULL,
    actif TINYINT(1) NOT NULL DEFAULT 1,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_derniere_utilisation DATETIME NULL,
    INDEX idx_sessions_utilisateur (utilisateur_id),
    INDEX idx_sessions_expiration (date_expiration),
    CONSTRAINT fk_sessions_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etudiants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL UNIQUE,
    matricule VARCHAR(80) NOT NULL UNIQUE,
    promotion_id INT UNSIGNED NULL,
    CONSTRAINT fk_etudiants_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_etudiants_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS enseignants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    utilisateur_id INT UNSIGNED NOT NULL UNIQUE,
    departement_id INT UNSIGNED NULL,
    cours VARCHAR(150) NULL,
    CONSTRAINT fk_enseignants_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_enseignants_departement
        FOREIGN KEY (departement_id) REFERENCES departements(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS annees_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    libelle VARCHAR(30) NOT NULL UNIQUE,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS semestres (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    annee_academique_id INT UNSIGNED NOT NULL,
    nom VARCHAR(80) NOT NULL,
    ordre TINYINT UNSIGNED NOT NULL,
    UNIQUE KEY uq_semestre_annee_ordre (annee_academique_id, ordre),
    CONSTRAINT fk_semestres_annee
        FOREIGN KEY (annee_academique_id) REFERENCES annees_academiques(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_id INT UNSIGNED NOT NULL,
    semestre_id INT UNSIGNED NOT NULL,
    code VARCHAR(40) NOT NULL UNIQUE,
    nom VARCHAR(180) NOT NULL,
    description TEXT NULL,
    nombre_heures INT UNSIGNED NOT NULL DEFAULT 0,
    credits INT UNSIGNED NOT NULL DEFAULT 0,
    objectifs TEXT NULL,
    modalites_evaluation TEXT NULL,
    statut_notes ENUM('non_encodees', 'brouillon', 'publiees') NOT NULL DEFAULT 'non_encodees',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_cours_promotion (promotion_id),
    INDEX idx_cours_semestre (semestre_id),
    CONSTRAINT fk_cours_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cours_semestre
        FOREIGN KEY (semestre_id) REFERENCES semestres(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cours_enseignants (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cours_id INT UNSIGNED NOT NULL,
    enseignant_id INT UNSIGNED NOT NULL,
    role_enseignement ENUM('principal', 'assistant') NOT NULL DEFAULT 'principal',
    UNIQUE KEY uq_cours_enseignant_role (cours_id, enseignant_id, role_enseignement),
    CONSTRAINT fk_cours_enseignants_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cours_enseignants_enseignant
        FOREIGN KEY (enseignant_id) REFERENCES enseignants(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS inscriptions_cours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NOT NULL,
    date_inscription TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_inscription_cours (etudiant_id, cours_id),
    CONSTRAINT fk_inscriptions_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_inscriptions_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS types_notes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(100) NOT NULL,
    poids DECIMAL(5,2) NOT NULL DEFAULT 1.00
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS notes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NOT NULL,
    type_note_id INT UNSIGNED NOT NULL,
    enseignant_id INT UNSIGNED NOT NULL,
    valeur DECIMAL(5,2) NOT NULL,
    statut ENUM('brouillon', 'publie') NOT NULL DEFAULT 'brouillon',
    verrouille TINYINT(1) NOT NULL DEFAULT 0,
    date_publication DATETIME NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_note_etudiant_cours_type (etudiant_id, cours_id, type_note_id),
    INDEX idx_notes_cours_statut (cours_id, statut),
    CONSTRAINT fk_notes_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_notes_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_notes_type
        FOREIGN KEY (type_note_id) REFERENCES types_notes(id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_notes_enseignant
        FOREIGN KEY (enseignant_id) REFERENCES enseignants(id)
        ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS publications_valve (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    cours_id INT UNSIGNED NOT NULL,
    enseignant_id INT UNSIGNED NOT NULL,
    type_publication ENUM(
        'annonce',
        'communique',
        'devoir',
        'support_de_cours',
        'changement_horaire',
        'consigne_examen',
        'publication_notes',
        'rappel'
    ) NOT NULL,
    titre VARCHAR(180) NOT NULL,
    contenu TEXT NOT NULL,
    piece_jointe_url VARCHAR(255) NULL,
    statut ENUM('brouillon', 'publie', 'verrouille') NOT NULL DEFAULT 'publie',
    visibilite ENUM('etudiants', 'enseignants', 'tous') NOT NULL DEFAULT 'etudiants',
    est_important TINYINT(1) NOT NULL DEFAULT 0,
    verrouille TINYINT(1) NOT NULL DEFAULT 0,
    date_publication DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uq_valve_cours_type_titre (cours_id, type_publication, titre),
    INDEX idx_valve_cours_date (cours_id, date_publication),
    CONSTRAINT fk_valve_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_valve_enseignant
        FOREIGN KEY (enseignant_id) REFERENCES enseignants(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reclamations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NULL,
    note_id INT UNSIGNED NULL,
    titre VARCHAR(180) NOT NULL,
    type_reclamation ENUM('note', 'cours', 'horaire', 'document', 'autre') NOT NULL DEFAULT 'note',
    description TEXT NOT NULL,
    statut ENUM('en_attente', 'en_cours', 'resolue', 'rejetee', 'transmise', 'transmise_apparitorat') NOT NULL DEFAULT 'en_attente',
    priorite ENUM('faible', 'normale', 'haute') NOT NULL DEFAULT 'normale',
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reclamations_statut (statut),
    CONSTRAINT fk_reclamations_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reclamations_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_reclamations_note
        FOREIGN KEY (note_id) REFERENCES notes(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS reponses_reclamations (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    reclamation_id INT UNSIGNED NOT NULL,
    utilisateur_id INT UNSIGNED NOT NULL,
    message TEXT NOT NULL,
    date_reponse TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reponses_reclamation
        FOREIGN KEY (reclamation_id) REFERENCES reclamations(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reponses_utilisateur
        FOREIGN KEY (utilisateur_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS alertes_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    cours_id INT UNSIGNED NULL,
    titre VARCHAR(180) NOT NULL,
    message TEXT NOT NULL,
    niveau ENUM('info', 'attention', 'danger') NOT NULL DEFAULT 'attention',
    lue TINYINT(1) NOT NULL DEFAULT 0,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_alertes_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_alertes_cours
        FOREIGN KEY (cours_id) REFERENCES cours(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS projets_academiques (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    promotion_id INT UNSIGNED NULL,
    encadreur_id INT UNSIGNED NULL,
    titre VARCHAR(180) NOT NULL,
    description TEXT NULL,
    groupe VARCHAR(120) NULL,
    progression DECIMAL(5,2) NOT NULL DEFAULT 0.00,
    livrable_attendu VARCHAR(180) NULL,
    statut ENUM('planifie', 'en_cours', 'en_retard', 'valide', 'termine') NOT NULL DEFAULT 'en_cours',
    date_echeance DATE NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_projets_promotion (promotion_id),
    INDEX idx_projets_statut (statut),
    CONSTRAINT fk_projets_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_projets_encadreur
        FOREIGN KEY (encadreur_id) REFERENCES enseignants(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS stages (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    etudiant_id INT UNSIGNED NOT NULL,
    entreprise VARCHAR(180) NOT NULL,
    maitre_stage VARCHAR(180) NULL,
    sujet VARCHAR(180) NULL,
    rapport_url VARCHAR(255) NULL,
    statut ENUM('planifie', 'en_cours', 'en_retard', 'valide', 'termine') NOT NULL DEFAULT 'en_cours',
    date_debut DATE NULL,
    date_fin DATE NULL,
    date_creation TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    date_modification TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_stages_etudiant (etudiant_id),
    INDEX idx_stages_statut (statut),
    CONSTRAINT fk_stages_etudiant
        FOREIGN KEY (etudiant_id) REFERENCES etudiants(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
