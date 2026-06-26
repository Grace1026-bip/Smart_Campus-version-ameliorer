<?php

declare(strict_types=1);

namespace Application\Middlewares;

use Application\Modeles\Role;
use Application\Noyau\Requete;
use Application\Services\AuthentificationService;
use Application\Services\PermissionService;
use Application\Services\ReponseApiService;

class RoleMiddleware
{
    public static function autoriser(array $roles): callable
    {
        return static function (Requete $requete) use ($roles): bool {
            $rolesNormalises = array_values(array_filter(array_map(
                static fn ($role): ?string => Role::normaliser((string) $role),
                $roles
            )));

            if (!PermissionService::aUnRole(AuthentificationService::roles(), $rolesNormalises)) {
                ReponseApiService::erreur('Acces interdit pour ce role.', 403);

                return false;
            }

            return true;
        };
    }
}
