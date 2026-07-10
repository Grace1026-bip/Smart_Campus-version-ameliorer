<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;

class EnseignantService
{
    public static function tableauDeBord(int $utilisateurId): array
    {
        $enseignantId = CoursService::enseignantId($utilisateurId);
        $profil = self::profil($enseignantId);
        $cours = CoursService::coursEnseignant($enseignantId);
        $reclamations = ReclamationService::reclamationsEnseignant($enseignantId);
        $risques = self::etudiantsRisque($enseignantId);
        $publications = ValveService::valveEnseignant($enseignantId);

        return [
            'profil' => $profil,
            'nombre_cours' => count($cours),
            'nombre_total_etudiants' => self::nombreEtudiants($enseignantId),
            'notes_brouillon' => self::compterNotes($enseignantId, 'brouillon'),
            'notes_publiees' => self::compterNotes($enseignantId, 'publie'),
            'nombre_publications' => count($publications),
            'nombre_reclamations_en_attente' => self::compterReclamations($enseignantId, 'en_attente'),
            'nombre_etudiants_a_risque' => count($risques),
            'publications_recentes' => array_slice($publications, 0, 5),
            'cours_recents' => array_slice($cours, 0, 5),
            'reclamations' => array_slice($reclamations, 0, 5),
            'nombre_reclamations' => count($reclamations),
            'etudiants_a_risque' => array_slice($risques, 0, 8),
            'dernieres_activites' => self::dernieresActivites($cours, $publications, $reclamations, $risques),
            'statistiques_cours' => array_map(
                static fn (array $cours): array => [
                    'cours_id' => $cours['id'],
                    'code' => $cours['code'],
                    'cours' => $cours['nom'],
                    'promotion' => $cours['promotion'],
                    'nombre_etudiants' => $cours['nombre_etudiants'],
                    'statistiques' => NoteService::statistiquesCours((int) $cours['id']),
                ],
                $cours
            ),
        ];
    }

    public static function profil(int $enseignantId): array
    {
        $photoSql = self::colonneExiste('utilisateurs', 'photo_url') ? 'u.photo_url' : 'NULL';

        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, d.nom AS departement, e.cours AS specialites,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email, u.statut,
                    ' . $photoSql . ' AS photo_url
             FROM enseignants e
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN departements d ON d.id = e.departement_id
             WHERE e.id = :enseignant_id
             LIMIT 1'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);
        $profil = $requete->fetch() ?: [];

        if ($profil !== []) {
            $profil['id'] = (int) $profil['id'];
        }

        return $profil;
    }

    private static function dernieresActivites(array $cours, array $publications, array $reclamations, array $risques): array
    {
        $activites = [];

        foreach (array_slice($publications, 0, 4) as $publication) {
            $activites[] = [
                'type' => 'publication',
                'titre' => $publication['titre'] ?? 'Publication valve',
                'detail' => ($publication['cours'] ?? 'Cours') . ' - ' . ($publication['date_publication'] ?? ''),
                'date' => $publication['date_publication'] ?? null,
            ];
        }

        foreach (array_slice($reclamations, 0, 3) as $reclamation) {
            $activites[] = [
                'type' => 'reclamation',
                'titre' => $reclamation['titre'] ?? 'Reclamation',
                'detail' => ($reclamation['etudiant'] ?? 'Etudiant') . ' - ' . ($reclamation['statut'] ?? ''),
                'date' => $reclamation['date_creation'] ?? null,
            ];
        }

        foreach (array_slice($risques, 0, 3) as $risque) {
            $activites[] = [
                'type' => 'risque',
                'titre' => $risque['nom'] ?? 'Etudiant a risque',
                'detail' => ($risque['cours'] ?? 'Cours') . ' - moyenne ' . ($risque['moyenne'] ?? '-'),
                'date' => null,
            ];
        }

        foreach (array_slice($cours, 0, 2) as $coursItem) {
            $activites[] = [
                'type' => 'cours',
                'titre' => $coursItem['nom'] ?? 'Cours attribue',
                'detail' => ($coursItem['promotion'] ?? '-') . ' - ' . ($coursItem['statut_notes'] ?? '-'),
                'date' => null,
            ];
        }

        usort($activites, static function (array $a, array $b): int {
            return strcmp((string) ($b['date'] ?? ''), (string) ($a['date'] ?? ''));
        });

        return array_slice($activites, 0, 8);
    }

