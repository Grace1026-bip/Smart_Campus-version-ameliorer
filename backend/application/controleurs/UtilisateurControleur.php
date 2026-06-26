<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Modeles\Role;
use Application\Modeles\Utilisateur;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class UtilisateurControleur
{
    public function connecte(Requete $requete): void
    {
        $utilisateur = AuthentificationService::utilisateurConnecte();

        if ($utilisateur === null) {
            ReponseApiService::erreur('Utilisateur non connecte.', 401);
            return;
        }

        ReponseApiService::succes([
            'utilisateur' => $utilisateur,
            'roles' => $utilisateur['roles_codes'],
        ], 'Utilisateur connecte.');
    }

    public function roles(Requete $requete): void
    {
        ReponseApiService::succes([
            'roles' => Role::tous(),
        ], 'Roles recuperes.');
    }

    public function utilisateurs(Requete $requete): void
    {
        ReponseApiService::succes([
            'utilisateurs' => Utilisateur::tous(),
        ], 'Utilisateurs recuperes.');
    }
}
