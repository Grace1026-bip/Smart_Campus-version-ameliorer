<?php

declare(strict_types=1);

namespace Application\Controleurs;

use Application\Modeles\Etudiant;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\ReponseApiService;

class EtudiantControleur
{
    public function tableauDeBord(Requete $requete): void
    {
        ReponseApiService::succes([
            'tableau_de_bord' => Etudiant::tableauDeBord((int) AuthentificationService::idUtilisateur()),
        ], 'Tableau de bord etudiant.');
    }
}
