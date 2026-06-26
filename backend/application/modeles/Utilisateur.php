<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class Utilisateur
{
    public static function trouver(int $id): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id, nom, postnom, prenom, email, mot_de_passe, statut, date_creation, date_modification
             FROM utilisateurs
             WHERE id = :id
             LIMIT 1'
        );
        $requete->execute(['id' => $id]);
        $utilisateur = $requete->fetch();

        return $utilisateur ?: null;
    }

    public static function trouverParEmail(string $email): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT id, nom, postnom, prenom, email, mot_de_passe, statut, date_creation, date_modification
             FROM utilisateurs
             WHERE email = :email
             LIMIT 1'
        );
        $requete->execute(['email' => strtolower(trim($email))]);
        $utilisateur = $requete->fetch();

        return $utilisateur ?: null;
    }

    public static function trouverAvecRoles(int $id): ?array
    {
        $utilisateur = self::trouver($id);

        if ($utilisateur === null) {
            return null;
        }

        return self::public($utilisateur, Role::rolesUtilisateur($id));
    }

    public static function tous(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT id, nom, postnom, prenom, email, statut, date_creation, date_modification
             FROM utilisateurs
             ORDER BY date_creation DESC'
        );

        return array_map(
            static fn (array $utilisateur): array => self::public($utilisateur, Role::rolesUtilisateur((int) $utilisateur['id'])),
            $requete->fetchAll()
        );
    }

    public static function creer(array $donnees): int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO utilisateurs (nom, postnom, prenom, email, mot_de_passe, statut)
             VALUES (:nom, :postnom, :prenom, :email, :mot_de_passe, :statut)'
        );

        $requete->execute([
            'nom' => nettoyer_chaine($donnees['nom'] ?? ''),
            'postnom' => nettoyer_chaine($donnees['postnom'] ?? ''),
            'prenom' => nettoyer_chaine($donnees['prenom'] ?? ''),
            'email' => strtolower(nettoyer_chaine($donnees['email'] ?? '')),
            'mot_de_passe' => (string) $donnees['mot_de_passe'],
            'statut' => (string) ($donnees['statut'] ?? 'en_attente'),
        ]);

        return (int) BaseDeDonnees::connexion()->lastInsertId();
    }

    public static function changerStatut(int $utilisateurId, string $statut): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE utilisateurs
             SET statut = :statut, date_modification = NOW()
             WHERE id = :id'
        );
        $requete->execute([
            'id' => $utilisateurId,
            'statut' => $statut,
        ]);
    }

    public static function public(array $utilisateur, array $roles): array
    {
        unset($utilisateur['mot_de_passe']);

        $utilisateur['id'] = (int) $utilisateur['id'];
        $utilisateur['roles'] = array_values($roles);
        $utilisateur['roles_codes'] = array_map(
            static fn (array $role): string => (string) $role['nom_role'],
            $roles
        );

        return $utilisateur;
    }
}
