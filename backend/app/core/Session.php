<?php

declare(strict_types=1);

namespace App\Core;

class Session
{
    private static array $config = [];

    public static function configure(array $config): void
    {
        self::$config = $config;

        if (session_status() === PHP_SESSION_NONE) {
            session_name((string) $config['session_name']);
            session_set_cookie_params([
                'lifetime' => 0,
                'path' => '/',
                'secure' => (bool) $config['session_secure'],
                'httponly' => true,
                'samesite' => (string) $config['session_same_site'],
            ]);
        }
    }

    public static function start(): void
    {
        if (session_status() === PHP_SESSION_NONE) {
            session_start();
        }
    }

    public static function get(string $key, mixed $default = null): mixed
    {
        return $_SESSION[$key] ?? $default;
    }

    public static function put(string $key, mixed $value): void
    {
        $_SESSION[$key] = $value;
    }

    public static function forget(string $key): void
    {
        unset($_SESSION[$key]);
    }

    public static function regenerate(): void
    {
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_regenerate_id(true);
        }
    }

    public static function persistForDays(int $days): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return;
        }

        setcookie(session_name(), session_id(), [
            'expires' => time() + ($days * 86400),
            'path' => '/',
            'secure' => (bool) (self::$config['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$config['session_same_site'] ?? 'Lax'),
        ]);
    }

    public static function destroy(): void
    {
        if (session_status() !== PHP_SESSION_ACTIVE) {
            return;
        }

        $_SESSION = [];

        setcookie(session_name(), '', [
            'expires' => time() - 3600,
            'path' => '/',
            'secure' => (bool) (self::$config['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$config['session_same_site'] ?? 'Lax'),
        ]);

        session_destroy();
    }
}
