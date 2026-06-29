<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\Note;
use Application\Modeles\Cours;
use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;
use PDO;

class NoteService
{
    public static function notesEtudiant(int $etudiantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT n.id, n.etudiant_id, n.cours_id, n.valeur, n.statut, n.verrouille, n.date_publication,
                    tn.code AS type_code, tn.libelle AS type_note,
                    c.code AS code_cours, c.nom AS cours, c.credits,
                    p.nom AS promotion,
                    CONCAT_WS(" ", ue.nom, ue.postnom, ue.prenom) AS enseignant,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant,
                    e.matricule
             FROM notes n
             INNER JOIN types_notes tn ON tn.id = n.type_note_id
             INNER JOIN cours c ON c.id = n.cours_id
             INNER JOIN promotions p ON p.id = c.promotion_id
             INNER JOIN cours_enseignants ce ON ce.cours_id = c.id AND ce.role_enseignement = "principal"
             INNER JOIN enseignants ens ON ens.id = ce.enseignant_id
             INNER JOIN utilisateurs ue ON ue.id = ens.utilisateur_id
             INNER JOIN etudiants e ON e.id = n.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             WHERE n.etudiant_id = :etudiant_id
               AND n.statut = "publie"
             ORDER BY c.nom ASC, tn.id ASC'
        );
        $requete->execute(['etudiant_id' => $etudiantId]);

