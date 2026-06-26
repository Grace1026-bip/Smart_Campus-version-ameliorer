<?php

declare(strict_types=1);

namespace App\Models;

use App\Core\Database;
use App\Core\HttpException;
use PDO;

class RegistrationRequest
{
    public const STATUS_PENDING = 'en_attente';
    public const STATUS_APPROVED = 'approuvee';
    public const STATUS_REJECTED = 'rejetee';

    public static function create(array $data): int
    {
        $requestedRole = Role::normalizeCode((string) ($data['requested_role'] ?? $data['role_demande'] ?? ''));

        $statement = Database::connection()->prepare(
            'INSERT INTO registration_requests (
                nom, postnom, prenom, email, telephone, requested_role, promotion_id,
                department_id, course_id, promotion_label, department_label, course_label,
                matricule, specialite, password_hash, status, metadata
             ) VALUES (
                :nom, :postnom, :prenom, :email, :telephone, :requested_role, :promotion_id,
                :department_id, :course_id, :promotion_label, :department_label, :course_label,
                :matricule, :specialite, :password_hash, :status, :metadata
             )'
        );

        $statement->execute([
            'nom' => trim((string) $data['nom']),
            'postnom' => trim((string) ($data['postnom'] ?? '')),
            'prenom' => trim((string) ($data['prenom'] ?? '')),
            'email' => strtolower(trim((string) $data['email'])),
            'telephone' => trim((string) $data['telephone']),
            'requested_role' => $requestedRole,
            'promotion_id' => self::nullableInt($data['promotion_id'] ?? null),
            'department_id' => self::nullableInt($data['department_id'] ?? null),
            'course_id' => self::nullableInt($data['course_id'] ?? null),
            'promotion_label' => self::nullableString($data['promotion'] ?? $data['promotion_label'] ?? null),
            'department_label' => self::nullableString($data['departement'] ?? $data['department'] ?? $data['department_label'] ?? null),
            'course_label' => self::nullableString($data['cours'] ?? $data['course'] ?? $data['course_label'] ?? null),
            'matricule' => self::nullableString($data['matricule'] ?? null),
            'specialite' => self::nullableString($data['specialite'] ?? null),
            'password_hash' => password_hash((string) $data['password'], PASSWORD_DEFAULT),
            'status' => self::STATUS_PENDING,
            'metadata' => json_encode($data['metadata'] ?? [], JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE),
        ]);

