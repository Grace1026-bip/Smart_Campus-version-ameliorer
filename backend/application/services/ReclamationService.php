<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;

class ReclamationService
{
    private const STATUTS_ENSEIGNANT = ['en_attente', 'en_cours', 'resolue', 'transmise_apparitorat'];
    private const TYPES = ['note', 'cours', 'horaire', 'document', 'autre'];
    private const PRIORITES = ['faible', 'normale', 'haute'];

    public static function creer(int $etudiantId, array $donnees): array
    {
        $coursId = !empty($donnees['cours_id']) ? (int) $donnees['cours_id'] : null;
        $noteId = !empty($donnees['note_id']) ? (int) $donnees['note_id'] : null;
        $titre = nettoyer_chaine($donnees['titre'] ?? '');
        $description = nettoyer_chaine($donnees['description'] ?? '');
        $type = (string) ($donnees['type_reclamation'] ?? $donnees['type'] ?? 'note');
        $priorite = (string) ($donnees['priorite'] ?? 'normale');

        if ($titre === '' || $description === '') {
            throw new ExceptionHttp('Titre et description obligatoires.', 422);
        }

        if ($coursId === null && $noteId === null) {
            throw new ExceptionHttp('Cours ou note concernee obligatoire.', 422);
        }

        if (!in_array($type, self::TYPES, true)) {
            throw new ExceptionHttp('Type de reclamation invalide.', 422);
        }

        if (!in_array($priorite, self::PRIORITES, true)) {
            throw new ExceptionHttp('Priorite de reclamation invalide.', 422);
        }

        if ($coursId !== null) {
            CoursService::verifierCoursEtudiant($etudiantId, $coursId);
        }

        if ($noteId !== null) {
            $note = self::noteEtudiant($etudiantId, $noteId);
            if ($coursId !== null && (int) $note['cours_id'] !== $coursId) {
                throw new ExceptionHttp('La note selectionnee ne correspond pas au cours choisi.', 422);
            }

            $coursId = (int) $note['cours_id'];
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO reclamations (etudiant_id, cours_id, note_id, titre, type_reclamation, description, priorite)
             VALUES (:etudiant_id, :cours_id, :note_id, :titre, :type_reclamation, :description, :priorite)'
        );
        $requete->execute([
            'etudiant_id' => $etudiantId,
            'cours_id' => $coursId,
            'note_id' => $noteId,
            'titre' => $titre,
            'type_reclamation' => $type,
            'description' => $description,
            'priorite' => $priorite,
        ]);

        return self::reclamation((int) BaseDeDonnees::connexion()->lastInsertId());
    }

    public static function reclamationsEtudiant(int $etudiantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(self::baseSql() . ' WHERE r.etudiant_id = :etudiant_id ORDER BY r.date_creation DESC');
        $requete->execute(['etudiant_id' => $etudiantId]);

        return array_map([self::class, 'formater'], $requete->fetchAll());
    }

    public static function reclamationsEnseignant(int $enseignantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            self::baseSql() . '
             INNER JOIN cours_enseignants ce ON ce.cours_id = r.cours_id
             WHERE ce.enseignant_id = :enseignant_id
             ORDER BY r.date_creation DESC'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);

        return array_map([self::class, 'formater'], $requete->fetchAll());
    }

    public static function reclamationsCours(int $enseignantId, int $coursId): array
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        $requete = BaseDeDonnees::connexion()->prepare(self::baseSql() . ' WHERE r.cours_id = :cours_id ORDER BY r.date_creation DESC');
        $requete->execute(['cours_id' => $coursId]);

