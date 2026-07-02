<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\AlerteAcademiqueService;
use Application\Services\AuthentificationService;
use Application\Services\CoursService;
use Application\Services\EtudiantService;
use Application\Services\NoteService;
use Application\Services\ReclamationService;
use Application\Services\ReponseApiService;
use Application\Services\ValveService;

class EtudiantControleur
{
    public function tableauDeBord(Requete $requete): void
    {
        $this->executer(function (): array {
            return [
                'tableau_de_bord' => EtudiantService::tableauDeBord((int) AuthentificationService::idUtilisateur()),
            ];
        }, 'Tableau de bord etudiant.');
    }

    public function cours(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['cours' => CoursService::coursEtudiant($etudiantId)];
        }, 'Cours etudiant recuperes.');
    }

    public function detailCours(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['cours' => CoursService::detailCoursEtudiant($etudiantId, (int) $id)];
        }, 'Detail du cours etudiant.');
    }

    public function valve(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['valve' => ValveService::valveEtudiant($etudiantId)];
        }, 'Valve etudiante recuperee.');
    }

    public function valveCours(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ValveService::valveCoursEtudiant($etudiantId, (int) $id);
        }, 'Valve du cours recuperee.');
    }

    public function notes(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return [
                'notes' => NoteService::notesEtudiant($etudiantId),
                'resume' => NoteService::resumeEtudiant($etudiantId),
            ];
        }, 'Notes etudiantes recuperees.');
    }

    public function alertes(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['alertes' => AlerteAcademiqueService::alertesEtudiant($etudiantId)];
        }, 'Alertes academiques recuperees.');
    }

    public function reclamations(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['reclamations' => ReclamationService::reclamationsEtudiant($etudiantId)];
        }, 'Reclamations etudiantes recuperees.');
    }

    public function creerReclamation(Requete $requete): void
    {
        $this->executer(function () use ($requete): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['reclamation' => ReclamationService::creer($etudiantId, $requete->donnees())];
        }, 'Reclamation creee.', 201);
    }

    public function profil(Requete $requete): void
    {
        $this->executer(function (): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['profil' => EtudiantService::profil($etudiantId)];
        }, 'Profil etudiant recupere.');
    }

    public function modifierProfil(Requete $requete): void
    {
        $this->executer(function () use ($requete): array {
            $etudiantId = CoursService::etudiantId((int) AuthentificationService::idUtilisateur());

            return ['profil' => EtudiantService::modifierProfil($etudiantId, $requete->donnees())];
        }, 'Profil etudiant mis a jour.');
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
