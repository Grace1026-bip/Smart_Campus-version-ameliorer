<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

class Role
{
    private const ALIASES = [
        'student' => 'etudiant',
        'etudiant' => 'etudiant',
        'etudiante' => 'etudiant',
        'teacher' => 'enseignant',
        'enseignant' => 'enseignant',
        'prof' => 'enseignant',
        'professeur' => 'enseignant',
        'promotionchief' => 'cp',
        'promotion_chief' => 'cp',
        'chef_promotion' => 'cp',
        'chef-de-promotion' => 'cp',
        'cp' => 'cp',
        'apparitor' => 'appariteur',
        'appariteur' => 'appariteur',
        'vice_dean' => 'vice_doyen',
        'vice-doyen' => 'vice_doyen',
        'vice_doyen' => 'vice_doyen',
        'dean' => 'doyen',
        'doyen' => 'doyen',
        'administrator' => 'administrateur',
        'admin' => 'administrateur',
        'administrateur' => 'administrateur',
        'paritaire' => 'paritaire',
    ];

    public static function all(): array
    {
        $statement = Database::connection()->query(
            'SELECT id, code, libelle, created_at FROM roles ORDER BY libelle ASC'
        );

        return $statement->fetchAll();
    }

    public static function normalizeCode(?string $code): ?string
    {
        if ($code === null) {
            return null;
        }

        $normalized = strtolower(trim($code));
        $normalized = str_replace([' ', '-'], ['_', '_'], $normalized);

        return self::ALIASES[$normalized] ?? $normalized;
    }

    public static function idsByCodes(array $codes): array
    {
        $codes = array_values(array_unique(array_filter(array_map(
            static fn ($code) => self::normalizeCode((string) $code),
            $codes
        ))));

        if ($codes === []) {
            return [];
        }

        $placeholders = implode(',', array_fill(0, count($codes), '?'));
        $statement = Database::connection()->prepare(
            "SELECT id, code FROM roles WHERE code IN ($placeholders)"
        );
        $statement->execute($codes);

        $roles = [];
        foreach ($statement->fetchAll() as $role) {
            $roles[$role['code']] = (int) $role['id'];
        }

        return $roles;
    }

    public static function isKnown(string $code): bool
    {
        $statement = Database::connection()->prepare(
            'SELECT COUNT(*) FROM roles WHERE code = :code'
        );
        $statement->execute(['code' => self::normalizeCode($code)]);

        return (int) $statement->fetchColumn() > 0;
    }
}
