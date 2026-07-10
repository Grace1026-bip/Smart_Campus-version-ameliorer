<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;
use DateTimeImmutable;
use PDO;

class User
{
    public static function find(int $id): ?array
    {
        $statement = Database::connection()->prepare(
            'SELECT id, nom, postnom, prenom, email, telephone, password_hash, active, created_at, updated_at
             FROM utilisateurs
             WHERE id = :id
             LIMIT 1'
        );
        $statement->execute(['id' => $id]);
        $user = $statement->fetch();

        return $user ?: null;
    }

    public static function findByEmail(string $email): ?array
    {
        $statement = Database::connection()->prepare(
            'SELECT id, nom, postnom, prenom, email, telephone, password_hash, active, created_at, updated_at
             FROM utilisateurs
             WHERE email = :email
             LIMIT 1'
        );
        $statement->execute(['email' => strtolower(trim($email))]);
        $user = $statement->fetch();

        return $user ?: null;
    }

    public static function findWithRoles(int $id): ?array
    {
        $user = self::find($id);

        if ($user === null) {
            return null;
        }

        return self::publicUser($user, self::rolesForUser($id));
    }

    public static function all(): array
    {
        $statement = Database::connection()->query(
            'SELECT id, nom, postnom, prenom, email, telephone, active, created_at, updated_at
             FROM utilisateurs
             ORDER BY created_at DESC'
        );

        return array_map(
            static fn (array $user) => self::publicUser($user, self::rolesForUser((int) $user['id'])),
            $statement->fetchAll()
        );
    }

    public static function create(array $data): int
    {
        $statement = Database::connection()->prepare(
            'INSERT INTO utilisateurs (nom, postnom, prenom, email, telephone, password_hash, active)
             VALUES (:nom, :postnom, :prenom, :email, :telephone, :password_hash, :active)'
        );

        $statement->execute([
            'nom' => trim((string) ($data['nom'] ?? '')),
            'postnom' => trim((string) ($data['postnom'] ?? '')),
            'prenom' => trim((string) ($data['prenom'] ?? '')),
            'email' => strtolower(trim((string) ($data['email'] ?? ''))),
            'telephone' => trim((string) ($data['telephone'] ?? '')),
            'password_hash' => (string) $data['password_hash'],
            'active' => (int) ($data['active'] ?? 1),
        ]);

        return (int) Database::connection()->lastInsertId();
    }

    public static function attachRoles(int $userId, array $roleCodes): void
    {
        $roleIds = Role::idsByCodes($roleCodes);
        $statement = Database::connection()->prepare(
            'INSERT IGNORE INTO roles_utilisateurs (user_id, role_id) VALUES (:user_id, :role_id)'
        );

        foreach ($roleIds as $roleId) {
            $statement->execute([
                'user_id' => $userId,
                'role_id' => $roleId,
            ]);
        }
    }

    public static function rolesForUser(int $userId): array
    {
        $statement = Database::connection()->prepare(
            'SELECT r.id, r.code, r.libelle
             FROM roles r
             INNER JOIN roles_utilisateurs ru ON ru.role_id = r.id
             WHERE ru.user_id = :user_id
             ORDER BY r.libelle ASC'
        );
        $statement->execute(['user_id' => $userId]);

        return $statement->fetchAll();
    }

    public static function roleCodesForUser(int $userId): array
    {
        return array_map(
            static fn (array $role) => $role['code'],
            self::rolesForUser($userId)
        );
    }

    public static function createRememberToken(int $userId, int $days): string
    {
        $selector = bin2hex(random_bytes(9));
        $validator = bin2hex(random_bytes(32));
        $expiresAt = (new DateTimeImmutable('+' . $days . ' days'))->format('Y-m-d H:i:s');

        $statement = Database::connection()->prepare(
            'INSERT INTO remember_tokens (user_id, selector, validator_hash, expires_at)
             VALUES (:user_id, :selector, :validator_hash, :expires_at)'
        );
        $statement->execute([
            'user_id' => $userId,
            'selector' => $selector,
            'validator_hash' => password_hash($validator, PASSWORD_DEFAULT),
            'expires_at' => $expiresAt,
        ]);

        return $selector . ':' . $validator;
    }

    public static function userIdFromRememberToken(string $token): ?int
    {
        [$selector, $validator] = array_pad(explode(':', $token, 2), 2, null);

        if (!$selector || !$validator) {
            return null;
        }

        $statement = Database::connection()->prepare(
            'SELECT id, user_id, validator_hash
             FROM remember_tokens
             WHERE selector = :selector AND expires_at > NOW()
             LIMIT 1'
        );
        $statement->execute(['selector' => $selector]);
        $rememberToken = $statement->fetch();

        if (!$rememberToken || !password_verify($validator, $rememberToken['validator_hash'])) {
            return null;
        }

        $update = Database::connection()->prepare(
            'UPDATE remember_tokens SET last_used_at = NOW() WHERE id = :id'
        );
        $update->execute(['id' => $rememberToken['id']]);

        return (int) $rememberToken['user_id'];
    }

    public static function deleteRememberToken(string $token): void
    {
        [$selector] = array_pad(explode(':', $token, 2), 1, null);

        if (!$selector) {
            return;
        }

        $statement = Database::connection()->prepare(
            'DELETE FROM remember_tokens WHERE selector = :selector'
        );
        $statement->execute(['selector' => $selector]);
    }

    public static function publicUser(array $user, array $roles): array
    {
        unset($user['password_hash']);

        $user['id'] = (int) $user['id'];
        $user['active'] = (bool) ($user['active'] ?? true);
        $user['roles'] = array_values($roles);
        $user['role_codes'] = array_map(static fn (array $role) => $role['code'], $roles);

        return $user;
    }
}
