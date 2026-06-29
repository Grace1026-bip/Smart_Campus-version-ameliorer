<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\PublicationValve;
use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;

class ValveService
{
    private const STATUTS = ['brouillon', 'publie', 'verrouille'];
    private const VISIBILITES = ['etudiants', 'enseignants', 'tous'];

    public static function valveEtudiant(int $etudiantId): array
    {
        $cours = CoursService::coursEtudiant($etudiantId);

        foreach ($cours as &$item) {
            $item['publications_recentes'] = self::publicationsCours((int) $item['id'], true, 3);
            $item['nouveau'] = self::aPublicationRecente((int) $item['id']);
        }

        return $cours;
    }

    public static function valveCoursEtudiant(int $etudiantId, int $coursId): array
    {
        CoursService::verifierCoursEtudiant($etudiantId, $coursId);

        return [
            'cours' => CoursService::detailCoursEtudiant($etudiantId, $coursId),
            'publications' => self::publicationsCours($coursId, true),
        ];
    }

    public static function valveEnseignant(int $enseignantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT pv.*, c.code AS code_cours, c.nom AS cours, p.nom AS promotion,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
             FROM publications_valve pv
             INNER JOIN cours c ON c.id = pv.cours_id
             INNER JOIN promotions p ON p.id = c.promotion_id
             INNER JOIN enseignants e ON e.id = pv.enseignant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             INNER JOIN cours_enseignants ce ON ce.cours_id = c.id
             WHERE ce.enseignant_id = :enseignant_id
             ORDER BY pv.date_publication DESC'
        );
        $requete->execute(['enseignant_id' => $enseignantId]);

