<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;

class AlerteAcademiqueService
{
    public static function alertesEtudiant(int $etudiantId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT aa.*, c.code AS code_cours, c.nom AS cours
             FROM alertes_academiques aa
             LEFT JOIN cours c ON c.id = aa.cours_id
             WHERE aa.etudiant_id = :etudiant_id
             ORDER BY aa.date_creation DESC'
        );
        $requete->execute(['etudiant_id' => $etudiantId]);

        return array_map(static function (array $alerte): array {
            $alerte['id'] = (int) $alerte['id'];
            $alerte['etudiant_id'] = (int) $alerte['etudiant_id'];
            $alerte['cours_id'] = $alerte['cours_id'] === null ? null : (int) $alerte['cours_id'];
            $alerte['lue'] = (bool) $alerte['lue'];

            return $alerte;
        }, $requete->fetchAll());
    }
}
