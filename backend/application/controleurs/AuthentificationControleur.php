<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Noyau\ExceptionHttp;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class AuthentificationControleur
{
    public function connexion(Requete $requete): void
    {
        $donnees = $requete->donnees();
        $email = nettoyer_chaine($donnees['email'] ?? $donnees['gmail'] ?? '');
        $motDePasse = (string) ($donnees['mot_de_passe'] ?? $donnees['password'] ?? '');
        $souvenir = normaliser_booleen(
            $donnees['se_souvenir_de_moi'] ?? $donnees['souvenir'] ?? $donnees['remember_me'] ?? $donnees['remember'] ?? false
        );

        $erreurs = [];

        if (!email_valide($email)) {
            $erreurs['email'] = 'Email invalide.';
        }

        if ($motDePasse === '') {
            $erreurs['mot_de_passe'] = 'Mot de passe obligatoire.';
        }

        if ($erreurs !== []) {
            ReponseApiService::erreur('Validation echouee.', 422, $erreurs);
            return;
        }

        try {
            ReponseApiService::succes(
                AuthentificationService::connexion($email, $motDePasse, $souvenir),
                'Connexion reussie'
            );
        } catch (ExceptionHttp $exception) {
            ReponseApiService::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
        }
    }

    public function deconnexion(Requete $requete): void
    {
        AuthentificationService::deconnexion();

        ReponseApiService::succes([], 'Deconnexion reussie');
    }
}
