<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class Role
{
    private const ALIASES = [
        'student' => 'etudiant',
        'etudiant' => 'etudiant',
        'etudiante' => 'etudiant',
        'teacher' => 'enseignant',
        'enseignant' => 'enseignant',
        'prof' => 'enseignant',
        'professeur' => 'enseignant',
        'chef_promotion' => 'chef_promotion',
        'chef-de-promotion' => 'chef_promotion',
        'promotion_chief' => 'chef_promotion',
        'cp' => 'chef_promotion',
        'icp' => 'icp',
        'appariteur' => 'appariteur',
        'apparitor' => 'appariteur',
        'paritaire' => 'paritaire',
        'doyen' => 'doyen',
        'dean' => 'doyen',
        'vice_doyen' => 'vice_doyen',
        'vice-doyen' => 'vice_doyen',
        'vice_dean' => 'vice_doyen',
        'admin' => 'administrateur',
        'administrator' => 'administrateur',
        'administrateur' => 'administrateur',
    ];

    public static function normaliser(?string $role): ?string
    {
        if ($role === null) {
            return null;
        }

        $normalise = strtolower(trim($role));
        $normalise = str_replace([' ', '-'], '_', $normalise);

        return self::ALIASES[$normalise] ?? $normalise;
    }

    public static function tous(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT id, nom_role FROM roles ORDER BY nom_role ASC'
        );

        return $requete->fetchAll();
    }

    public static function existe(string $role): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*) FROM roles WHERE nom_role = :role'
        );
        $requete->execute(['role' => self::normaliser($role)]);

        return (int) $requete->fetchColumn() > 0;
    }

    public static function idsParRoles(array $roles): array
    {
        $roles = array_values(array_unique(array_filter(array_map(
            static fn ($role): ?string => self::normaliser((string) $role),
            $roles
        ))));

        if ($roles === []) {
            return [];
        }

        $marqueurs = implode(',', array_fill(0, count($roles), '?'));
        $requete = BaseDeDonnees::connexion()->prepare(
            "SELECT id, nom_role FROM roles WHERE nom_role IN ($marqueurs)"
        );
        $requete->execute($roles);

        $ids = [];
        foreach ($requete->fetchAll() as $role) {
            $ids[$role['nom_role']] = (int) $role['id'];
        }

        return $ids;
    }

    public static function attacherAUtilisateur(int $utilisateurId, array $roles): void
    {
        $ids = self::idsParRoles($roles);

        if ($ids === []) {
            return;
        }

        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT IGNORE INTO utilisateur_roles (utilisateur_id, role_id)
             VALUES (:utilisateur_id, :role_id)'
        );

        foreach ($ids as $roleId) {
            $requete->execute([
                'utilisateur_id' => $utilisateurId,
                'role_id' => $roleId,
            ]);
        }
    }

    public static function rolesUtilisateur(int $utilisateurId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT r.id, r.nom_role
             FROM roles r
             INNER JOIN utilisateur_roles ur ON ur.role_id = r.id
             WHERE ur.utilisateur_id = :utilisateur_id
             ORDER BY r.nom_role ASC'
        );
        $requete->execute(['utilisateur_id' => $utilisateurId]);

        return $requete->fetchAll();
    }

    public static function nomsUtilisateur(int $utilisateurId): array
    {
        return array_map(
            static fn (array $role): string => (string) $role['nom_role'],
            self::rolesUtilisateur($utilisateurId)
        );
    }

    public static function rolesAAttribuer(string $roleDemande): array
    {
        $role = self::normaliser($roleDemande);
        $roles = [$role];

        if (in_array($role, ['doyen', 'vice_doyen'], true)) {
            $roles[] = 'enseignant';
        }

        return array_values(array_unique(array_filter($roles)));
    }
}
