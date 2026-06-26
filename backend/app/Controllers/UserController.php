<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Controller;
use App\Core\Request;
use App\Models\Role;
use App\Models\User;

class UserController extends Controller
{
    public function index(Request $request): void
    {
        $this->json([
            'users' => User::all(),
        ], 'Utilisateurs recuperes.');
    }

    public function roles(Request $request): void
    {
        $this->json([
            'roles' => Role::all(),
        ], 'Roles recuperes.');
    }
}
