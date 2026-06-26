<?php

declare(strict_types=1);

namespace Application\Middlewares;

use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class AuthentificationMiddleware
{
    public static function gerer(Requete $requete): bool
    {
        if (AuthentificationService::utilisateurConnecte() === null) {
            ReponseApiService::erreur('Authentification requise.', 401);

            return false;
        }

        return true;
    }
}
