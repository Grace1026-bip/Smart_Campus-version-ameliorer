<?php

declare(strict_types=1);

namespace App\Core;

abstract class Controller
{
    protected function json(array $data, string $message = 'OK', int $status = 200): void
    {
        Response::success($data, $message, $status);
    }

    protected function error(string $message, int $status = 400, array $extra = []): void
    {
        Response::error($message, $status, $extra);
    }

    protected function requireFields(array $data, array $fields): array
    {
        $errors = [];

        foreach ($fields as $field) {
            if (!array_key_exists($field, $data) || trim((string) $data[$field]) === '') {
                $errors[$field] = 'Champ obligatoire.';
            }
        }

        return $errors;
    }
}