        return array_map([self::class, 'formaterPublication'], $requete->fetchAll());
    }

    public static function publicationsCours(int $coursId, bool $lectureEtudiant = false, ?int $limite = null): array
    {
        $sql = 'SELECT pv.*, c.code AS code_cours, c.nom AS cours,
                       CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
                FROM publications_valve pv
                INNER JOIN cours c ON c.id = pv.cours_id
                INNER JOIN enseignants e ON e.id = pv.enseignant_id
                INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                WHERE pv.cours_id = :cours_id';

        if ($lectureEtudiant) {
            $sql .= ' AND pv.statut IN ("publie", "verrouille") AND pv.visibilite IN ("etudiants", "tous")';
        }

        $sql .= ' ORDER BY pv.date_publication DESC';

        if ($limite !== null) {
            $sql .= ' LIMIT ' . (int) $limite;
        }

        $requete = BaseDeDonnees::connexion()->prepare($sql);
        $requete->execute(['cours_id' => $coursId]);

        return array_map([self::class, 'formaterPublication'], $requete->fetchAll());
    }

    public static function creerPublication(int $enseignantId, array $donnees): array
    {
        $coursId = (int) ($donnees['cours_id'] ?? 0);
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        $type = (string) ($donnees['type_publication'] ?? $donnees['type'] ?? 'annonce');
        if (!in_array($type, PublicationValve::TYPES, true)) {
            throw new ExceptionHttp('Type de publication invalide.', 422);
        }

        $statut = (string) ($donnees['statut'] ?? 'publie');
        $visibilite = (string) ($donnees['visibilite'] ?? 'etudiants');
        self::validerStatutEtVisibilite($statut, $visibilite);

        $titre = nettoyer_chaine($donnees['titre'] ?? '');
        $contenu = nettoyer_chaine($donnees['contenu'] ?? '');

        if ($titre === '' || $contenu === '') {
            throw new ExceptionHttp('Titre et contenu obligatoires.', 422);
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO publications_valve (
                cours_id, enseignant_id, type_publication, titre, contenu, piece_jointe_url, statut, visibilite, est_important
             ) VALUES (
                :cours_id, :enseignant_id, :type_publication, :titre, :contenu, :piece_jointe_url, :statut, :visibilite, :est_important
             )'
        );
        $requete->execute([
            'cours_id' => $coursId,
            'enseignant_id' => $enseignantId,
            'type_publication' => $type,
            'titre' => $titre,
            'contenu' => $contenu,
            'piece_jointe_url' => nettoyer_chaine($donnees['piece_jointe_url'] ?? '') ?: null,
            'statut' => $statut,
            'visibilite' => $visibilite,
            'est_important' => normaliser_booleen($donnees['est_important'] ?? $donnees['important'] ?? false) ? 1 : 0,
        ]);

        return self::publication((int) BaseDeDonnees::connexion()->lastInsertId());
    }

    public static function modifierPublication(int $enseignantId, int $publicationId, array $donnees): array
    {
        $publication = self::publication($publicationId);
        CoursService::verifierCoursEnseignant($enseignantId, (int) $publication['cours_id']);

        if ((bool) $publication['verrouille'] || $publication['statut'] === 'verrouille') {
            throw new ExceptionHttp('Cette publication est verrouillee.', 409);
        }

        $typePublication = $donnees['type_publication'] ?? $donnees['type'] ?? null;
        if ($typePublication !== null && !in_array((string) $typePublication, PublicationValve::TYPES, true)) {
            throw new ExceptionHttp('Type de publication invalide.', 422);
        }

        $statut = $donnees['statut'] ?? null;
        $visibilite = $donnees['visibilite'] ?? null;
        self::validerStatutEtVisibilite($statut, $visibilite);

        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE publications_valve
             SET titre = COALESCE(:titre, titre),
                 contenu = COALESCE(:contenu, contenu),
                 type_publication = COALESCE(:type_publication, type_publication),
                 statut = COALESCE(:statut, statut),
                 visibilite = COALESCE(:visibilite, visibilite),
                 est_important = COALESCE(:est_important, est_important),
                 piece_jointe_url = COALESCE(:piece_jointe_url, piece_jointe_url)
             WHERE id = :id'
        );
        $requete->execute([
            'id' => $publicationId,
            'titre' => isset($donnees['titre']) ? nettoyer_chaine($donnees['titre']) : null,
            'contenu' => isset($donnees['contenu']) ? nettoyer_chaine($donnees['contenu']) : null,
            'type_publication' => $typePublication === null ? null : (string) $typePublication,
            'statut' => $statut,
            'visibilite' => $visibilite,
            'est_important' => array_key_exists('est_important', $donnees)
                ? (normaliser_booleen($donnees['est_important']) ? 1 : 0)
                : null,
            'piece_jointe_url' => isset($donnees['piece_jointe_url']) ? nettoyer_chaine($donnees['piece_jointe_url']) : null,
        ]);

        return self::publication($publicationId);
    }

    public static function supprimerPublication(int $enseignantId, int $publicationId): void
    {
        $publication = self::publication($publicationId);
        CoursService::verifierCoursEnseignant($enseignantId, (int) $publication['cours_id']);

        if ((bool) $publication['verrouille'] || $publication['statut'] === 'verrouille') {
            throw new ExceptionHttp('Cette publication est verrouillee.', 409);
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'DELETE FROM publications_valve WHERE id = :id'
        );
        $requete->execute(['id' => $publicationId]);
    }

    public static function creerPublicationAutomatiqueNotes(int $enseignantId, int $coursId): void
    {
        CoursService::verifierCoursEnseignant($enseignantId, $coursId);

        $requeteCours = BaseDeDonnees::connexion()->prepare(
            'SELECT nom, code FROM cours WHERE id = :cours_id LIMIT 1'
        );
        $requeteCours->execute(['cours_id' => $coursId]);
        $cours = $requeteCours->fetch();

        if (!$cours) {
            return;
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO publications_valve (
                cours_id, enseignant_id, type_publication, titre, contenu, statut, visibilite, est_important, verrouille
             ) VALUES (
                :cours_id, :enseignant_id, "publication_notes", :titre, :contenu, "verrouille", "etudiants", 1, 1
             )
             ON DUPLICATE KEY UPDATE contenu = VALUES(contenu), statut = "verrouille", est_important = 1, verrouille = 1'
        );
        $requete->execute([
            'cours_id' => $coursId,
            'enseignant_id' => $enseignantId,
            'titre' => 'Notes publiees - ' . $cours['code'],
            'contenu' => 'Les notes du cours ' . $cours['nom'] . ' ont ete publiees.',
        ]);
    }

    public static function publication(int $id): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT pv.*, c.code AS code_cours, c.nom AS cours,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
             FROM publications_valve pv
             INNER JOIN cours c ON c.id = pv.cours_id
             INNER JOIN enseignants e ON e.id = pv.enseignant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             WHERE pv.id = :id
             LIMIT 1'
        );
        $requete->execute(['id' => $id]);
        $publication = $requete->fetch();

        if (!$publication) {
            throw new ExceptionHttp('Publication introuvable.', 404);
        }

        return self::formaterPublication($publication);
    }

    private static function aPublicationRecente(int $coursId): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*)
             FROM publications_valve
             WHERE cours_id = :cours_id
               AND statut IN ("publie", "verrouille")
               AND date_publication >= (NOW() - INTERVAL 7 DAY)'
        );
        $requete->execute(['cours_id' => $coursId]);

        return (int) $requete->fetchColumn() > 0;
    }

    private static function formaterPublication(array $publication): array
    {
        $publication['id'] = (int) $publication['id'];
        $publication['cours_id'] = (int) $publication['cours_id'];
        $publication['enseignant_id'] = (int) $publication['enseignant_id'];
        $publication['est_important'] = (bool) ($publication['est_important'] ?? false);
        $publication['verrouille'] = (bool) $publication['verrouille'];
        $publication['est_verrouille'] = $publication['verrouille'];
        $publication['type'] = $publication['type_publication'];
        $publication['fichier'] = $publication['piece_jointe_url'];

        return $publication;
    }

    private static function validerStatutEtVisibilite(mixed $statut, mixed $visibilite): void
    {
        if ($statut !== null && !in_array((string) $statut, self::STATUTS, true)) {
            throw new ExceptionHttp('Statut de publication invalide.', 422);
        }

        if ($visibilite !== null && !in_array((string) $visibilite, self::VISIBILITES, true)) {
            throw new ExceptionHttp('Visibilite de publication invalide.', 422);
        }
    }
}
