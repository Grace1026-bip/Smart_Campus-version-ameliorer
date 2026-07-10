<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class Cours
{
    public static function etudiantIdDepuisUtilisateur(int $utilisateurId): ?int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id FROM etudiants WHERE utilisateur_id = :utilisateur_id LIMIT 1'
        );
        $requete->execute(['utilisateur_id' => $utilisateurId]);
        $id = $requete->fetchColumn();

        return $id === false ? null : (int) $id;
    }

    public static function enseignantIdDepuisUtilisateur(int $utilisateurId): ?int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id FROM enseignants WHERE utilisateur_id = :utilisateur_id LIMIT 1'
        );
        $requete->execute(['utilisateur_id' => $utilisateurId]);
        $id = $requete->fetchColumn();

        return $id === false ? null : (int) $id;
    }

    public static function coursAppartientEtudiant(int $etudiantId, int $coursId): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*) FROM inscriptions_cours WHERE etudiant_id = :etudiant_id AND cours_id = :cours_id'
        );
        $requete->execute(['etudiant_id' => $etudiantId, 'cours_id' => $coursId]);

        return (int) $requete->fetchColumn() > 0;
    }

    public static function coursAppartientEnseignant(int $enseignantId, int $coursId): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*) FROM cours_enseignants WHERE enseignant_id = :enseignant_id AND cours_id = :cours_id'
        );
        $requete->execute(['enseignant_id' => $enseignantId, 'cours_id' => $coursId]);

        return (int) $requete->fetchColumn() > 0;
    }
}
