<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\Cours;
use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;

class CoursService
{
    public static function etudiantId(int $utilisateurId): int
    {
        $id = Cours::etudiantIdDepuisUtilisateur($utilisateurId);

        if ($id === null) {
            throw new ExceptionHttp('Profil etudiant introuvable.', 404);
        }

        return $id;
    }

    public static function enseignantId(int $utilisateurId): int
    {
        $id = Cours::enseignantIdDepuisUtilisateur($utilisateurId);

        if ($id === null) {
            throw new ExceptionHttp('Profil enseignant introuvable.', 404);
        }

        return $id;
    }

    public static function verifierCoursEtudiant(int $etudiantId, int $coursId): void
    {
        if (!Cours::coursAppartientEtudiant($etudiantId, $coursId)) {
            throw new ExceptionHttp('Cours introuvable dans votre promotion.', 403);
        }
    }

    public static function verifierCoursEnseignant(int $enseignantId, int $coursId): void
    {
        if (!Cours::coursAppartientEnseignant($enseignantId, $coursId)) {
            throw new ExceptionHttp('Vous ne pouvez pas acceder a ce cours.', 403);
        }
    }

    public static function coursEtudiant(int $etudiantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            self::baseCoursSql() . '
             INNER JOIN inscriptions_cours ic ON ic.cours_id = c.id
             WHERE ic.etudiant_id = :etudiant_id
             ORDER BY s.ordre ASC, c.nom ASC'
        );
        $requete->execute(['etudiant_id' => $etudiantId]);

