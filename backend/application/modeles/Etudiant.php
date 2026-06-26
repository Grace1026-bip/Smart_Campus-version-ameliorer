<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class Etudiant
{
    public static function creerProfil(int $utilisateurId, array $donnees): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO etudiants (utilisateur_id, matricule, promotion_id)
             VALUES (:utilisateur_id, :matricule, :promotion_id)'
        );
        $requete->execute([
            'utilisateur_id' => $utilisateurId,
            'matricule' => nettoyer_chaine($donnees['matricule'] ?? ''),
            'promotion_id' => self::promotionId($donnees),
        ]);
    }

    public static function profil(int $utilisateurId): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.matricule, e.promotion_id, p.nom AS promotion, p.niveau
             FROM etudiants e
             LEFT JOIN promotions p ON p.id = e.promotion_id
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
                'notes_disponibles' => 0,
                'reclamations_ouvertes' => 0,
                'projets_actifs' => 0,
            ],
        ];
    }

    private static function entierOuNull(mixed $valeur): ?int
    {
        return $valeur === null || $valeur === '' ? null : (int) $valeur;
    }

    private static function promotionId(array $donnees): ?int
    {
        $promotionId = self::entierOuNull($donnees['promotion_id'] ?? null);

        if ($promotionId !== null) {
            return $promotionId;
        }

        $nom = nettoyer_chaine($donnees['promotion'] ?? '');

        if ($nom === '') {
            return null;
        }

        $pdo = BaseDeDonnees::connexion();
        $requete = $pdo->prepare('SELECT id FROM promotions WHERE nom = :nom LIMIT 1');
        $requete->execute(['nom' => $nom]);
        $id = $requete->fetchColumn();

        if ($id !== false) {
            return (int) $id;
        }

        $insertion = $pdo->prepare('INSERT INTO promotions (nom, niveau) VALUES (:nom, :niveau)');
        $insertion->execute([
            'nom' => $nom,
            'niveau' => nettoyer_chaine($donnees['niveau'] ?? ''),
        ]);

        return (int) $pdo->lastInsertId();
    }
}
