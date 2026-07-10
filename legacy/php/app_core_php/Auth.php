<?php

declare(strict_types=1);

namespace App\Core;

use App\Models\Role;
use App\Models\User;

class Auth
{
    private const USER_KEY = 'auth_user_id';
    private const SELECTED_ROLE_KEY = 'selected_role';

    private static array $config = [];

    public static function configure(array $config): void
    {
        self::$config = $config;
    }

    public static function attempt(string $email, string $password, ?string $role = null, bool $remember = false): ?array
    {
        $user = User::findByEmail($email);

        if ($user === null || !(bool) $user['active']) {
            return null;
        }

        if (!password_verify($password, $user['password_hash'])) {
            return null;
        }

        $roles = User::rolesForUser((int) $user['id']);
        $roleCodes = array_map(static fn (array $role) => $role['code'], $roles);
        $selectedRole = Role::normalizeCode($role) ?: ($roleCodes[0] ?? null);

        if ($selectedRole !== null && !in_array($selectedRole, $roleCodes, true)) {
            return null;
        }

        Session::regenerate();
        Session::put(self::USER_KEY, (int) $user['id']);
        Session::put(self::SELECTED_ROLE_KEY, $selectedRole);

        if ($remember) {
            $days = (int) (self::$config['remember_days'] ?? 10);
            $token = User::createRememberToken((int) $user['id'], $days);
            self::setRememberCookie($token, time() + ($days * 86400));
            Session::persistForDays($days);
        }

        return [
            'user' => User::publicUser($user, $roles),
            'selected_role' => $selectedRole,
        ];
    }

    public static function user(): ?array
    {
        $userId = Session::get(self::USER_KEY);

        if ($userId !== null) {
            return User::findWithRoles((int) $userId);
        }

        return self::restoreFromRememberCookie();
    }

    public static function id(): ?int
    {
        $userId = Session::get(self::USER_KEY);

        if ($userId !== null) {
            return (int) $userId;
        }

        $user = self::restoreFromRememberCookie();

        return $user['id'] ?? null;
    }

    public static function roleCodes(): array
    {
        $user = self::user();

        return $user['role_codes'] ?? [];
    }

    public static function hasRole(array $allowedRoles): bool
    {
        $allowedRoles = array_map([Role::class, 'normalizeCode'], $allowedRoles);

        return array_intersect(self::roleCodes(), $allowedRoles) !== [];
    }

    public static function logout(): void
    {
        $cookieName = self::rememberCookieName();
        $token = $_COOKIE[$cookieName] ?? null;

        if ($token) {
            User::deleteRememberToken((string) $token);
            self::clearRememberCookie();
        }

        Session::destroy();
    }

    private static function restoreFromRememberCookie(): ?array
    {
        $cookieName = self::rememberCookieName();
        $token = $_COOKIE[$cookieName] ?? null;

        if (!$token) {
            return null;
        }

        $userId = User::userIdFromRememberToken((string) $token);

        if ($userId === null) {
            self::clearRememberCookie();
            return null;
        }

        $user = User::find($userId);

        if ($user === null || !(bool) $user['active']) {
            self::clearRememberCookie();
            return null;
        }

        $roles = User::rolesForUser($userId);
        $roleCodes = array_map(static fn (array $role) => $role['code'], $roles);

        Session::regenerate();
        Session::put(self::USER_KEY, $userId);
        Session::put(self::SELECTED_ROLE_KEY, $roleCodes[0] ?? null);

        return User::publicUser($user, $roles);
    }

    private static function setRememberCookie(string $token, int $expires): void
    {
        setcookie(self::rememberCookieName(), $token, [
            'expires' => $expires,
            'path' => '/',
            'secure' => (bool) (self::$config['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$config['session_same_site'] ?? 'Lax'),
        ]);
    }

    private static function clearRememberCookie(): void
    {
        setcookie(self::rememberCookieName(), '', [
            'expires' => time() - 3600,
            'path' => '/',
            'secure' => (bool) (self::$config['session_secure'] ?? false),
            'httponly' => true,
            'samesite' => (string) (self::$config['session_same_site'] ?? 'Lax'),
        ]);
    }

    private static function rememberCookieName(): string
    {
        return (string) (self::$config['remember_cookie'] ?? 'remember_token');
    }
}