        return array_map([self::class, 'formater'], $requete->fetchAll());
    }

    public static function reclamationEnseignant(int $enseignantId, int $reclamationId): array
    {
        $reclamation = self::reclamation($reclamationId);

        if ($reclamation['cours_id'] === null) {
            throw new ExceptionHttp('Cette reclamation n est pas liee a un cours enseignant.', 403);
        }

        CoursService::verifierCoursEnseignant($enseignantId, (int) $reclamation['cours_id']);

        return $reclamation;
    }

    public static function repondre(int $enseignantId, int $utilisateurId, int $reclamationId, array $donnees): array
    {
        $reclamation = self::reclamationEnseignant($enseignantId, $reclamationId);

        $message = nettoyer_chaine($donnees['message'] ?? $donnees['reponse'] ?? '');
        if ($message === '') {
            throw new ExceptionHttp('Message de reponse obligatoire.', 422);
        }

        $statut = (string) ($donnees['statut'] ?? 'en_cours');
        if ($statut === 'transmise') {
            $statut = 'transmise_apparitorat';
        }

        if (!in_array($statut, self::STATUTS_ENSEIGNANT, true)) {
            throw new ExceptionHttp('Statut de reclamation invalide.', 422);
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO reponses_reclamations (reclamation_id, utilisateur_id, message)
             VALUES (:reclamation_id, :utilisateur_id, :message)'
        );
        $requete->execute([
            'reclamation_id' => $reclamationId,
            'utilisateur_id' => $utilisateurId,
            'message' => $message,
        ]);

        $miseAJour = BaseDeDonnees::connexion()->prepare(
            'UPDATE reclamations SET statut = :statut WHERE id = :id'
        );
        $miseAJour->execute(['statut' => $statut, 'id' => $reclamationId]);

        return self::reclamation($reclamationId);
    }

    public static function reclamation(int $id): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(self::baseSql() . ' WHERE r.id = :id LIMIT 1');
        $requete->execute(['id' => $id]);
        $reclamation = $requete->fetch();

        if (!$reclamation) {
            throw new ExceptionHttp('Reclamation introuvable.', 404);
        }

        $reclamation = self::formater($reclamation);
        $reclamation['reponses'] = self::reponses($id);

        return $reclamation;
    }

    private static function reponses(int $reclamationId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT rr.id, rr.message, rr.date_reponse,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
             FROM reponses_reclamations rr
             INNER JOIN utilisateurs u ON u.id = rr.utilisateur_id
             WHERE rr.reclamation_id = :reclamation_id
             ORDER BY rr.date_reponse ASC'
        );
        $requete->execute(['reclamation_id' => $reclamationId]);

        return $requete->fetchAll();
    }

    private static function noteEtudiant(int $etudiantId, int $noteId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id, cours_id
             FROM notes
             WHERE id = :id
               AND etudiant_id = :etudiant_id
               AND statut = "publie"
             LIMIT 1'
        );
        $requete->execute(['id' => $noteId, 'etudiant_id' => $etudiantId]);
        $note = $requete->fetch();

        if (!$note) {
            throw new ExceptionHttp('Note publiee introuvable pour cet etudiant.', 404);
        }

        return $note;
    }

    private static function baseSql(): string
    {
        return 'SELECT r.*, c.code AS code_cours, c.nom AS cours,
                       n.valeur AS note_concernee,
                       CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant,
                       e.matricule,
                       p.nom AS promotion
                FROM reclamations r
                INNER JOIN etudiants e ON e.id = r.etudiant_id
                INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                INNER JOIN promotions p ON p.id = e.promotion_id
                LEFT JOIN cours c ON c.id = r.cours_id
                LEFT JOIN notes n ON n.id = r.note_id';
    }

    private static function formater(array $reclamation): array
    {
        $reclamation['id'] = (int) $reclamation['id'];
        $reclamation['etudiant_id'] = (int) $reclamation['etudiant_id'];
        $reclamation['cours_id'] = $reclamation['cours_id'] === null ? null : (int) $reclamation['cours_id'];
        $reclamation['note_id'] = $reclamation['note_id'] === null ? null : (int) $reclamation['note_id'];
        $reclamation['note_concernee'] = $reclamation['note_concernee'] === null ? null : (float) $reclamation['note_concernee'];
        if ($reclamation['statut'] === 'transmise') {
            $reclamation['statut'] = 'transmise_apparitorat';
        }

        return $reclamation;
    }
}
