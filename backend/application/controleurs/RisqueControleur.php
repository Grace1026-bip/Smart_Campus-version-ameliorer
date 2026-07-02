<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\ReponseApiService;
use Application\Services\RisqueService;

class RisqueControleur
{
    public function index(Requete $requete): void
    {
        try {
            ReponseApiService::succes(
                ['risques' => RisqueService::risquesAcademiques()],
                'Risques academiques.'
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }
}
