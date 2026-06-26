<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\SessionUtilisateur;
use Application\Modeles\Utilisateur;
use Application\Noyau\ExceptionHttp;

class AuthentificationService
{
    private static array $configuration = [];

    public static function configurer(array $configuration): void
    {
        self::$configuration = $configuration;
    }

    public static function connexion(string $email, string $motDePasse, bool $souvenir = false): array
    {
        $utilisateur = Utilisateur::trouverParEmail($email);

        if ($utilisateur === null || !password_verify($motDePasse, (string) $utilisateur['mot_de_passe'])) {
            throw new ExceptionHttp('Email ou mot de passe incorrect', 401);
        }

        self::verifierStatut((string) $utilisateur['statut']);

        $utilisateurPublic = Utilisateur::trouverAvecRoles((int) $utilisateur['id']);

        if ($utilisateurPublic === null) {
            throw new ExceptionHttp('Utilisateur introuvable.', 404);
        }

        SessionService::connecterUtilisateur($utilisateurPublic);

        if ($souvenir) {
            $jours = (int) (self::$configuration['jours_souvenir'] ?? 15);
            $token = SessionUtilisateur::creerToken((int) $utilisateur['id'], $jours);
            self::definirCookieSouvenir($token, time() + ($jours * 86400));
            SessionService::prolongerCookieSession($jours);
        }

        return [
            'utilisateur' => $utilisateurPublic,
            'roles' => $utilisateurPublic['roles_codes'],
        ];
    }

    public static function utilisateurConnecte(): ?array
    {
        $idUtilisateur = SessionService::idUtilisateur();

        if ($idUtilisateur !== null) {
            return Utilisateur::trouverAvecRoles($idUtilisateur);
        }

        return self::restaurerDepuisCookie();
    }

    public static function idUtilisateur(): ?int
    {
        $utilisateur = self::utilisateurConnecte();

        return $utilisateur === null ? null : (int) $utilisateur['id'];
    }

    public static function roles(): array
    {
        $utilisateur = self::utilisateurConnecte();

        return $utilisateur['roles_codes'] ?? [];
    }

    public static function deconnexion(): void
    {
        $nomCookie = self::nomCookieSouvenir();
        $token = $_COOKIE[$nomCookie] ?? null;

        if ($token) {
            SessionUtilisateur::invaliderToken((string) $token);
            self::effacerCookieSouvenir();
        }

        SessionService::detruire();
    }

    private static function restaurerDepuisCookie(): ?array
    {
        $token = $_COOKIE[self::nomCookieSouvenir()] ?? null;

        if (!$token) {
            return null;
        }

        $utilisateurId = SessionUtilisateur::utilisateurIdDepuisToken((string) $token);

        if ($utilisateurId === null) {
            self::effacerCookieSouvenir();
            return null;
        }

        $utilisateur = Utilisateur::trouverAvecRoles($utilisateurId);

        if ($utilisateur === null || $utilisateur['statut'] !== 'approuve') {
            self::effacerCookieSouvenir();
            return null;
        }

        SessionService::connecterUtilisateur($utilisateur);

        return $utilisateur;
    }

    private static function verifierStatut(string $statut): void
    {
        match ($statut) {
            'en_attente' => throw new ExceptionHttp(
                "Votre demande d'inscription est encore en attente d'approbation.",
                403
            ),
            'rejete' => throw new ExceptionHttp("Votre demande d'inscription a ete rejetee.", 403),
            'bloque' => throw new ExceptionHttp("Votre compte est bloque. Veuillez contacter l'administration.", 403),
            'approuve' => null,
            default => throw new ExceptionHttp('Statut de compte invalide.', 403),
        };
    }

    private static function definirCookieSouvenir(string $token, int $expiration): void
    {
        setcookie(self::nomCookieSouvenir(), $token, [
            'expires' => $expiration,
            'path' => '/',
            'secure' => (bool) (self::$configuration['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$configuration['session_same_site'] ?? 'Lax'),
        ]);
    }

    private static function effacerCookieSouvenir(): void
    {
        setcookie(self::nomCookieSouvenir(), '', [
            'expires' => time() - 3600,
            'path' => '/',
            'secure' => (bool) (self::$configuration['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$configuration['session_same_site'] ?? 'Lax'),
        ]);
    }

    private static function nomCookieSouvenir(): string
    {
        return (string) (self::$configuration['cookie_souvenir'] ?? 'souvenir_smart_faculty');
    }
}
