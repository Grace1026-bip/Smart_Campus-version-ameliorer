<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;

class Promotion
{
    public static function all(): array
    {
        $statement = Database::connection()->query(
            'SELECT id, code, libelle, department_id, created_at FROM promotions ORDER BY libelle ASC'
        );

        return $statement->fetchAll();
    }
}
