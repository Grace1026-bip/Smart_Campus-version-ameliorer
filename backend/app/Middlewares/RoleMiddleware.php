<?php

declare(strict_types=1);

namespace App\Middlewares;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;

class RoleMiddleware
{
    public static function handle(array $roles): callable
    {
        return static function (Request $request) use ($roles): bool {
            if (!Auth::hasRole($roles)) {
                Response::error('Acces interdit pour ce role.', 403);

                return false;
            }

            return true;
        };
    }
}
