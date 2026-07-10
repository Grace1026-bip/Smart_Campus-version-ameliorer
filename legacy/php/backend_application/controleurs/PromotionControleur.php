<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\PromotionService;
use Application\Services\ReponseApiService;

class PromotionControleur
{
    public function index(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['promotions' => PromotionService::promotionsSupervisees()],
            'Promotions supervisees.'
        );
    }

    public function detail(Requete $requete, string $id): void
    {
        $this->executer(
            static fn (): array => ['promotion' => PromotionService::detailSupervision((int) $id)],
            'Detail promotion.'
        );
    }

    private function executer(callable $action, string $message): void
    {
        try {
            ReponseApiService::succes($action(), $message);
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }
}
