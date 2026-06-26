<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class Enseignant
{
    public static function creerProfil(int $utilisateurId, array $donnees): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO enseignants (utilisateur_id, departement_id, cours)
             VALUES (:utilisateur_id, :departement_id, :cours)'
        );
        $requete->execute([
            'utilisateur_id' => $utilisateurId,
            'departement_id' => self::departementId($donnees),
            'cours' => nettoyer_chaine($donnees['cours'] ?? ''),
        ]);
    }

    public static function profil(int $utilisateurId): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.departement_id, e.cours, d.nom AS departement
             FROM enseignants e
             LEFT JOIN departements d ON d.id = e.departement_id
             WHERE e.utilisateur_id = :utilisateur_id
             LIMIT 1'
        );
        $requete->execute(['utilisateur_id' => $utilisateurId]);
        $profil = $requete->fetch();

        return $profil ?: null;
    }

    public static function tableauDeBord(int $utilisateurId): array
    {
        return [
            'profil' => self::profil($utilisateurId),
            'resume' => [
                'cours_assignes' => 0,
                'etudiants_suivis' => 0,
                'reclamations_a_traiter' => 0,
            ],
        ];
    }

    private static function entierOuNull(mixed $valeur): ?int
    {
        return $valeur === null || $valeur === '' ? null : (int) $valeur;
    }

    private static function departementId(array $donnees): ?int
    {
        $departementId = self::entierOuNull($donnees['departement_id'] ?? null);

        if ($departementId !== null) {
            return $departementId;
        }

        $nom = nettoyer_chaine($donnees['departement'] ?? '');

        if ($nom === '') {
            return null;
        }

        $pdo = BaseDeDonnees::connexion();
        $requete = $pdo->prepare('SELECT id FROM departements WHERE nom = :nom LIMIT 1');
        $requete->execute(['nom' => $nom]);
        $id = $requete->fetchColumn();

        if ($id !== false) {
            return (int) $id;
        }

        $insertion = $pdo->prepare('INSERT INTO departements (nom) VALUES (:nom)');
        $insertion->execute(['nom' => $nom]);

        return (int) $pdo->lastInsertId();
    }
}
