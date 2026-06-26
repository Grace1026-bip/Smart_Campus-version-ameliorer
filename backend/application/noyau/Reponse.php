<?php

declare(strict_types=1);

namespace Application\Noyau;

class Reponse
{
    public static function json(array $charge, int $statut = 200): void
    {
        http_response_code($statut);
        header('Content-Type: application/json; charset=utf-8');
        echo json_encode($charge, JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE | JSON_PRETTY_PRINT);
    }

    public static function succes(array $donnees = [], string $message = 'OK', int $statut = 200): void
    {
        self::json([
            'succes' => true,
            'message' => $message,
            'donnees' => $donnees,
        ], $statut);
    }

    public static function erreur(string $message, int $statut = 400, array $erreurs = []): void
    {
        self::json([
            'succes' => false,
            'message' => $message,
            'erreurs' => $erreurs,
        ], $statut);
    }
}
