<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Request;
use App\Models\Role;

class AuthController extends Controller
{
    public function login(Request $request): void
    {
        $data = $request->all();
        $email = trim((string) ($data['email'] ?? $data['identifier'] ?? ''));
        $password = (string) ($data['password'] ?? '');
        $role = Role::normalizeCode($data['role'] ?? null);
        $remember = filter_var($data['remember'] ?? $data['remember_me'] ?? false, FILTER_VALIDATE_BOOLEAN);

        $errors = [];
        if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Email invalide.';
        }

        if ($password === '') {
            $errors['password'] = 'Mot de passe obligatoire.';
        }

        if ($errors !== []) {
            $this->error('Validation echouee.', 422, ['errors' => $errors]);
            return;
        }

        $session = Auth::attempt($email, $password, $role, $remember);

        if ($session === null) {
            $this->error('Identifiants invalides ou role non autorise.', 401);
            return;
        }

        $this->json($session, 'Connexion reussie.');
    }

    public function logout(Request $request): void
    {
        Auth::logout();

        $config = require base_path('config/app.php');
        $this->json([
            'redirect' => $config['frontend_login_url'],
        ], 'Deconnexion reussie.');
    }

    public function me(Request $request): void
    {
        $user = Auth::user();

        if ($user === null) {
            $this->error('Utilisateur non connecte.', 401);
            return;
        }

        $this->json(['user' => $user], 'Utilisateur connecte.');
    }
}
