<?php

declare(strict_types=1);

namespace Application\Modeles;

use Application\Noyau\BaseDeDonnees;

class DemandeInscription
{
    public static function creer(int $utilisateurId, string $typeDemande, ?string $message = null): int
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'INSERT INTO demandes_inscription (utilisateur_id, type_demande, statut, message)
             VALUES (:utilisateur_id, :type_demande, :statut, :message)'
        );
        $requete->execute([
            'utilisateur_id' => $utilisateurId,
            'type_demande' => Role::normaliser($typeDemande),
            'statut' => 'en_attente',
            'message' => $message,
        ]);

        return (int) BaseDeDonnees::connexion()->lastInsertId();
    }

    public static function toutes(?string $statut = null): array
    {
        $sql = 'SELECT di.*, u.nom, u.postnom, u.prenom, u.email, u.statut AS statut_compte,
                       approbateur.email AS email_approbateur
                FROM demandes_inscription di
                INNER JOIN utilisateurs u ON u.id = di.utilisateur_id
                LEFT JOIN utilisateurs approbateur ON approbateur.id = di.approuve_par';
        $parametres = [];

        if ($statut !== null && $statut !== '') {
            $sql .= ' WHERE di.statut = :statut';
            $parametres['statut'] = $statut;
        }

        $sql .= ' ORDER BY di.date_demande DESC';

        $requete = BaseDeDonnees::connexion()->prepare($sql);
        $requete->execute($parametres);

        return array_map([self::class, 'public'], $requete->fetchAll());
    }

    public static function trouver(int $id): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT di.*, u.nom, u.postnom, u.prenom, u.email, u.statut AS statut_compte
             FROM demandes_inscription di
             INNER JOIN utilisateurs u ON u.id = di.utilisateur_id
             WHERE di.id = :id
             LIMIT 1'
        );
        $requete->execute(['id' => $id]);
        $demande = $requete->fetch();

        return $demande ? self::public($demande) : null;
    }

    public static function trouverPourVerrouillage(int $id): ?array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT * FROM demandes_inscription WHERE id = :id LIMIT 1 FOR UPDATE'
        );
        $requete->execute(['id' => $id]);
        $demande = $requete->fetch();

        return $demande ?: null;
    }

    public static function marquerApprouvee(int $id, int $approbateurId): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE demandes_inscription
             SET statut = :statut,
                 approuve_par = :approuve_par,
                 date_traitement = NOW()
             WHERE id = :id'
        );
        $requete->execute([
            'id' => $id,
            'statut' => 'approuve',
            'approuve_par' => $approbateurId,
        ]);
    }

    public static function marquerRejetee(int $id, int $approbateurId, ?string $message): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'UPDATE demandes_inscription
             SET statut = :statut,
                 approuve_par = :approuve_par,
                 message = COALESCE(:message, message),
                 date_traitement = NOW()
             WHERE id = :id'
        );
        $requete->execute([
            'id' => $id,
            'statut' => 'rejete',
            'approuve_par' => $approbateurId,
            'message' => $message,
        ]);
    }

    private static function public(array $demande): array
    {
        foreach (['id', 'utilisateur_id', 'approuve_par'] as $champ) {
            if (array_key_exists($champ, $demande) && $demande[$champ] !== null) {
                $demande[$champ] = (int) $demande[$champ];
            }
        }

        return $demande;
    }
}
