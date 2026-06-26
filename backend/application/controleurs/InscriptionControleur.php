<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Modeles\Role;
use Application\Services\AuthentificationService;
use Application\Services\InscriptionService;
use Application\Services\ReponseApiService;

class InscriptionControleur
{
    public function inscrireEtudiant(Requete $requete): void
    {
        $donnees = $this->normaliserMotDePasse($requete->donnees());

        try {
            ReponseApiService::succes(
                InscriptionService::inscrireEtudiant($donnees),
                "Demande d'inscription etudiante creee.",
                201
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    public function inscrireEnseignant(Requete $requete): void
    {
        $donnees = $this->normaliserMotDePasse($requete->donnees());

        try {
            ReponseApiService::succes(
                InscriptionService::inscrireEnseignant($donnees),
                "Demande d'inscription enseignante creee.",
                201
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    public function inscrireGenerique(Requete $requete): void
    {
        $donnees = $this->normaliserMotDePasse($requete->donnees());
        $role = Role::normaliser($donnees['type_demande'] ?? $donnees['role_demande'] ?? $donnees['requested_role'] ?? 'etudiant');

        if ($role === 'enseignant') {
            $this->executerInscriptionEnseignant($donnees);
            return;
        }

        $this->executerInscriptionEtudiant($donnees);
    }

    public function demandes(Requete $requete): void
    {
        ReponseApiService::succes([
            'demandes' => InscriptionService::demandes($requete->requete('statut', $requete->requete('status'))),
        ], 'Demandes recuperees.');
    }

    public function approuver(Requete $requete, string $id): void
    {
        try {
            ReponseApiService::succes(
                InscriptionService::approuver(
                    (int) $id,
                    (int) AuthentificationService::idUtilisateur(),
                    AuthentificationService::roles()
                ),
                'Demande approuvee.'
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    public function rejeter(Requete $requete, string $id): void
    {
        $donnees = $requete->donnees();
        $message = isset($donnees['message'])
            ? nettoyer_chaine($donnees['message'])
            : (isset($donnees['motif'])
                ? nettoyer_chaine($donnees['motif'])
                : (isset($donnees['reason']) ? nettoyer_chaine($donnees['reason']) : null));

        try {
            ReponseApiService::succes(
                InscriptionService::rejeter(
                    (int) $id,
                    (int) AuthentificationService::idUtilisateur(),
                    AuthentificationService::roles(),
                    $message
                ),
                'Demande rejetee.'
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    private function normaliserMotDePasse(array $donnees): array
    {
        if (!isset($donnees['mot_de_passe']) && isset($donnees['password'])) {
            $donnees['mot_de_passe'] = $donnees['password'];
        }

        if (!isset($donnees['departement']) && isset($donnees['department'])) {
            $donnees['departement'] = $donnees['department'];
        }

        if (!isset($donnees['cours']) && isset($donnees['course'])) {
            $donnees['cours'] = $donnees['course'];
        }

        if (!isset($donnees['promotion']) && isset($donnees['promotion_label'])) {
            $donnees['promotion'] = $donnees['promotion_label'];
        }

        return $donnees;
    }

    private function executerInscriptionEtudiant(array $donnees): void
    {
        try {
            ReponseApiService::succes(
                InscriptionService::inscrireEtudiant($donnees),
                "Demande d'inscription etudiante creee.",
                201
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    private function executerInscriptionEnseignant(array $donnees): void
    {
        try {
            ReponseApiService::succes(
                InscriptionService::inscrireEnseignant($donnees),
                "Demande d'inscription enseignante creee.",
                201
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }
}
