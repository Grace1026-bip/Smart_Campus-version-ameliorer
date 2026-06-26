<?php

declare(strict_types=1);

namespace App\Middlewares;

use App\Core\Auth;
use App\Core\Request;
use App\Core\Response;

class AuthMiddleware
{
    public static function handle(Request $request): bool
    {
        if (Auth::user() === null) {
            Response::error('Authentification requise.', 401);

            return false;
        }

        return true;
    }
}