        return (int) Database::connection()->lastInsertId();
    }

    public static function all(?string $status = null): array
    {
        $sql = 'SELECT rr.*, approver.email AS approver_email, created_user.email AS user_email
                FROM registration_requests rr
                LEFT JOIN utilisateurs approver ON approver.id = rr.approved_by
                LEFT JOIN utilisateurs created_user ON created_user.id = rr.user_id';
        $params = [];

        if ($status !== null && $status !== '') {
            $sql .= ' WHERE rr.status = :status';
            $params['status'] = $status;
        }

        $sql .= ' ORDER BY rr.created_at DESC';

        $statement = Database::connection()->prepare($sql);
        $statement->execute($params);

        return array_map([self::class, 'publicRequest'], $statement->fetchAll());
    }

    public static function find(int $id): ?array
    {
        $statement = Database::connection()->prepare(
            'SELECT * FROM registration_requests WHERE id = :id LIMIT 1'
        );
        $statement->execute(['id' => $id]);
        $request = $statement->fetch();

        return $request ? self::publicRequest($request) : null;
    }

    public static function approve(int $id, int $approverId, array $approverRoles): array
    {
        return Database::transaction(function (PDO $pdo) use ($id, $approverId, $approverRoles) {
            $request = self::findForUpdate($id);

            if ($request === null) {
                throw new HttpException('Demande introuvable.', 404);
            }

            if ($request['status'] !== self::STATUS_PENDING) {
                throw new HttpException('Cette demande a deja ete traitee.', 409);
            }

            if (!self::canApprove((string) $request['requested_role'], $approverRoles)) {
                throw new HttpException('Role non autorise pour approuver cette demande.', 403);
            }

            if (User::findByEmail((string) $request['email']) !== null) {
                throw new HttpException('Un utilisateur existe deja avec cet email.', 409);
            }

            $rolesToAssign = self::rolesToAssign((string) $request['requested_role']);
            $userId = User::create([
                'nom' => $request['nom'],
                'postnom' => $request['postnom'],
                'prenom' => $request['prenom'],
                'email' => $request['email'],
                'telephone' => $request['telephone'],
                'password_hash' => $request['password_hash'],
                'active' => 1,
            ]);

            User::attachRoles($userId, $rolesToAssign);

            if (array_intersect($rolesToAssign, ['etudiant', 'cp']) !== []) {
                Student::createProfile($userId, $request);
            }

            if (array_intersect($rolesToAssign, ['enseignant', 'doyen', 'vice_doyen']) !== []) {
                Teacher::createProfile($userId, $request);
            }

            $statement = $pdo->prepare(
                'UPDATE registration_requests
                 SET status = :status, approved_by = :approved_by, user_id = :user_id,
                     decided_at = NOW(), updated_at = NOW()
                 WHERE id = :id'
            );
            $statement->execute([
                'status' => self::STATUS_APPROVED,
                'approved_by' => $approverId,
                'user_id' => $userId,
                'id' => $id,
            ]);

            return [
                'request' => self::find($id),
                'user' => User::findWithRoles($userId),
            ];
        });
    }

    public static function reject(int $id, int $approverId, array $approverRoles, ?string $reason = null): array
    {
        return Database::transaction(function (PDO $pdo) use ($id, $approverId, $approverRoles, $reason) {
            $request = self::findForUpdate($id);

            if ($request === null) {
                throw new HttpException('Demande introuvable.', 404);
            }

            if ($request['status'] !== self::STATUS_PENDING) {
                throw new HttpException('Cette demande a deja ete traitee.', 409);
            }

            if (!self::canApprove((string) $request['requested_role'], $approverRoles)) {
                throw new HttpException('Role non autorise pour rejeter cette demande.', 403);
            }

            $statement = $pdo->prepare(
                'UPDATE registration_requests
                 SET status = :status, approved_by = :approved_by, rejection_reason = :reason,
                     decided_at = NOW(), updated_at = NOW()
                 WHERE id = :id'
            );
            $statement->execute([
                'status' => self::STATUS_REJECTED,
                'approved_by' => $approverId,
                'reason' => $reason,
                'id' => $id,
            ]);

            return self::find($id) ?? [];
        });
    }

    public static function canApprove(string $requestedRole, array $approverRoles): bool
    {
        $requestedRole = Role::normalizeCode($requestedRole);
        $approverRoles = array_map([Role::class, 'normalizeCode'], $approverRoles);

        if (in_array('administrateur', $approverRoles, true)) {
            return true;
        }

        if (in_array($requestedRole, ['etudiant', 'cp'], true)) {
            return array_intersect($approverRoles, ['cp', 'paritaire', 'doyen', 'vice_doyen', 'appariteur']) !== [];
        }

        if (in_array($requestedRole, ['enseignant', 'doyen', 'vice_doyen'], true)) {
            return array_intersect($approverRoles, ['appariteur', 'doyen', 'vice_doyen']) !== [];
        }

        return false;
    }

    private static function rolesToAssign(string $requestedRole): array
    {
        $role = Role::normalizeCode($requestedRole);
        $roles = [$role];

        if (in_array($role, ['doyen', 'vice_doyen'], true)) {
            $roles[] = 'enseignant';
        }

        return array_values(array_unique($roles));
    }

    private static function findForUpdate(int $id): ?array
    {
        $statement = Database::connection()->prepare(
            'SELECT * FROM registration_requests WHERE id = :id LIMIT 1 FOR UPDATE'
        );
        $statement->execute(['id' => $id]);
        $request = $statement->fetch();

        return $request ?: null;
    }

    private static function publicRequest(array $request): array
    {
        unset($request['password_hash']);
        $request['id'] = (int) $request['id'];
        $request['promotion_id'] = self::nullableInt($request['promotion_id'] ?? null);
        $request['department_id'] = self::nullableInt($request['department_id'] ?? null);
        $request['course_id'] = self::nullableInt($request['course_id'] ?? null);
        $request['approved_by'] = self::nullableInt($request['approved_by'] ?? null);
        $request['user_id'] = self::nullableInt($request['user_id'] ?? null);
        $request['metadata'] = isset($request['metadata']) && $request['metadata']
            ? json_decode((string) $request['metadata'], true)
            : [];

        return $request;
    }

    private static function nullableString(mixed $value): ?string
    {
        if ($value === null || trim((string) $value) === '') {
            return null;
        }

        return trim((string) $value);
    }

    private static function nullableInt(mixed $value): ?int
    {
        if ($value === null || $value === '') {
            return null;
        }

        return (int) $value;
    }
}
