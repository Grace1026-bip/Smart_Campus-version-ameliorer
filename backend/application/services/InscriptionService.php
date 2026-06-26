<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Modeles\DemandeInscription;
use Application\Modeles\Enseignant;
use Application\Modeles\Etudiant;
use Application\Modeles\Role;
use Application\Modeles\Utilisateur;
use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;
use PDO;
use Throwable;

class InscriptionService
{
    public static function inscrireEtudiant(array $donnees): array
    {
        $erreurs = champs_obligatoires($donnees, [
            'nom',
            'postnom',
            'prenom',
            'email',
            'matricule',
            'mot_de_passe',
        ]);

        if (empty($donnees['promotion_id']) && empty($donnees['promotion'])) {
            $erreurs['promotion'] = 'Promotion obligatoire.';
        }

        self::validerCommun($donnees, $erreurs);

        if ($erreurs !== []) {
            throw new ExceptionHttp('Validation echouee.', 422, $erreurs);
        }

        return self::creerDemande($donnees, 'etudiant');
    }

    public static function inscrireEnseignant(array $donnees): array
    {
        $erreurs = champs_obligatoires($donnees, [
            'nom',
            'postnom',
            'prenom',
            'email',
            'mot_de_passe',
        ]);

        if (empty($donnees['departement_id']) && empty($donnees['cours'])) {
            $erreurs['enseignant'] = 'Departement ou cours obligatoire.';
        }

        self::validerCommun($donnees, $erreurs);

        if ($erreurs !== []) {
            throw new ExceptionHttp('Validation echouee.', 422, $erreurs);
        }

        return self::creerDemande($donnees, 'enseignant');
    }

    public static function demandes(?string $statut = null): array
    {
        return DemandeInscription::toutes($statut);
    }

    public static function approuver(int $demandeId, int $approbateurId, array $rolesApprobateur): array
    {
        return BaseDeDonnees::transaction(function (PDO $pdo) use ($demandeId, $approbateurId, $rolesApprobateur): array {
            $demande = DemandeInscription::trouverPourVerrouillage($demandeId);

            if ($demande === null) {
                throw new ExceptionHttp('Demande introuvable.', 404);
            }

            if ($demande['statut'] !== 'en_attente') {
                throw new ExceptionHttp('Cette demande a deja ete traitee.', 409);
            }

            if (!PermissionService::peutApprouver((string) $demande['type_demande'], $rolesApprobateur)) {
                throw new ExceptionHttp('Role non autorise pour approuver cette demande.', 403);
            }

            Utilisateur::changerStatut((int) $demande['utilisateur_id'], 'approuve');
            DemandeInscription::marquerApprouvee($demandeId, $approbateurId);

            return [
                'demande' => DemandeInscription::trouver($demandeId),
                'utilisateur' => Utilisateur::trouverAvecRoles((int) $demande['utilisateur_id']),
            ];
        });
    }

    public static function rejeter(int $demandeId, int $approbateurId, array $rolesApprobateur, ?string $message): array
    {
        return BaseDeDonnees::transaction(function (PDO $pdo) use ($demandeId, $approbateurId, $rolesApprobateur, $message): array {
            $demande = DemandeInscription::trouverPourVerrouillage($demandeId);

            if ($demande === null) {
                throw new ExceptionHttp('Demande introuvable.', 404);
            }

            if ($demande['statut'] !== 'en_attente') {
                throw new ExceptionHttp('Cette demande a deja ete traitee.', 409);
            }

            if (!PermissionService::peutApprouver((string) $demande['type_demande'], $rolesApprobateur)) {
                throw new ExceptionHttp('Role non autorise pour rejeter cette demande.', 403);
            }

            Utilisateur::changerStatut((int) $demande['utilisateur_id'], 'rejete');
            DemandeInscription::marquerRejetee($demandeId, $approbateurId, $message);

            return [
                'demande' => DemandeInscription::trouver($demandeId),
                'utilisateur' => Utilisateur::trouverAvecRoles((int) $demande['utilisateur_id']),
            ];
        });
    }

    private static function creerDemande(array $donnees, string $type): array
    {
        try {
            return BaseDeDonnees::transaction(function (PDO $pdo) use ($donnees, $type): array {
                if (Utilisateur::trouverParEmail((string) $donnees['email']) !== null) {
                    throw new ExceptionHttp('Un compte existe deja avec cet email.', 409);
                }

                $utilisateurId = Utilisateur::creer([
                    'nom' => $donnees['nom'],
                    'postnom' => $donnees['postnom'],
                    'prenom' => $donnees['prenom'],
                    'email' => $donnees['email'],
                    'mot_de_passe' => password_hash((string) $donnees['mot_de_passe'], PASSWORD_DEFAULT),
                    'statut' => 'en_attente',
                ]);

                Role::attacherAUtilisateur($utilisateurId, Role::rolesAAttribuer($type));

                if ($type === 'etudiant') {
                    Etudiant::creerProfil($utilisateurId, $donnees);
                }

                if ($type === 'enseignant') {
                    Enseignant::creerProfil($utilisateurId, $donnees);
                }

                $demandeId = DemandeInscription::creer(
                    $utilisateurId,
                    $type,
                    isset($donnees['message']) ? nettoyer_chaine($donnees['message']) : null
                );

                return [
                    'demande' => DemandeInscription::trouver($demandeId),
                    'utilisateur' => Utilisateur::trouverAvecRoles($utilisateurId),
                ];
            });
        } catch (ExceptionHttp $exception) {
            throw $exception;
        } catch (Throwable) {
            throw new ExceptionHttp('Impossible de creer la demande.', 500);
        }
    }

    private static function validerCommun(array $donnees, array &$erreurs): void
    {
        if (!empty($donnees['email']) && !email_valide((string) $donnees['email'])) {
            $erreurs['email'] = 'Email invalide.';
        }

        if (!empty($donnees['mot_de_passe']) && !mot_de_passe_valide((string) $donnees['mot_de_passe'])) {
            $erreurs['mot_de_passe'] = 'Le mot de passe doit contenir au moins 8 caracteres.';
        }
    }
}
