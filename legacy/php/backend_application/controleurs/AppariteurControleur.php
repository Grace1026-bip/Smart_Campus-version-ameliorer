<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\AppariteurService;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class AppariteurControleur
{
    public function tableauDeBord(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['tableau_de_bord' => AppariteurService::tableauDeBord()],
            'Tableau de bord appariteur.'
        );
    }

    public function etudiants(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['etudiants' => AppariteurService::etudiants()],
            'Etudiants supervises.'
        );
    }

    public function enseignants(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['enseignants' => AppariteurService::enseignants()],
            'Enseignants supervises.'
        );
    }

    public function promotions(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['promotions' => AppariteurService::promotions()],
            'Promotions supervisees.'
        );
    }

    public function detailPromotion(Requete $requete, string $id): void
    {
        $this->executer(
            static fn (): array => ['promotion' => AppariteurService::promotion((int) $id)],
            'Detail promotion.'
        );
    }

    public function cours(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['cours' => AppariteurService::cours()],
            'Cours supervises.'
        );
    }

    public function detailCours(Requete $requete, string $id): void
    {
        $this->executer(
            static fn (): array => ['cours' => AppariteurService::detailCours((int) $id)],
            'Detail cours.'
        );
    }

    public function reclamations(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['reclamations' => AppariteurService::reclamations()],
            'Reclamations apparitorat.'
        );
    }

    public function detailReclamation(Requete $requete, string $id): void
    {
        $this->executer(
            static fn (): array => ['reclamation' => AppariteurService::detailReclamation((int) $id)],
            'Detail reclamation apparitorat.'
        );
    }

    public function changerStatutReclamation(Requete $requete, string $id): void
    {
        $this->executer(function () use ($requete, $id): array {
            return [
                'reclamation' => AppariteurService::changerStatutReclamation(
                    (int) AuthentificationService::idUtilisateur(),
                    (int) $id,
                    $requete->donnees()
                ),
            ];
        }, 'Statut de reclamation mis a jour.');
    }

    public function risques(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['risques' => AppariteurService::risques()],
            'Risques academiques.'
        );
    }

    public function projets(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['projets' => AppariteurService::projets()],
            'Projets academiques.'
        );
    }

    public function stages(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['stages' => AppariteurService::stages()],
            'Stages supervises.'
        );
    }

    public function assistant(Requete $requete): void
    {
        $this->executer(
            static fn (): array => ['assistant' => AppariteurService::assistant()],
            'Assistant appariteur.'
        );
    }

    public function rapports(Requete $requete): void
    {
        $this->executer(
            static fn (): array => AppariteurService::rapports(),
            'Rapports apparitorat.'
        );
    }

    private function executer(callable $action, string $message, int $statut = 200): void
    {
        try {
            ReponseApiService::succes($action(), $message, $statut);
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }
}
