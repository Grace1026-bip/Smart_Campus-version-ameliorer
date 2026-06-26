<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Modeles\Enseignant;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class EnseignantControleur
{
    public function tableauDeBord(Requete $requete): void
    {
        ReponseApiService::succes([
            'tableau_de_bord' => Enseignant::tableauDeBord((int) AuthentificationService::idUtilisateur()),
        ], 'Tableau de bord enseignant.');
    }
}
