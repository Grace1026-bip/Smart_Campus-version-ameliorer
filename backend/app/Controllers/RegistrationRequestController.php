<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\HttpException;
use App\Core\Request;
use App\Models\RegistrationRequest;
use App\Models\Role;
use Throwable;

class RegistrationRequestController extends Controller
{
    public function store(Request $request): void
    {
        $data = $request->all();
        $requestedRole = Role::normalizeCode($data['requested_role'] ?? $data['role_demande'] ?? null);
        $data['requested_role'] = $requestedRole;

        $errors = $this->requireFields($data, [
            'nom',
            'email',
            'telephone',
            'requested_role',
            'password',
        ]);

        if (($data['email'] ?? '') !== '' && !filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Email invalide.';
        }

        if (($data['password'] ?? '') !== '' && strlen((string) $data['password']) < 8) {
            $errors['password'] = 'Le mot de passe doit contenir au moins 8 caracteres.';
        }

        if ($requestedRole === null || !Role::isKnown($requestedRole)) {
            $errors['requested_role'] = 'Role demande invalide.';
        }

        if ($requestedRole === 'etudiant' && empty($data['promotion_id']) && empty($data['promotion'])) {
            $errors['promotion'] = 'Promotion obligatoire pour un etudiant.';
        }

        if (in_array($requestedRole, ['enseignant', 'doyen', 'vice_doyen'], true)
            && empty($data['department_id'])
            && empty($data['departement'])
            && empty($data['department'])
            && empty($data['course_id'])
            && empty($data['cours'])
            && empty($data['course'])
        ) {
            $errors['enseignant'] = 'Departement ou cours obligatoire pour un enseignant.';
        }

        if ($errors !== []) {
            $this->error('Validation echouee.', 422, ['errors' => $errors]);
            return;
        }

        try {
            $id = RegistrationRequest::create($data);
        } catch (Throwable) {
            $this->error('Impossible de creer la demande. Verifiez que l email n est pas deja utilise.', 409);
            return;
        }

        $this->json([
            'request' => RegistrationRequest::find($id),
        ], 'Demande d inscription creee.', 201);
    }

    public function index(Request $request): void
    {
        $status = $request->query('status');
        $this->json([
            'requests' => RegistrationRequest::all($status ? (string) $status : null),
        ], 'Demandes recuperees.');
    }

    public function approve(Request $request, string $id): void
    {
        try {
            $result = RegistrationRequest::approve((int) $id, (int) Auth::id(), Auth::roleCodes());
        } catch (HttpException $exception) {
            $this->error($exception->getMessage(), $exception->status());
            return;
        }

        $this->json($result, 'Demande approuvee.');
    }

    public function reject(Request $request, string $id): void
    {
        $data = $request->all();
        $reason = $data['reason'] ?? $data['motif'] ?? null;

        try {
            $requestData = RegistrationRequest::reject(
                (int) $id,
                (int) Auth::id(),
                Auth::roleCodes(),
                $reason ? (string) $reason : null
            );
        } catch (HttpException $exception) {
            $this->error($exception->getMessage(), $exception->status());
            return;
        }

        $this->json(['request' => $requestData], 'Demande rejetee.');
    }
}
