USE smart_faculty;

INSERT INTO roles (nom_role) VALUES
    ('etudiant'),
    ('enseignant'),
    ('chef_promotion'),
    ('icp'),
    ('appariteur'),
    ('paritaire'),
    ('doyen'),
    ('vice_doyen'),
    ('administrateur')
ON DUPLICATE KEY UPDATE nom_role = VALUES(nom_role);

INSERT INTO departements (nom) VALUES
    ('Informatique'),
    ('Mathematiques'),
    ('Gestion')
ON DUPLICATE KEY UPDATE nom = VALUES(nom);

INSERT INTO promotions (nom, niveau) VALUES
    ('L1 Informatique', 'L1'),
    ('L2 Informatique', 'L2'),
    ('L3 Informatique', 'L3')
ON DUPLICATE KEY UPDATE niveau = VALUES(niveau);

-- Comptes de test:
-- admin@smartfaculty.test / Admin@123456
-- paritaire@smartfaculty.test / Paritaire@123456
-- icp@smartfaculty.test / Icp@123456
-- doyen@smartfaculty.test / Doyen@123456
-- vice.doyen@smartfaculty.test / Vice@123456
-- etudiant@smartfaculty.test / Etudiant@123456
-- enseignant@smartfaculty.test / password123

INSERT INTO utilisateurs (nom, postnom, prenom, email, mot_de_passe, statut) VALUES
    ('Admin', '', 'Smart Faculty', 'admin@smartfaculty.test', '$2y$12$zc9VSTJRb0VTU32CfG/3rOIbQVKgNRpB3WZOWgCF9XNYv03rQc2c.', 'approuve'),
    ('Mbuyi', 'Kanza', 'Aline', 'paritaire@smartfaculty.test', '$2y$12$Rn2Aicui0Oid0WeQGIE0reArxqJv2yD4dkHMdiNeM1IV4mtwKcEvi', 'approuve'),
    ('Kanku', 'Tshibola', 'Grace', 'icp@smartfaculty.test', '$2y$12$pil7tfDHl4zruFpMXgEHMOLA/3VhqZkQtPCXb0Lt1JZ5dsEVLgXfC', 'approuve'),
    ('Kabeya', 'Mutombo', 'Jean', 'doyen@smartfaculty.test', '$2y$12$e14ub6d/S2Kzl8bqP5rrVefATEyrrTzo0bPLWCRbeBMODvRdGppga', 'approuve'),
    ('Ilunga', 'Kasongo', 'Mireille', 'vice.doyen@smartfaculty.test', '$2y$12$67grLsmjWlW0ikw5DdFvYOI8EXK3Z4MPMuyovlRmsE4zgLVpGq4vK', 'approuve'),
    ('Nkosi', 'Mwamba', 'Kevin', 'etudiant@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Mabika', 'Lukusa', 'Paul', 'enseignant@smartfaculty.test', '$2y$12$PnndYqlQBf9csEXVyWA9POT1okgSah97QAYmZ9h.ww2MnaT8Zik/m', 'approuve')
ON DUPLICATE KEY UPDATE email = VALUES(email);

SET @smart_faculty_seed_photo_url = (
    SELECT IF(
        COUNT(*) > 0,
        'UPDATE utilisateurs SET photo_url = ''/assets/images/logo.PNG'' WHERE email IN (''enseignant@smartfaculty.test'', ''enseignant2@smartfaculty.test'', ''assistant1@smartfaculty.test'', ''assistant2@smartfaculty.test'')',
        'SELECT 1'
    )
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'utilisateurs'
      AND COLUMN_NAME = 'photo_url'
);
PREPARE smart_faculty_seed_stmt FROM @smart_faculty_seed_photo_url;
EXECUTE smart_faculty_seed_stmt;
DEALLOCATE PREPARE smart_faculty_seed_stmt;

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'admin@smartfaculty.test' AND r.nom_role = 'administrateur';

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'paritaire@smartfaculty.test' AND r.nom_role = 'paritaire';

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'icp@smartfaculty.test' AND r.nom_role = 'icp';

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'doyen@smartfaculty.test' AND r.nom_role IN ('doyen', 'enseignant');

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'vice.doyen@smartfaculty.test' AND r.nom_role IN ('vice_doyen', 'enseignant');

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'etudiant@smartfaculty.test' AND r.nom_role = 'etudiant';

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'enseignant@smartfaculty.test' AND r.nom_role = 'enseignant';

