CREATE DATABASE IF NOT EXISTS smart_faculty
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE smart_faculty;

CREATE TABLE IF NOT EXISTS roles (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS utilisateurs (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    postnom VARCHAR(100) NULL,
    prenom VARCHAR(100) NULL,
    email VARCHAR(190) NOT NULL UNIQUE,
    telephone VARCHAR(50) NULL,
    password_hash VARCHAR(255) NOT NULL,
    active TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS roles_utilisateurs (
    user_id INT UNSIGNED NOT NULL,
    role_id INT UNSIGNED NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_id, role_id),
    CONSTRAINT fk_roles_utilisateurs_user
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_roles_utilisateurs_role
        FOREIGN KEY (role_id) REFERENCES roles(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS departments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(150) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS promotions (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(150) NOT NULL,
    department_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_promotions_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS cours (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    libelle VARCHAR(150) NOT NULL,
    department_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cours_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS etudiants (
    user_id INT UNSIGNED PRIMARY KEY,
    matricule VARCHAR(80) NULL,
    promotion_id INT UNSIGNED NULL,
    department_id INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_etudiants_user
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_etudiants_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_etudiants_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS profs (
    user_id INT UNSIGNED PRIMARY KEY,
    department_id INT UNSIGNED NULL,
    course_id INT UNSIGNED NULL,
    specialite VARCHAR(150) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_profs_user
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_profs_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_profs_course
        FOREIGN KEY (course_id) REFERENCES cours(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS registration_requests (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    postnom VARCHAR(100) NULL,
    prenom VARCHAR(100) NULL,
    email VARCHAR(190) NOT NULL,
    telephone VARCHAR(50) NULL,
    requested_role VARCHAR(50) NOT NULL,
    promotion_id INT UNSIGNED NULL,
    department_id INT UNSIGNED NULL,
    course_id INT UNSIGNED NULL,
    promotion_label VARCHAR(150) NULL,
    department_label VARCHAR(150) NULL,
    course_label VARCHAR(150) NULL,
    matricule VARCHAR(80) NULL,
    specialite VARCHAR(150) NULL,
    password_hash VARCHAR(255) NOT NULL,
    status ENUM('en_attente', 'approuvee', 'rejetee') NOT NULL DEFAULT 'en_attente',
    approved_by INT UNSIGNED NULL,
    user_id INT UNSIGNED NULL,
    rejection_reason TEXT NULL,
    metadata JSON NULL,
    decided_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_registration_status (status),
    INDEX idx_registration_email (email),
    CONSTRAINT fk_registration_promotion
        FOREIGN KEY (promotion_id) REFERENCES promotions(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_registration_department
        FOREIGN KEY (department_id) REFERENCES departments(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_registration_course
        FOREIGN KEY (course_id) REFERENCES cours(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_registration_approver
        FOREIGN KEY (approved_by) REFERENCES utilisateurs(id)
        ON DELETE SET NULL,
    CONSTRAINT fk_registration_user
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
        ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS remember_tokens (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    selector CHAR(18) NOT NULL UNIQUE,
    validator_hash VARCHAR(255) NOT NULL,
    expires_at DATETIME NOT NULL,
    last_used_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_remember_user (user_id),
    INDEX idx_remember_expires (expires_at),
    CONSTRAINT fk_remember_user
        FOREIGN KEY (user_id) REFERENCES utilisateurs(id)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO roles (code, libelle) VALUES
    ('etudiant', 'Etudiant'),
    ('enseignant', 'Enseignant'),
    ('cp', 'CP / Chef de promotion'),
    ('appariteur', 'Appariteur'),
    ('vice_doyen', 'Vice-doyen'),
    ('doyen', 'Doyen'),
    ('administrateur', 'Administrateur'),
    ('paritaire', 'Paritaire')
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle);

INSERT INTO departments (code, libelle) VALUES
    ('INFO', 'Informatique'),
    ('MATH', 'Mathematiques'),
    ('GESTION', 'Gestion')
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle);

INSERT INTO promotions (code, libelle, department_id) VALUES
    ('L1_INFO', 'L1 Informatique', (SELECT id FROM departments WHERE code = 'INFO')),
    ('L2_INFO', 'L2 Informatique', (SELECT id FROM departments WHERE code = 'INFO')),
    ('L3_INFO', 'L3 Informatique', (SELECT id FROM departments WHERE code = 'INFO')),
    ('M1_INFO', 'M1 Informatique', (SELECT id FROM departments WHERE code = 'INFO'))
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle), department_id = VALUES(department_id);

INSERT INTO cours (code, libelle, department_id) VALUES
    ('PHP_MVC', 'Programmation PHP MVC', (SELECT id FROM departments WHERE code = 'INFO')),
    ('BDD', 'Bases de donnees', (SELECT id FROM departments WHERE code = 'INFO'))
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle), department_id = VALUES(department_id);

-- Pour creer le premier administrateur de test:
-- 1. Generez un hash avec PHP:
--    php -r "echo password_hash('Admin@123456', PASSWORD_DEFAULT), PHP_EOL;"
-- 2. Remplacez HASH_ICI puis executez:
-- INSERT INTO utilisateurs (nom, postnom, prenom, email, telephone, password_hash, active)
-- VALUES ('Admin', NULL, 'Smart Faculty', 'admin@smartfaculty.test', NULL, 'HASH_ICI', 1);
-- INSERT INTO roles_utilisateurs (user_id, role_id)
-- SELECT u.id, r.id FROM utilisateurs u, roles r
-- WHERE u.email = 'admin@smartfaculty.test' AND r.code = 'administrateur';
