<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\Role;

class PermissionService
{
    public static function peutApprouver(string $typeDemande, array $rolesUtilisateur): bool
    {
        $typeDemande = Role::normaliser($typeDemande) ?? '';
        $rolesUtilisateur = array_values(array_filter(array_map(
            static fn ($role): ?string => Role::normaliser((string) $role),
            $rolesUtilisateur
        )));

        if (in_array('administrateur', $rolesUtilisateur, true)) {
            return true;
        }

        if ($typeDemande === 'etudiant') {
            return array_intersect($rolesUtilisateur, ['icp', 'paritaire', 'doyen', 'vice_doyen']) !== [];
        }

        if ($typeDemande === 'enseignant') {
            return array_intersect($rolesUtilisateur, ['paritaire', 'doyen', 'vice_doyen']) !== [];
        }

        return false;
    }

    public static function aUnRole(array $rolesUtilisateur, array $rolesAutorises): bool
    {
        $rolesUtilisateur = array_map([Role::class, 'normaliser'], $rolesUtilisateur);
        $rolesAutorises = array_map([Role::class, 'normaliser'], $rolesAutorises);

        return array_intersect($rolesUtilisateur, $rolesAutorises) !== [];
    }
}