        return array_map([self::class, 'formaterNote'], $requete->fetchAll());
    }

    public static function notesEtudiantCours(int $etudiantId, int $coursId): array
    {
        $notes = array_filter(
            self::notesEtudiant($etudiantId),
            static fn (array $note): bool => (int) $note['cours_id'] === $coursId
        );

        return array_values($notes);
    }

    public static function notesCours(int $coursId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT n.id, n.etudiant_id, n.cours_id, n.valeur, n.statut, n.verrouille, n.date_publication,
                    tn.code AS type_code, tn.libelle AS type_note,
                    c.code AS code_cours, c.nom AS cours, c.credits,
                    p.nom AS promotion,
                    CONCAT_WS(" ", ue.nom, ue.postnom, ue.prenom) AS enseignant,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant,
                    e.matricule
             FROM notes n
             INNER JOIN types_notes tn ON tn.id = n.type_note_id
             INNER JOIN cours c ON c.id = n.cours_id
             INNER JOIN promotions p ON p.id = c.promotion_id
             INNER JOIN enseignants ens ON ens.id = n.enseignant_id
             INNER JOIN utilisateurs ue ON ue.id = ens.utilisateur_id
             INNER JOIN etudiants e ON e.id = n.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             WHERE n.cours_id = :cours_id
             ORDER BY u.nom ASC, tn.id ASC'
        );
        $requete->execute(['cours_id' => $coursId]);

        return array_map([self::class, 'formaterNote'], $requete->fetchAll());
    }

    public static function notesCoursEnseignant(int $enseignantId, int $coursId): array
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        return self::notesCours($coursId);
    }

    public static function statistiquesCours(int $coursId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(DISTINCT ic.etudiant_id) AS total_etudiants,
                    COUNT(CASE WHEN n.statut = "publie" THEN 1 END) AS notes_publiees,
                    AVG(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" THEN n.valeur END) AS moyenne_cours,
                    SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "brouillon" THEN 1 ELSE 0 END) AS notes_brouillon,
                    SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" THEN 1 ELSE 0 END) AS moyennes_publiees,
                    SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur >= 10 THEN 1 ELSE 0 END) AS reussites,
                    SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur < 10 THEN 1 ELSE 0 END) AS echecs,
                    SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur < 12 THEN 1 ELSE 0 END) AS etudiants_a_risque
             FROM inscriptions_cours ic
             LEFT JOIN notes n ON n.cours_id = ic.cours_id AND n.etudiant_id = ic.etudiant_id
             LEFT JOIN types_notes tn ON tn.id = n.type_note_id
             WHERE ic.cours_id = :cours_id'
        );
        $requete->execute(['cours_id' => $coursId]);
        $stats = $requete->fetch() ?: [];
        $moyennesPubliees = (int) ($stats['moyennes_publiees'] ?? 0);
        $reussites = (int) ($stats['reussites'] ?? 0);
        $echecs = (int) ($stats['echecs'] ?? 0);

        return [
            'total_etudiants' => (int) ($stats['total_etudiants'] ?? 0),
            'notes_publiees' => (int) ($stats['notes_publiees'] ?? 0),
            'notes_brouillon' => (int) ($stats['notes_brouillon'] ?? 0),
            'moyennes_publiees' => $moyennesPubliees,
            'moyenne_cours' => $stats['moyenne_cours'] === null ? null : round((float) $stats['moyenne_cours'], 2),
            'reussites' => $reussites,
            'echecs' => $echecs,
            'taux_reussite' => $moyennesPubliees > 0 ? round(($reussites / $moyennesPubliees) * 100, 2) : 0,
            'taux_echec' => $moyennesPubliees > 0 ? round(($echecs / $moyennesPubliees) * 100, 2) : 0,
            'etudiants_a_risque' => (int) ($stats['etudiants_a_risque'] ?? 0),
        ];
    }

    public static function resumeEtudiant(int $etudiantId): array
    {
        $notes = array_filter(
            self::notesEtudiant($etudiantId),
            static fn (array $note): bool => $note['type_code'] === 'moyenne_finale'
        );

        $totalCredits = 0;
        $creditsValides = 0;
        $scorePondere = 0.0;
        $coursEchoues = 0;

        foreach ($notes as $note) {
            $credits = (int) $note['credits'];
            $valeur = (float) $note['valeur'];
            $totalCredits += $credits;
            $scorePondere += $valeur * $credits;

            if ($valeur >= 10.0) {
                $creditsValides += $credits;
            } else {
                $coursEchoues++;
            }
        }

        return [
            'moyenne_generale' => $totalCredits > 0 ? round($scorePondere / $totalCredits, 2) : null,
            'credits_valides' => $creditsValides,
            'credits_restants' => max(0, $totalCredits - $creditsValides),
            'notes_publiees' => count($notes),
            'cours_echoues' => $coursEchoues,
        ];
    }

    public static function enregistrerBrouillon(int $enseignantId, int $coursId, array $donnees): array
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);
        $notes = $donnees['notes'] ?? [];

        if (!is_array($notes) || $notes === []) {
            throw new ExceptionHttp('Aucune note a enregistrer.', 422);
        }

        return BaseDeDonnees::transaction(function (PDO $pdo) use ($enseignantId, $coursId, $notes): array {
            foreach ($notes as $note) {
                $etudiantId = self::resoudreEtudiantId($note);

                if (!Cours::coursAppartientEtudiant($etudiantId, $coursId)) {
                    throw new ExceptionHttp('Cet etudiant n est pas inscrit a ce cours.', 403);
                }

                if (self::estLigneComposite($note)) {
                    foreach (['interrogation', 'travail_pratique', 'examen'] as $type) {
                        if (!array_key_exists($type, $note) || $note[$type] === null || $note[$type] === '') {
                            continue;
                        }

                        self::sauvegarderNote($pdo, $enseignantId, $coursId, $etudiantId, $type, (float) $note[$type], 'brouillon', false);
                    }

                    self::recalculerMoyenneEtudiantCours($pdo, $enseignantId, $coursId, $etudiantId, 'brouillon', false);
                    continue;
                }

                $type = (string) ($note['type'] ?? $note['type_note'] ?? 'moyenne_finale');
                $valeur = (float) ($note['valeur'] ?? $note['note'] ?? -1);
                self::sauvegarderNote($pdo, $enseignantId, $coursId, $etudiantId, $type, $valeur, 'brouillon', false);
            }

            self::mettreAJourStatutCours($coursId, 'brouillon');

            return [
                'notes' => self::notesCours($coursId),
                'statistiques' => self::statistiquesCours($coursId),
            ];
        });
    }

    public static function publierNotes(int $enseignantId, int $coursId): array
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        return BaseDeDonnees::transaction(function (PDO $pdo) use ($enseignantId, $coursId): array {
            self::recalculerMoyennesCours($pdo, $enseignantId, $coursId, 'brouillon', false);

            $brouillons = $pdo->prepare(
                'SELECT COUNT(*) FROM notes WHERE cours_id = :cours_id AND statut = "brouillon" AND verrouille = 0'
            );
            $brouillons->execute(['cours_id' => $coursId]);

            if ((int) $brouillons->fetchColumn() === 0) {
                throw new ExceptionHttp('Aucune note en brouillon a publier.', 422);
            }

            $requete = $pdo->prepare(
                'UPDATE notes
                 SET statut = "publie", verrouille = 1, date_publication = NOW()
                 WHERE cours_id = :cours_id AND statut = "brouillon" AND verrouille = 0'
            );
            $requete->execute(['cours_id' => $coursId]);

            self::mettreAJourStatutCours($coursId, 'publiees');
            self::synchroniserAlertesCours($pdo, $coursId);
            ValveService::creerPublicationAutomatiqueNotes($enseignantId, $coursId);

            return [
                'notes' => self::notesCours($coursId),
                'statistiques' => self::statistiquesCours($coursId),
            ];
        });
    }

    private static function mettreAJourStatutCours(int $coursId, string $statut): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE cours SET statut_notes = :statut WHERE id = :cours_id'
        );
        $requete->execute(['statut' => $statut, 'cours_id' => $coursId]);
    }

    private static function estLigneComposite(array $note): bool
    {
        return array_key_exists('interrogation', $note)
            || array_key_exists('travail_pratique', $note)
            || array_key_exists('examen', $note);
    }

    private static function sauvegarderNote(
        PDO $pdo,
        int $enseignantId,
        int $coursId,
        int $etudiantId,
        string $type,
        float $valeur,
        string $statut,
        bool $verrouille
    ): void {
        if ($valeur < 0 || $valeur > 20) {
            throw new ExceptionHttp('Une note doit etre comprise entre 0 et 20.', 422);
        }

        $typeNoteId = self::resoudreTypeNoteId($type);
        self::verifierNoteModifiable($pdo, $etudiantId, $coursId, $typeNoteId);

        $requete = $pdo->prepare(
            'INSERT INTO notes (etudiant_id, cours_id, type_note_id, enseignant_id, valeur, statut, verrouille)
             VALUES (:etudiant_id, :cours_id, :type_note_id, :enseignant_id, :valeur, :statut, :verrouille)
             ON DUPLICATE KEY UPDATE
                valeur = VALUES(valeur),
                statut = VALUES(statut),
                verrouille = VALUES(verrouille),
                enseignant_id = VALUES(enseignant_id),
                date_publication = NULL'
        );
        $requete->execute([
            'etudiant_id' => $etudiantId,
            'cours_id' => $coursId,
            'type_note_id' => $typeNoteId,
            'enseignant_id' => $enseignantId,
            'valeur' => $valeur,
            'statut' => $statut,
            'verrouille' => $verrouille ? 1 : 0,
        ]);
    }

    private static function verifierNoteModifiable(PDO $pdo, int $etudiantId, int $coursId, int $typeNoteId): void
    {
        $requete = $pdo->prepare(
            'SELECT statut, verrouille
             FROM notes
             WHERE etudiant_id = :etudiant_id
               AND cours_id = :cours_id
               AND type_note_id = :type_note_id
             LIMIT 1'
        );
        $requete->execute([
            'etudiant_id' => $etudiantId,
            'cours_id' => $coursId,
            'type_note_id' => $typeNoteId,
        ]);
        $note = $requete->fetch();

        if ($note && ((bool) $note['verrouille'] || $note['statut'] === 'publie')) {
            throw new ExceptionHttp('Les notes publiees ou verrouillees ne peuvent plus etre modifiees.', 409);
        }
    }

    private static function recalculerMoyennesCours(PDO $pdo, int $enseignantId, int $coursId, string $statut, bool $verrouille): void
    {
        $requete = $pdo->prepare('SELECT etudiant_id FROM inscriptions_cours WHERE cours_id = :cours_id');
        $requete->execute(['cours_id' => $coursId]);

        foreach ($requete->fetchAll() as $ligne) {
            self::recalculerMoyenneEtudiantCours($pdo, $enseignantId, $coursId, (int) $ligne['etudiant_id'], $statut, $verrouille);
        }
    }

    private static function recalculerMoyenneEtudiantCours(PDO $pdo, int $enseignantId, int $coursId, int $etudiantId, string $statut, bool $verrouille): void
    {
        $requete = $pdo->prepare(
            'SELECT tn.code, tn.poids, n.valeur
             FROM notes n
             INNER JOIN types_notes tn ON tn.id = n.type_note_id
             WHERE n.etudiant_id = :etudiant_id
               AND n.cours_id = :cours_id
               AND tn.code IN ("interrogation", "travail_pratique", "examen")'
        );
        $requete->execute(['etudiant_id' => $etudiantId, 'cours_id' => $coursId]);
        $notes = $requete->fetchAll();

        if (count($notes) < 3) {
            return;
        }

        $moyenne = 0.0;
        foreach ($notes as $note) {
            $moyenne += ((float) $note['valeur']) * ((float) $note['poids']);
        }

        self::sauvegarderNote($pdo, $enseignantId, $coursId, $etudiantId, 'moyenne_finale', round($moyenne, 2), $statut, $verrouille);
    }

    private static function synchroniserAlertesCours(PDO $pdo, int $coursId): void
    {
        $typeMoyenne = self::resoudreTypeNoteId('moyenne_finale');
        $requete = $pdo->prepare(
            'SELECT n.etudiant_id, n.valeur, c.nom AS cours
             FROM notes n
             INNER JOIN cours c ON c.id = n.cours_id
             WHERE n.cours_id = :cours_id
               AND n.type_note_id = :type_note_id
               AND n.statut = "publie"'
        );
        $requete->execute(['cours_id' => $coursId, 'type_note_id' => $typeMoyenne]);

        $suppression = $pdo->prepare(
            'DELETE FROM alertes_academiques
             WHERE etudiant_id = :etudiant_id
               AND cours_id = :cours_id
               AND titre IN ("Moyenne faible", "Vigilance academique")'
        );
        $insertion = $pdo->prepare(
            'INSERT INTO alertes_academiques (etudiant_id, cours_id, titre, message, niveau)
             VALUES (:etudiant_id, :cours_id, :titre, :message, :niveau)'
        );

        foreach ($requete->fetchAll() as $note) {
            $etudiantId = (int) $note['etudiant_id'];
            $moyenne = (float) $note['valeur'];
            $suppression->execute(['etudiant_id' => $etudiantId, 'cours_id' => $coursId]);

            if ($moyenne >= 12) {
                continue;
            }

            $titre = $moyenne < 10 ? 'Moyenne faible' : 'Vigilance academique';
            $niveau = $moyenne < 10 ? 'danger' : 'attention';
            $message = $moyenne < 10
                ? 'Attention : votre moyenne en ' . $note['cours'] . ' est inferieure au seuil de reussite.'
                : 'Votre moyenne en ' . $note['cours'] . ' est proche du seuil. Un suivi est conseille.';

            $insertion->execute([
                'etudiant_id' => $etudiantId,
                'cours_id' => $coursId,
                'titre' => $titre,
                'message' => $message,
                'niveau' => $niveau,
            ]);
        }
    }

    private static function resoudreEtudiantId(array $note): int
    {
        if (!empty($note['etudiant_id'])) {
            return (int) $note['etudiant_id'];
        }

        if (empty($note['matricule'])) {
            throw new ExceptionHttp('Etudiant ou matricule obligatoire.', 422);
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id FROM etudiants WHERE matricule = :matricule LIMIT 1'
        );
        $requete->execute(['matricule' => $note['matricule']]);
        $id = $requete->fetchColumn();

        if ($id === false) {
            throw new ExceptionHttp('Etudiant introuvable.', 404);
        }

        return (int) $id;
    }

    private static function resoudreTypeNoteId(string $code): int
    {
        $code = match ($code) {
            'tp', 'travail', 'travaux_pratiques' => 'travail_pratique',
            'interro' => 'interrogation',
            'moyenne', 'finale' => 'moyenne_finale',
            default => $code,
        };

        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id FROM types_notes WHERE code = :code LIMIT 1'
        );
        $requete->execute(['code' => $code]);
        $id = $requete->fetchColumn();

        if ($id === false) {
            throw new ExceptionHttp('Type de note invalide.', 422);
        }

        return (int) $id;
    }

    private static function formaterNote(array $note): array
    {
        $note['id'] = (int) $note['id'];
        $note['etudiant_id'] = (int) $note['etudiant_id'];
        $note['cours_id'] = (int) $note['cours_id'];
        $note['credits'] = (int) $note['credits'];
        $note['valeur'] = (float) $note['valeur'];
        $note['verrouille'] = (bool) $note['verrouille'];
        $note['resultat'] = Note::statutDepuisMoyenne($note['type_code'] === 'moyenne_finale' ? (float) $note['valeur'] : null);
        $note['published'] = $note['statut'] === 'publie';

        return $note;
    }
}
