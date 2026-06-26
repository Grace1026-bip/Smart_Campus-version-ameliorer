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
-- enseignant@smartfaculty.test / Enseignant@123456

INSERT INTO utilisateurs (nom, postnom, prenom, email, mot_de_passe, statut) VALUES
    ('Admin', '', 'Smart Faculty', 'admin@smartfaculty.test', '$2y$12$zc9VSTJRb0VTU32CfG/3rOIbQVKgNRpB3WZOWgCF9XNYv03rQc2c.', 'approuve'),
    ('Mbuyi', 'Kanza', 'Aline', 'paritaire@smartfaculty.test', '$2y$12$Rn2Aicui0Oid0WeQGIE0reArxqJv2yD4dkHMdiNeM1IV4mtwKcEvi', 'approuve'),
    ('Kanku', 'Tshibola', 'Grace', 'icp@smartfaculty.test', '$2y$12$pil7tfDHl4zruFpMXgEHMOLA/3VhqZkQtPCXb0Lt1JZ5dsEVLgXfC', 'approuve'),
    ('Kabeya', 'Mutombo', 'Jean', 'doyen@smartfaculty.test', '$2y$12$e14ub6d/S2Kzl8bqP5rrVefATEyrrTzo0bPLWCRbeBMODvRdGppga', 'approuve'),
    ('Ilunga', 'Kasongo', 'Mireille', 'vice.doyen@smartfaculty.test', '$2y$12$67grLsmjWlW0ikw5DdFvYOI8EXK3Z4MPMuyovlRmsE4zgLVpGq4vK', 'approuve'),
    ('Nkosi', 'Mwamba', 'Kevin', 'etudiant@smartfaculty.test', '$2y$12$8WLIL8nxYBQWbKufWLRca.eJwaGQPsEi5cfEhWRgfjAa1KuPeTufy', 'approuve'),
    ('Mabika', 'Lukusa', 'Paul', 'enseignant@smartfaculty.test', '$2y$12$M4Co44mSwrtD6uTnpWf2q.ybco/5MBdUsSL2xNmxUbl3IrBz9HcP6', 'approuve')
ON DUPLICATE KEY UPDATE email = VALUES(email);

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
