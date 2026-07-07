USE smart_faculty;

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

DELETE FROM sessions_utilisateurs
WHERE actif = 0
   OR date_expiration < NOW();

SET @smart_faculty_migrate_assistants = (
    SELECT IF(
        COUNT(*) > 0,
        'INSERT IGNORE INTO cours_enseignants (cours_id, enseignant_id, role_enseignement)
         SELECT cours_id, enseignant_id, ''assistant''
         FROM cours_assistants',
        'SELECT 1'
    )
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'cours_assistants'
);
PREPARE smart_faculty_stmt FROM @smart_faculty_migrate_assistants;
EXECUTE smart_faculty_stmt;
DEALLOCATE PREPARE smart_faculty_stmt;

SET @smart_faculty_migrate_documents = (
    SELECT IF(
        COUNT(*) > 0,
        'INSERT INTO publications_valve (
             cours_id,
             enseignant_id,
             type_publication,
             titre,
             contenu,
             piece_jointe_url,
             statut,
             visibilite,
             est_important,
             verrouille,
             date_publication
         )
         SELECT dc.cours_id,
                enseignants_ref.enseignant_id,
                ''support_de_cours'',
                dc.titre,
                CONCAT(''Support disponible: '', dc.titre),
                dc.url_document,
                ''publie'',
                ''etudiants'',
                0,
                0,
                COALESCE(dc.date_creation, NOW())
         FROM documents_cours dc
         INNER JOIN (
             SELECT cours_id,
                    COALESCE(
                        MAX(CASE WHEN role_enseignement = ''principal'' THEN enseignant_id END),
                        MIN(enseignant_id)
                    ) AS enseignant_id
             FROM cours_enseignants
             GROUP BY cours_id
         ) enseignants_ref ON enseignants_ref.cours_id = dc.cours_id
         LEFT JOIN publications_valve pv
                ON pv.cours_id = dc.cours_id
               AND pv.type_publication = ''support_de_cours''
               AND pv.titre = dc.titre
         WHERE dc.url_document IS NOT NULL
           AND dc.url_document <> ''''
           AND pv.id IS NULL
         ON DUPLICATE KEY UPDATE
             piece_jointe_url = VALUES(piece_jointe_url),
             contenu = VALUES(contenu),
             statut = ''publie'',
             visibilite = ''etudiants''',
        'SELECT 1'
    )
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'documents_cours'
);
PREPARE smart_faculty_stmt FROM @smart_faculty_migrate_documents;
EXECUTE smart_faculty_stmt;
DEALLOCATE PREPARE smart_faculty_stmt;

DROP TABLE IF EXISTS documents_cours;
DROP TABLE IF EXISTS cours_assistants;
