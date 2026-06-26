<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;
use DateTimeImmutable;

class SessionUtilisateur
{
    public static function creerToken(int $utilisateurId, int $jours): string
    {
        $token = bin2hex(random_bytes(32));
        $expiration = (new DateTimeImmutable('+' . $jours . ' days'))->format('Y-m-d H:i:s');

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO sessions_utilisateurs (utilisateur_id, token, date_expiration, actif)
             VALUES (:utilisateur_id, :token, :date_expiration, 1)'
        );
        $requete->execute([
            'utilisateur_id' => $utilisateurId,
            'token' => self::hacherToken($token),
            'date_expiration' => $expiration,
        ]);

        return $token;
    }

    public static function utilisateurIdDepuisToken(string $token): ?int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id, utilisateur_id
             FROM sessions_utilisateurs
             WHERE token = :token
               AND actif = 1
               AND date_expiration > NOW()
             LIMIT 1'
        );
        $requete->execute(['token' => self::hacherToken($token)]);
        $session = $requete->fetch();

        if (!$session) {
            return null;
        }

        $miseAJour = BaseDeDonnees::connexion()->prepare(
            'UPDATE sessions_utilisateurs SET date_derniere_utilisation = NOW() WHERE id = :id'
        );
        $miseAJour->execute(['id' => $session['id']]);

        return (int) $session['utilisateur_id'];
    }

    public static function invaliderToken(string $token): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE sessions_utilisateurs
             SET actif = 0
             WHERE token = :token'
        );
        $requete->execute(['token' => self::hacherToken($token)]);
    }

    private static function hacherToken(string $token): string
    {
        return hash('sha256', $token);
    }
}