INSERT IGNORE INTO etudiants (utilisateur_id, matricule, promotion_id)
SELECT u.id, 'SF-L2-0001', p.id
FROM utilisateurs u JOIN promotions p
WHERE u.email = 'etudiant@smartfaculty.test' AND p.nom = 'L2 Informatique';

INSERT IGNORE INTO enseignants (utilisateur_id, departement_id, cours)
SELECT u.id, d.id, 'Programmation PHP MVC'
FROM utilisateurs u JOIN departements d
WHERE u.email IN ('enseignant@smartfaculty.test', 'doyen@smartfaculty.test', 'vice.doyen@smartfaculty.test')
  AND d.nom = 'Informatique';

INSERT INTO utilisateurs (nom, postnom, prenom, email, mot_de_passe, statut) VALUES
    ('Lula', 'Nsimba', 'Sarah', 'etudiant.attente@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'en_attente')
ON DUPLICATE KEY UPDATE email = VALUES(email);

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id FROM utilisateurs u JOIN roles r
WHERE u.email = 'etudiant.attente@smartfaculty.test' AND r.nom_role = 'etudiant';

INSERT IGNORE INTO etudiants (utilisateur_id, matricule, promotion_id)
SELECT u.id, 'SF-L2-0099', p.id
FROM utilisateurs u JOIN promotions p
WHERE u.email = 'etudiant.attente@smartfaculty.test' AND p.nom = 'L2 Informatique';

INSERT INTO demandes_inscription (utilisateur_id, type_demande, statut, message)
SELECT u.id, 'etudiant', 'en_attente', 'Demande de test en attente.'
FROM utilisateurs u
WHERE u.email = 'etudiant.attente@smartfaculty.test'
  AND NOT EXISTS (
      SELECT 1
      FROM demandes_inscription di
      WHERE di.utilisateur_id = u.id
        AND di.type_demande = 'etudiant'
        AND di.statut = 'en_attente'
  );

INSERT INTO annees_academiques (libelle, date_debut, date_fin, active) VALUES
    ('2025-2026', '2025-09-01', '2026-07-31', 1)
ON DUPLICATE KEY UPDATE date_debut = VALUES(date_debut), date_fin = VALUES(date_fin), active = VALUES(active);

INSERT INTO semestres (annee_academique_id, nom, ordre) VALUES
    ((SELECT id FROM annees_academiques WHERE libelle = '2025-2026'), 'Semestre 3', 3),
    ((SELECT id FROM annees_academiques WHERE libelle = '2025-2026'), 'Semestre 4', 4),
    ((SELECT id FROM annees_academiques WHERE libelle = '2025-2026'), 'Semestre 5', 5)
ON DUPLICATE KEY UPDATE nom = VALUES(nom);

INSERT INTO utilisateurs (nom, postnom, prenom, email, mot_de_passe, statut) VALUES
    ('Kalala', 'Mbuyi', 'Sarah', 'etudiant2@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Tshibola', 'Kanku', 'Joel', 'etudiant3@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Kabongo', 'Ilunga', 'Merveille', 'etudiant4@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Mputu', 'Lukusa', 'Daniel', 'etudiant5@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Banza', 'Nkulu', 'Esther', 'etudiant6@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Mulumba', 'Kasongo', 'Arnaud', 'etudiant7@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Tshiala', 'Ngandu', 'Divine', 'etudiant8@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Kabasele', 'Mpoyi', 'Cedric', 'etudiant9@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Nsimba', 'Kalume', 'Prisca', 'etudiant10@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Mukendi', 'Tshomba', 'Laura', 'enseignant2@smartfaculty.test', '$2y$12$M4Co44mSwrtD6uTnpWf2q.ybco/5MBdUsSL2xNmxUbl3IrBz9HcP6', 'approuve'),
    ('Kazadi', 'Mbala', 'Eric', 'assistant1@smartfaculty.test', '$2y$12$M4Co44mSwrtD6uTnpWf2q.ybco/5MBdUsSL2xNmxUbl3IrBz9HcP6', 'approuve'),
    ('Tumba', 'Kayembe', 'Nadine', 'assistant2@smartfaculty.test', '$2y$12$M4Co44mSwrtD6uTnpWf2q.ybco/5MBdUsSL2xNmxUbl3IrBz9HcP6', 'approuve')
ON DUPLICATE KEY UPDATE nom = VALUES(nom), postnom = VALUES(postnom), prenom = VALUES(prenom), statut = VALUES(statut);

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id
FROM utilisateurs u JOIN roles r
WHERE u.email IN (
    'etudiant@smartfaculty.test',
    'etudiant2@smartfaculty.test',
    'etudiant3@smartfaculty.test',
    'etudiant4@smartfaculty.test',
    'etudiant5@smartfaculty.test',
    'etudiant6@smartfaculty.test',
    'etudiant7@smartfaculty.test',
    'etudiant8@smartfaculty.test',
    'etudiant9@smartfaculty.test',
    'etudiant10@smartfaculty.test'
) AND r.nom_role = 'etudiant';

INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
SELECT u.id, r.id
FROM utilisateurs u JOIN roles r
WHERE u.email IN (
    'enseignant2@smartfaculty.test',
    'assistant1@smartfaculty.test',
    'assistant2@smartfaculty.test'
) AND r.nom_role = 'enseignant';

INSERT IGNORE INTO etudiants (utilisateur_id, matricule, promotion_id)
SELECT u.id,
       CASE u.email
           WHEN 'etudiant2@smartfaculty.test' THEN 'SF-L2-0002'
           WHEN 'etudiant3@smartfaculty.test' THEN 'SF-L2-0003'
           WHEN 'etudiant4@smartfaculty.test' THEN 'SF-L2-0004'
           WHEN 'etudiant5@smartfaculty.test' THEN 'SF-L2-0005'
           WHEN 'etudiant6@smartfaculty.test' THEN 'SF-L2-0006'
           WHEN 'etudiant7@smartfaculty.test' THEN 'SF-L3-0007'
           WHEN 'etudiant8@smartfaculty.test' THEN 'SF-L3-0008'
           WHEN 'etudiant9@smartfaculty.test' THEN 'SF-L3-0009'
           WHEN 'etudiant10@smartfaculty.test' THEN 'SF-L3-0010'
       END,
       CASE
           WHEN u.email IN ('etudiant7@smartfaculty.test', 'etudiant8@smartfaculty.test', 'etudiant9@smartfaculty.test', 'etudiant10@smartfaculty.test')
               THEN (SELECT id FROM promotions WHERE nom = 'L3 Informatique')
           ELSE (SELECT id FROM promotions WHERE nom = 'L2 Informatique')
       END
FROM utilisateurs u
WHERE u.email IN (
    'etudiant2@smartfaculty.test',
    'etudiant3@smartfaculty.test',
    'etudiant4@smartfaculty.test',
    'etudiant5@smartfaculty.test',
    'etudiant6@smartfaculty.test',
    'etudiant7@smartfaculty.test',
    'etudiant8@smartfaculty.test',
    'etudiant9@smartfaculty.test',
    'etudiant10@smartfaculty.test'
);

INSERT IGNORE INTO enseignants (utilisateur_id, departement_id, cours)
SELECT u.id, d.id,
       CASE u.email
           WHEN 'enseignant2@smartfaculty.test' THEN 'Algorithmique avancee, Architecture logicielle'
           WHEN 'assistant1@smartfaculty.test' THEN 'Travaux pratiques web'
           WHEN 'assistant2@smartfaculty.test' THEN 'Laboratoire bases de donnees'
       END
FROM utilisateurs u JOIN departements d
WHERE u.email IN ('enseignant2@smartfaculty.test', 'assistant1@smartfaculty.test', 'assistant2@smartfaculty.test')
  AND d.nom = 'Informatique';

INSERT INTO cours (
    promotion_id,
    semestre_id,
    code,
    nom,
    description,
    nombre_heures,
    credits,
    objectifs,
    modalites_evaluation,
    statut_notes
) VALUES
    ((SELECT id FROM promotions WHERE nom = 'L2 Informatique'), (SELECT id FROM semestres WHERE ordre = 3), 'ALGO2', 'Algorithmique II', 'Structures de donnees, tris, graphes et complexite.', 60, 6, 'Maitriser les algorithmes fondamentaux et analyser leur complexite.', 'Interrogations 20%, TP 30%, examen 50%.', 'publiees'),
    ((SELECT id FROM promotions WHERE nom = 'L2 Informatique'), (SELECT id FROM semestres WHERE ordre = 3), 'BDD2', 'Bases de donnees II', 'Modelisation relationnelle avancee, SQL et transactions.', 60, 6, 'Concevoir et interroger une base de donnees robuste.', 'TP 30%, interrogation 20%, examen 50%.', 'publiees'),
    ((SELECT id FROM promotions WHERE nom = 'L2 Informatique'), (SELECT id FROM semestres WHERE ordre = 4), 'WEB2', 'Developpement Web PHP', 'Applications web MVC, securite et API REST.', 45, 5, 'Construire une application web PHP maintenable et securisee.', 'Projet 40%, TP 20%, examen 40%.', 'publiees'),
    ((SELECT id FROM promotions WHERE nom = 'L2 Informatique'), (SELECT id FROM semestres WHERE ordre = 4), 'GL2', 'Genie logiciel', 'Analyse, architecture, tests et gestion de projet logiciel.', 45, 5, 'Comprendre le cycle de vie logiciel et les pratiques qualite.', 'Devoir 30%, projet 30%, examen 40%.', 'brouillon'),
    ((SELECT id FROM promotions WHERE nom = 'L3 Informatique'), (SELECT id FROM semestres WHERE ordre = 5), 'IA1', 'Introduction a l intelligence artificielle', 'Recherche, heuristiques, classification et evaluation.', 60, 6, 'Comprendre les bases de l IA appliquee.', 'TP 30%, interrogation 20%, examen 50%.', 'publiees'),
    ((SELECT id FROM promotions WHERE nom = 'L3 Informatique'), (SELECT id FROM semestres WHERE ordre = 5), 'ARCH3', 'Architecture des systemes', 'Systemes distribues, performance et supervision.', 45, 5, 'Analyser et concevoir des architectures fiables.', 'Projet 40%, examen 60%.', 'brouillon')
ON DUPLICATE KEY UPDATE
    nom = VALUES(nom),
    description = VALUES(description),
    nombre_heures = VALUES(nombre_heures),
    credits = VALUES(credits),
    statut_notes = VALUES(statut_notes);

INSERT IGNORE INTO cours_enseignants (cours_id, enseignant_id, role_enseignement)
SELECT c.id, e.id, 'principal'
FROM cours c
JOIN enseignants e
JOIN utilisateurs u ON u.id = e.utilisateur_id
WHERE (c.code IN ('ALGO2', 'WEB2', 'IA1', 'GL2') AND u.email = 'enseignant@smartfaculty.test')
   OR (c.code IN ('BDD2', 'ARCH3') AND u.email = 'enseignant2@smartfaculty.test');

INSERT IGNORE INTO cours_enseignants (cours_id, enseignant_id, role_enseignement)
SELECT c.id, e.id, 'assistant'
FROM cours c
JOIN enseignants e
JOIN utilisateurs u ON u.id = e.utilisateur_id
WHERE (c.code IN ('WEB2', 'GL2') AND u.email = 'assistant1@smartfaculty.test')
   OR (c.code IN ('ALGO2', 'BDD2', 'IA1', 'ARCH3') AND u.email = 'assistant2@smartfaculty.test');

INSERT IGNORE INTO cours_assistants (cours_id, enseignant_id)
SELECT cours_id, enseignant_id
FROM cours_enseignants
WHERE role_enseignement = 'assistant';

INSERT IGNORE INTO inscriptions_cours (etudiant_id, cours_id)
SELECT e.id, c.id
FROM etudiants e
JOIN promotions p ON p.id = e.promotion_id
JOIN cours c ON c.promotion_id = p.id
JOIN utilisateurs u ON u.id = e.utilisateur_id
WHERE u.statut = 'approuve';

INSERT INTO types_notes (code, libelle, poids) VALUES
    ('interrogation', 'Interrogation', 0.20),
    ('travail_pratique', 'Travail pratique', 0.30),
    ('examen', 'Examen', 0.50),
    ('moyenne_finale', 'Moyenne finale', 1.00)
ON DUPLICATE KEY UPDATE libelle = VALUES(libelle), poids = VALUES(poids);

INSERT INTO notes (etudiant_id, cours_id, type_note_id, enseignant_id, valeur, statut, verrouille, date_publication)
SELECT ic.etudiant_id,
       ic.cours_id,
       tn.id,
       ce.enseignant_id,
       ROUND(8.50 + MOD(ic.etudiant_id + ic.cours_id + tn.id, 8), 2),
       'publie',
       1,
       NOW()
FROM inscriptions_cours ic
JOIN cours c ON c.id = ic.cours_id
JOIN types_notes tn ON tn.code IN ('interrogation', 'travail_pratique', 'examen', 'moyenne_finale')
JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = 'principal'
WHERE c.code IN ('ALGO2', 'BDD2', 'WEB2', 'IA1')
ON DUPLICATE KEY UPDATE valeur = VALUES(valeur), statut = VALUES(statut), verrouille = VALUES(verrouille), date_publication = VALUES(date_publication);

INSERT INTO notes (etudiant_id, cours_id, type_note_id, enseignant_id, valeur, statut, verrouille)
SELECT ic.etudiant_id,
       ic.cours_id,
       tn.id,
       ce.enseignant_id,
       ROUND(9.00 + MOD(ic.etudiant_id + ic.cours_id, 7), 2),
       'brouillon',
       0
FROM inscriptions_cours ic
JOIN cours c ON c.id = ic.cours_id
JOIN types_notes tn ON tn.code = 'moyenne_finale'
JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = 'principal'
WHERE c.code IN ('GL2', 'ARCH3')
ON DUPLICATE KEY UPDATE valeur = VALUES(valeur), statut = VALUES(statut), verrouille = VALUES(verrouille);

INSERT INTO publications_valve (cours_id, enseignant_id, type_publication, titre, contenu, statut, visibilite, date_publication)
SELECT c.id, ce.enseignant_id, 'annonce',
       CONCAT('Bienvenue dans le cours ', c.nom),
       CONCAT('La valve du cours ', c.nom, ' centralise les annonces, documents, consignes et notes publiees.'),
       'publie',
       'etudiants',
       NOW() - INTERVAL MOD(c.id, 5) DAY
FROM cours c
JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = 'principal'
ON DUPLICATE KEY UPDATE titre = VALUES(titre);

INSERT INTO publications_valve (cours_id, enseignant_id, type_publication, titre, contenu, statut, visibilite, date_publication)
SELECT c.id, ce.enseignant_id, 'devoir',
       CONCAT('Travail pratique - ', c.code),
       'Consignes disponibles. Le depot doit etre effectue avant la prochaine seance.',
       'publie',
       'etudiants',
       NOW() - INTERVAL (MOD(c.id, 4) + 1) DAY
FROM cours c
JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = 'principal'
WHERE c.code IN ('ALGO2', 'BDD2', 'WEB2')
ON DUPLICATE KEY UPDATE contenu = VALUES(contenu);

INSERT INTO publications_valve (cours_id, enseignant_id, type_publication, titre, contenu, statut, visibilite, est_important, verrouille, date_publication)
SELECT c.id, ce.enseignant_id, 'publication_notes',
       CONCAT('Notes publiees - ', c.code),
       CONCAT('Les notes du cours ', c.nom, ' ont ete publiees.'),
       'verrouille',
       'etudiants',
       1,
       1,
       NOW()
FROM cours c
JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = 'principal'
WHERE c.code IN ('ALGO2', 'BDD2', 'WEB2', 'IA1')
ON DUPLICATE KEY UPDATE contenu = VALUES(contenu), est_important = VALUES(est_important), verrouille = VALUES(verrouille);

INSERT IGNORE INTO documents_cours (cours_id, publication_id, titre, url_document, type_document)
SELECT c.id, NULL, CONCAT('Plan du cours ', c.code), CONCAT('/documents/', LOWER(c.code), '-plan.pdf'), 'pdf'
FROM cours c;

INSERT INTO alertes_academiques (etudiant_id, cours_id, titre, message, niveau)
SELECT n.etudiant_id,
       n.cours_id,
       'Moyenne faible',
       CONCAT('Attention : votre moyenne en ', c.nom, ' est faible.'),
       'danger'
FROM notes n
JOIN cours c ON c.id = n.cours_id
JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = 'moyenne_finale'
WHERE n.statut = 'publie'
  AND n.valeur < 10
  AND NOT EXISTS (
      SELECT 1
      FROM alertes_academiques aa
      WHERE aa.etudiant_id = n.etudiant_id
        AND aa.cours_id = n.cours_id
        AND aa.titre = 'Moyenne faible'
  );

INSERT INTO reclamations (etudiant_id, cours_id, note_id, titre, type_reclamation, description, statut, priorite)
SELECT n.etudiant_id,
       n.cours_id,
       n.id,
       CONCAT('Verification note ', c.code),
       'note',
       'Je souhaite verifier le detail de ma note publiee.',
       'en_attente',
       'normale'
FROM notes n
JOIN cours c ON c.id = n.cours_id
JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = 'moyenne_finale'
JOIN etudiants e ON e.id = n.etudiant_id
JOIN utilisateurs u ON u.id = e.utilisateur_id
WHERE n.statut = 'publie'
  AND u.email IN ('etudiant@smartfaculty.test', 'etudiant2@smartfaculty.test')
  AND NOT EXISTS (
      SELECT 1
      FROM reclamations r
      WHERE r.etudiant_id = n.etudiant_id
        AND r.cours_id = n.cours_id
        AND r.titre = CONCAT('Verification note ', c.code)
  )
LIMIT 2;
