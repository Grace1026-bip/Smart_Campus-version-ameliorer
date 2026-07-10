<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

class Student
{
    public static function createProfile(int $userId, array $data): void
    {
        $statement = Database::connection()->prepare(
            'INSERT INTO etudiants (user_id, matricule, promotion_id, department_id)
             VALUES (:user_id, :matricule, :promotion_id, :department_id)'
        );

        $statement->execute([
            'user_id' => $userId,
            'matricule' => $data['matricule'] ?? null,
            'promotion_id' => $data['promotion_id'] ?? null,
            'department_id' => $data['department_id'] ?? null,
        ]);
    }
}
