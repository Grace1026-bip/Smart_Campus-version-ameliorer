<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

class Teacher
{
    public static function createProfile(int $userId, array $data): void
    {
        $statement = Database::connection()->prepare(
            'INSERT INTO profs (user_id, department_id, course_id, specialite)
             VALUES (:user_id, :department_id, :course_id, :specialite)'
        );

        $statement->execute([
            'user_id' => $userId,
            'department_id' => $data['department_id'] ?? null,
            'course_id' => $data['course_id'] ?? null,
            'specialite' => $data['specialite'] ?? null,
        ]);
    }
}