    public static function etudiantsRisque(int $enseignantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            self::risquesSql() . '
             INNER JOIN cours_enseignants ce ON ce.cours_id = c.id
             WHERE ce.enseignant_id = :enseignant_id
               AND n.statut = "publie"
               AND tn.code = "moyenne_finale"
               AND n.valeur < 12
             ORDER BY n.valeur ASC'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);

        return array_map([self::class, 'formaterRisque'], $requete->fetchAll());
    }

    public static function etudiantsRisqueCours(int $enseignantId, int $coursId): array
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        $requete = BaseDeDonnees::connexion()->prepare(
            self::risquesSql() . '
             WHERE c.id = :cours_id
               AND n.statut = "publie"
               AND tn.code = "moyenne_finale"
               AND n.valeur < 12
             ORDER BY n.valeur ASC'
        );
        $requete->execute(['cours_id' => $coursId]);

        return array_map([self::class, 'formaterRisque'], $requete->fetchAll());
    }

    private static function compterNotes(int $enseignantId, string $statut): int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*)
             FROM notes n
             INNER JOIN cours_enseignants ce ON ce.cours_id = n.cours_id
             WHERE ce.enseignant_id = :enseignant_id
               AND n.statut = :statut'
        );
        $requete->execute(['enseignant_id' => $enseignantId, 'statut' => $statut]);

        return (int) $requete->fetchColumn();
    }

    private static function nombreEtudiants(int $enseignantId): int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(DISTINCT ic.etudiant_id)
             FROM inscriptions_cours ic
             INNER JOIN cours_enseignants ce ON ce.cours_id = ic.cours_id
             WHERE ce.enseignant_id = :enseignant_id'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);

        return (int) $requete->fetchColumn();
    }

    private static function compterReclamations(int $enseignantId, string $statut): int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*)
             FROM reclamations r
             INNER JOIN cours_enseignants ce ON ce.cours_id = r.cours_id
             WHERE ce.enseignant_id = :enseignant_id
               AND r.statut = :statut'
        );
        $requete->execute(['enseignant_id' => $enseignantId, 'statut' => $statut]);

        return (int) $requete->fetchColumn();
    }

    private static function colonneExiste(string $table, string $colonne): bool
    {
        static $cache = [];

        $cle = $table . '.' . $colonne;
        if (array_key_exists($cle, $cache)) {
            return $cache[$cle];
        }

        try {
            $requete = BaseDeDonnees::connexion()->prepare(
                'SELECT COUNT(*)
                 FROM INFORMATION_SCHEMA.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = :table
                   AND COLUMN_NAME = :colonne'
            );
            $requete->execute(['table' => $table, 'colonne' => $colonne]);

            return $cache[$cle] = (int) $requete->fetchColumn() > 0;
        } catch (\Throwable) {
            return $cache[$cle] = false;
        }
    }

    private static function risquesSql(): string
    {
        return 'SELECT e.id AS etudiant_id, e.matricule,
                       CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom,
                       p.nom AS promotion,
                       c.id AS cours_id, c.code AS code_cours, c.nom AS cours,
                       n.valeur AS moyenne
                FROM notes n
                INNER JOIN types_notes tn ON tn.id = n.type_note_id
                INNER JOIN etudiants e ON e.id = n.etudiant_id
                INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                INNER JOIN promotions p ON p.id = e.promotion_id
                INNER JOIN cours c ON c.id = n.cours_id';
    }

    private static function formaterRisque(array $risque): array
    {
        $moyenne = (float) $risque['moyenne'];
        $risque['etudiant_id'] = (int) $risque['etudiant_id'];
        $risque['cours_id'] = (int) $risque['cours_id'];
        $risque['moyenne'] = $moyenne;
        $risque['niveau'] = $moyenne < 10 ? 'eleve' : ($moyenne < 11 ? 'moyen' : 'faible');
        $risque['motif'] = $moyenne < 10
            ? 'Moyenne finale inferieure a 10/20.'
            : 'Moyenne finale proche du seuil de reussite.';

        return $risque;
    }
}
