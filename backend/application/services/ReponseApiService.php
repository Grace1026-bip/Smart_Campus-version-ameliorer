<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\Reponse;

class ReponseApiService
{
    public static function succes(array $donnees = [], string $message = 'OK', int $statut = 200): void
    {
        Reponse::succes($donnees, $message, $statut);
    }

    public static function erreur(string $message, int $statut = 400, array $erreurs = []): void
    {
        Reponse::erreur($message, $statut, $erreurs);
    }
}
