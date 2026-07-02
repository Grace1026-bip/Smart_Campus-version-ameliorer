<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;

class EtudiantService
{
    public static function tableauDeBord(int $utilisateurId): array
    {
        $etudiantId = CoursService::etudiantId($utilisateurId);
        $profil = self::profil($etudiantId);
        $cours = CoursService::coursEtudiant($etudiantId);
        $resumeNotes = NoteService::resumeEtudiant($etudiantId);
        $reclamations = ReclamationService::reclamationsEtudiant($etudiantId);
        $alertes = AlerteAcademiqueService::alertesEtudiant($etudiantId);
        $publications = self::dernieresPublications($etudiantId, 5);
        $dernieresNotes = array_slice(NoteService::notesEtudiant($etudiantId), 0, 5);

        return [
            'profil' => $profil,
            'nombre_cours' => count($cours),
            'nombre_publications' => array_reduce(
                $cours,
                static fn (int $total, array $item): int => $total + (int) ($item['nombre_publications'] ?? 0),
                0
            ),
            'moyenne_generale' => $resumeNotes['moyenne_generale'],
            'credits_valides' => $resumeNotes['credits_valides'],
            'credits_restants' => $resumeNotes['credits_restants'],
            'notes_publiees' => $resumeNotes['notes_publiees'],
            'reclamations_en_cours' => count(array_filter(
                $reclamations,
                static fn (array $item): bool => in_array($item['statut'], ['en_attente', 'en_cours'], true)
            )),
            'nombre_alertes' => count($alertes),
            'dernieres_annonces' => $publications,
            'dernieres_notes' => $dernieresNotes,
            'alertes' => array_slice($alertes, 0, 5),
            'progression' => [
                'cours_total' => count($cours),
                'cours_echoues' => $resumeNotes['cours_echoues'],
                'credits_total_connus' => $resumeNotes['credits_valides'] + $resumeNotes['credits_restants'],
            ],
        ];
    }

    public static function profil(int $etudiantId): array
    {
        $photoSql = self::colonneExiste('utilisateurs', 'photo_url') ? 'u.photo_url' : 'NULL';
        $telephoneSql = self::colonneExiste('utilisateurs', 'telephone') ? 'u.telephone' : 'NULL';

        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.utilisateur_id, e.matricule, p.nom AS promotion, p.niveau,
                    aa.libelle AS annee_academique,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.nom, u.postnom, u.prenom, u.email, u.statut, u.date_creation AS date_inscription,
                    ' . $photoSql . ' AS photo_url,
                    ' . $telephoneSql . ' AS telephone
             FROM etudiants e
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN promotions p ON p.id = e.promotion_id
             LEFT JOIN annees_academiques aa ON aa.active = 1
             WHERE e.id = :etudiant_id
             LIMIT 1'
        );
        $requete->execute(['etudiant_id' => $etudiantId]);
        $profil = $requete->fetch() ?: [];

        if ($profil !== []) {
            $profil['id'] = (int) $profil['id'];
            $profil['utilisateur_id'] = (int) $profil['utilisateur_id'];
        }

        return $profil;
    }

    public static function modifierProfil(int $etudiantId, array $donnees): array
    {
        $profil = self::profil($etudiantId);

        if ($profil === []) {
            throw new ExceptionHttp('Profil etudiant introuvable.', 404);
        }

        $champs = [];
        $parametres = ['utilisateur_id' => (int) $profil['utilisateur_id']];

        foreach (['nom', 'postnom', 'prenom'] as $champ) {
            if (array_key_exists($champ, $donnees)) {
                $champs[] = $champ . ' = :' . $champ;
                $parametres[$champ] = nettoyer_chaine($donnees[$champ]);
            }
        }

        if (array_key_exists('email', $donnees)) {
            $email = strtolower(nettoyer_chaine($donnees['email']));
            if ($email === '' || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
                throw new ExceptionHttp('Adresse email invalide.', 422);
            }

            self::verifierEmailDisponible($email, (int) $profil['utilisateur_id']);
            $champs[] = 'email = :email';
            $parametres['email'] = $email;
        }

        if (self::colonneExiste('utilisateurs', 'photo_url') && array_key_exists('photo_url', $donnees)) {
            $photoUrl = nettoyer_chaine($donnees['photo_url']);
            $champs[] = 'photo_url = :photo_url';
            $parametres['photo_url'] = $photoUrl === '' ? null : $photoUrl;
        }

        if (self::colonneExiste('utilisateurs', 'telephone') && array_key_exists('telephone', $donnees)) {
            $telephone = nettoyer_chaine($donnees['telephone']);
            $champs[] = 'telephone = :telephone';
            $parametres['telephone'] = $telephone === '' ? null : $telephone;
        }

        if ($champs !== []) {
            $requete = BaseDeDonnees::connexion()->prepare(
                'UPDATE utilisateurs SET ' . implode(', ', $champs) . ' WHERE id = :utilisateur_id'
            );
            $requete->execute($parametres);
        }

        return self::profil($etudiantId);
    }

    public static function dernieresPublications(int $etudiantId, int $limite): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT pv.id, pv.cours_id, pv.type_publication, pv.titre, pv.contenu, pv.date_publication,
                    c.code AS code_cours, c.nom AS cours,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
             FROM inscriptions_cours ic
             INNER JOIN publications_valve pv ON pv.cours_id = ic.cours_id
             INNER JOIN cours c ON c.id = pv.cours_id
             INNER JOIN enseignants e ON e.id = pv.enseignant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             WHERE ic.etudiant_id = :etudiant_id
               AND pv.statut IN ("publie", "verrouille")
               AND pv.visibilite IN ("etudiants", "tous")
             ORDER BY pv.date_publication DESC
             LIMIT ' . (int) $limite
        );
        $requete->execute(['etudiant_id' => $etudiantId]);

        return $requete->fetchAll();
    }

    private static function verifierEmailDisponible(string $email, int $utilisateurId): void
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*) FROM utilisateurs WHERE email = :email AND id <> :utilisateur_id'
        );
        $requete->execute(['email' => $email, 'utilisateur_id' => $utilisateurId]);

        if ((int) $requete->fetchColumn() > 0) {
            throw new ExceptionHttp('Cette adresse email est deja utilisee.', 409);
        }
    }

    private static function colonneExiste(string $table, string $colonne): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*)
             FROM INFORMATION_SCHEMA.COLUMNS
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = :table
               AND COLUMN_NAME = :colonne'
        );
        $requete->execute(['table' => $table, 'colonne' => $colonne]);

        return (int) $requete->fetchColumn() > 0;
    }
}
