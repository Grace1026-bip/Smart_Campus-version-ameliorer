<?php

declare(strict_types=1);

namespace Application\Services;

class SessionService
{
    private static array $configuration = [];

    public static function configurer(array $configuration): void
    {
        self::$configuration = $configuration;

        if (session_status() === PHP_SESSION_NONE) {
            session_name((string) $configuration['nom_session']);
            session_set_cookie_params([
                'lifetime' => 0,
                'path' => '/',
                'secure' => (bool) $configuration['session_secure'],
                'httponly' => true,
                'samesite' => (string) $configuration['session_same_site'],
            ]);
        }
    }

    public static function demarrer(): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    public static function connecterUtilisateur(array $utilisateur): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_regenerate_id(true);
        }

        $_SESSION['id_utilisateur'] = (int) $utilisateur['id'];
        $_SESSION['nom'] = (string) $utilisateur['nom'];
        $_SESSION['email'] = (string) $utilisateur['email'];
        $_SESSION['roles'] = $utilisateur['roles_codes'] ?? [];
        $_SESSION['statut'] = (string) $utilisateur['statut'];
    }

    public static function utilisateurSession(): ?array
    {
        if (empty($_SESSION['id_utilisateur'])) {
            return null;
        }

        return [
            'id_utilisateur' => (int) $_SESSION['id_utilisateur'],
            'nom' => (string) ($_SESSION['nom'] ?? ''),
            'email' => (string) ($_SESSION['email'] ?? ''),
            'roles' => $_SESSION['roles'] ?? [],
            'statut' => (string) ($_SESSION['statut'] ?? ''),
        ];
    }

    public static function idUtilisateur(): ?int
    {
        return empty($_SESSION['id_utilisateur']) ? null : (int) $_SESSION['id_utilisateur'];
    }

    public static function roles(): array
    {
        return array_values($_SESSION['roles'] ?? []);
    }

    public static function aRole(array $rolesAutorises): bool
    {
        return array_intersect(self::roles(), $rolesAutorises) !== [];
    }

    public static function prolongerCookieSession(int $jours): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return;
        }

        setcookie(session_name(), session_id(), [
            'expires' => time() + ($jours * 86400),
            'path' => '/',
            'secure' => (bool) (self::$configuration['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$configuration['session_same_site'] ?? 'Lax'),
        ]);
    }

    public static function detruire(): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return;
        }

        $_SESSION = [];

        setcookie(session_name(), '', [
            'expires' => time() - 3600,
            'path' => '/',
            'secure' => (bool) (self::$configuration['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$configuration['session_same_site'] ?? 'Lax'),
        ]);

        session_destroy();
    }
}