        return array_map([self::class, 'formaterCours'], $requete->fetchAll());
    }

    public static function detailCoursEtudiant(int $etudiantId, int $coursId): array
    {
        self::verifierCoursEtudiant($etudiantId, $coursId);

        return self::detailCours($coursId, $etudiantId);
    }

    public static function coursEnseignant(int $enseignantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            self::baseCoursSql() . '
             INNER JOIN cours_enseignants filtre ON filtre.cours_id = c.id
             WHERE filtre.enseignant_id = :enseignant_id
             ORDER BY p.nom ASC, s.ordre ASC, c.nom ASC'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);

        return array_map([self::class, 'formaterCours'], $requete->fetchAll());
    }

    public static function detailCoursEnseignant(int $enseignantId, int $coursId): array
    {
        self::verifierCoursEnseignant($enseignantId, $coursId);

        return self::detailCours($coursId, null, $enseignantId);
    }

    public static function etudiantsCours(int $enseignantId, int $coursId): array
    {
        self::verifierCoursEnseignant($enseignantId, $coursId);

        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.matricule, p.nom AS promotion,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email,
                    (
                        SELECT n.valeur
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        WHERE n.etudiant_id = e.id AND n.cours_id = :cours_id_moyenne
                        LIMIT 1
                    ) AS moyenne
             FROM inscriptions_cours ic
             INNER JOIN etudiants e ON e.id = ic.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             INNER JOIN promotions p ON p.id = e.promotion_id
             WHERE ic.cours_id = :cours_id
             ORDER BY u.nom ASC, u.prenom ASC'
        );
        $requete->execute([
            'cours_id' => $coursId,
            'cours_id_moyenne' => $coursId,
        ]);

        return array_map(static function (array $ligne): array {
            $ligne['id'] = (int) $ligne['id'];
            $ligne['moyenne'] = $ligne['moyenne'] === null ? null : (float) $ligne['moyenne'];

            return $ligne;
        }, $requete->fetchAll());
    }

    public static function detailCours(int $coursId, ?int $etudiantId = null, ?int $enseignantId = null): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            self::baseCoursSql() . '
             WHERE c.id = :cours_id
             LIMIT 1'
        );
        $requete->execute(['cours_id' => $coursId]);
        $cours = $requete->fetch();

        if (!$cours) {
            throw new ExceptionHttp('Cours introuvable.', 404);
        }

        $detail = self::formaterCours($cours);
        $detail['documents'] = self::documentsCours($coursId);
        $detail['publications'] = ValveService::publicationsCours($coursId, $etudiantId !== null);
        $detail['notes'] = $etudiantId !== null
            ? NoteService::notesEtudiantCours($etudiantId, $coursId)
            : NoteService::notesCours($coursId);
        $detail['statistiques'] = NoteService::statistiquesCours($coursId);

        if ($etudiantId !== null) {
            $detail['reclamations'] = array_values(array_filter(
                ReclamationService::reclamationsEtudiant($etudiantId),
                static fn (array $reclamation): bool => (int) ($reclamation['cours_id'] ?? 0) === $coursId
            ));
        }

        if ($enseignantId !== null) {
            $detail['etudiants'] = self::etudiantsCours($enseignantId, $coursId);
            $detail['reclamations'] = ReclamationService::reclamationsCours($enseignantId, $coursId);
            $detail['etudiants_a_risque'] = EnseignantService::etudiantsRisqueCours($enseignantId, $coursId);
        }

        return $detail;
    }

    public static function documentsCours(int $coursId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id, cours_id, publication_id, titre, url_document, type_document, date_creation
             FROM documents_cours
             WHERE cours_id = :cours_id
             ORDER BY date_creation DESC'
        );
        $requete->execute(['cours_id' => $coursId]);

        return array_map(static function (array $document): array {
            $document['id'] = (int) $document['id'];
            $document['cours_id'] = (int) $document['cours_id'];
            $document['publication_id'] = $document['publication_id'] === null ? null : (int) $document['publication_id'];

            return $document;
        }, $requete->fetchAll());
    }

    private static function baseCoursSql(): string
    {
        return 'SELECT c.id, c.code, c.nom, c.description, c.nombre_heures, c.credits,
                       c.objectifs, c.modalites_evaluation, c.statut_notes,
                       p.id AS promotion_id, p.nom AS promotion, p.niveau,
                       s.id AS semestre_id, s.nom AS semestre, s.ordre AS ordre_semestre,
                       aa.libelle AS annee_academique,
                       (
                           SELECT CONCAT_WS(" ", u.nom, u.postnom, u.prenom)
                           FROM cours_enseignants ce
                           INNER JOIN enseignants e ON e.id = ce.enseignant_id
                           INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                           WHERE ce.cours_id = c.id AND ce.role_enseignement = "principal"
                           LIMIT 1
                       ) AS enseignant_principal,
                       (
                           SELECT GROUP_CONCAT(CONCAT_WS(" ", u.nom, u.postnom, u.prenom) SEPARATOR "||")
                           FROM cours_enseignants ce
                           INNER JOIN enseignants e ON e.id = ce.enseignant_id
                           INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                           WHERE ce.cours_id = c.id AND ce.role_enseignement = "assistant"
                       ) AS assistants,
                       (
                           SELECT COUNT(*)
                           FROM inscriptions_cours ic2
                           WHERE ic2.cours_id = c.id
                       ) AS nombre_etudiants,
                       (
                           SELECT COUNT(*)
                           FROM publications_valve pv
                           WHERE pv.cours_id = c.id AND pv.statut IN ("publie", "verrouille")
                       ) AS nombre_publications,
                       (
                           SELECT pv.titre
                           FROM publications_valve pv
                           WHERE pv.cours_id = c.id AND pv.statut IN ("publie", "verrouille")
                           ORDER BY pv.date_publication DESC
                           LIMIT 1
                       ) AS derniere_publication
                FROM cours c
                INNER JOIN promotions p ON p.id = c.promotion_id
                INNER JOIN semestres s ON s.id = c.semestre_id
                INNER JOIN annees_academiques aa ON aa.id = s.annee_academique_id';
    }

    private static function formaterCours(array $cours): array
    {
        return [
            'id' => (int) $cours['id'],
            'code' => $cours['code'],
            'nom' => $cours['nom'],
            'description' => $cours['description'],
            'promotion_id' => (int) $cours['promotion_id'],
            'promotion' => $cours['promotion'],
            'niveau' => $cours['niveau'],
            'semestre_id' => (int) $cours['semestre_id'],
            'semestre' => $cours['semestre'],
            'annee_academique' => $cours['annee_academique'],
            'nombre_heures' => (int) $cours['nombre_heures'],
            'credits' => (int) $cours['credits'],
            'objectifs' => $cours['objectifs'],
            'modalites_evaluation' => $cours['modalites_evaluation'],
            'enseignant_principal' => $cours['enseignant_principal'],
            'assistants' => $cours['assistants'] ? explode('||', $cours['assistants']) : [],
            'nombre_etudiants' => (int) $cours['nombre_etudiants'],
            'nombre_publications' => (int) $cours['nombre_publications'],
            'derniere_publication' => $cours['derniere_publication'],
            'statut_notes' => $cours['statut_notes'],
        ];
    }
}
