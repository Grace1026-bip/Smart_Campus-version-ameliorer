<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\CoursService;
use Application\Services\EnseignantService;
use Application\Services\NoteService;
use Application\Services\ReclamationService;
use Application\Services\ReponseApiService;
use Application\Services\ValveService;

class EnseignantControleur
{
    public function tableauDeBord(Requete $requete): void
    {
        $this->executer(function (): array {
            return [
                'tableau_de_bord' => EnseignantService::tableauDeBord((int) AuthentificationService::idUtilisateur()),
            ];
        }, 'Tableau de bord enseignant.');
    }

    public function cours(Requete $requete): void
    {
        $this->executer(function (): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['cours' => CoursService::coursEnseignant($enseignantId)];
        }, 'Cours enseignant recuperes.');
    }

    public function detailCours(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['cours' => CoursService::detailCoursEnseignant($enseignantId, (int) $id)];
        }, 'Detail du cours enseignant.');
    }

    public function valve(Requete $requete): void
    {
        $this->executer(function (): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['publications' => ValveService::valveEnseignant($enseignantId)];
        }, 'Valve enseignant recuperee.');
    }

    public function creerPublication(Requete $requete): void
    {
        $this->executer(function () use ($requete): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['publication' => ValveService::creerPublication($enseignantId, $requete->donnees())];
        }, 'Publication creee.', 201);
    }

    public function modifierPublication(Requete $requete, string $id): void
    {
        $this->executer(function () use ($requete, $id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['publication' => ValveService::modifierPublication($enseignantId, (int) $id, $requete->donnees())];
        }, 'Publication modifiee.');
    }

    public function supprimerPublication(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());
            ValveService::supprimerPublication($enseignantId, (int) $id);

            return [];
        }, 'Publication supprimee.');
    }

    public function etudiantsCours(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['etudiants' => CoursService::etudiantsCours($enseignantId, (int) $id)];
        }, 'Etudiants du cours recuperes.');
    }

    public function notesCours(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return [
                'notes' => NoteService::notesCoursEnseignant($enseignantId, (int) $id),
                'statistiques' => NoteService::statistiquesCours((int) $id),
            ];
        }, 'Notes du cours recuperees.');
    }

    public function enregistrerBrouillon(Requete $requete, string $id): void
    {
        $this->executer(function () use ($requete, $id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return NoteService::enregistrerBrouillon($enseignantId, (int) $id, $requete->donnees());
        }, 'Notes enregistrees en brouillon.');
    }

    public function publierNotes(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return NoteService::publierNotes($enseignantId, (int) $id);
        }, 'Notes publiees et verrouillees.');
    }

    public function etudiantsRisque(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['etudiants_a_risque' => EnseignantService::etudiantsRisqueCours($enseignantId, (int) $id)];
        }, 'Etudiants a risque recuperes.');
    }

    public function reclamations(Requete $requete): void
    {
        $this->executer(function (): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['reclamations' => ReclamationService::reclamationsEnseignant($enseignantId)];
        }, 'Reclamations enseignant recuperees.');
    }

    public function detailReclamation(Requete $requete, string $id): void
    {
        $this->executer(function () use ($id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return ['reclamation' => ReclamationService::reclamationEnseignant($enseignantId, (int) $id)];
        }, 'Detail de la reclamation enseignant.');
    }

    public function repondreReclamation(Requete $requete, string $id): void
    {
        $this->executer(function () use ($requete, $id): array {
            $enseignantId = CoursService::enseignantId((int) AuthentificationService::idUtilisateur());

            return [
                'reclamation' => ReclamationService::repondre(
                    $enseignantId,
                    (int) AuthentificationService::idUtilisateur(),
                    (int) $id,
                    $requete->donnees()
                ),
            ];
        }, 'Reponse enregistree.');
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
