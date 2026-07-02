<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\RapportService;
use Application\Services\ReponseApiService;

class RapportControleur
{
    public function apparitorat(Requete $requete): void
    {
        try {
            ReponseApiService::succes(
                RapportService::rapportsApparitorat(),
                'Rapports apparitorat.'
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }
}
