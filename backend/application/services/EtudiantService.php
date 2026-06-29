<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;

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

        return [
            'profil' => $profil,
            'nombre_cours' => count($cours),
            'moyenne_generale' => $resumeNotes['moyenne_generale'],
            'credits_valides' => $resumeNotes['credits_valides'],
            'credits_restants' => $resumeNotes['credits_restants'],
            'notes_publiees' => $resumeNotes['notes_publiees'],
            'reclamations_en_cours' => count(array_filter(
                $reclamations,
                static fn (array $item): bool => in_array($item['statut'], ['en_attente', 'en_cours'], true)
            )),
            'dernieres_annonces' => $publications,
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
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.matricule, p.nom AS promotion, p.niveau,
                    aa.libelle AS annee_academique,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email, u.statut
             FROM etudiants e
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             INNER JOIN promotions p ON p.id = e.promotion_id
             LEFT JOIN annees_academiques aa ON aa.active = 1
             WHERE e.id = :etudiant_id
             LIMIT 1'
        );
        $requete->execute(['etudiant_id' => $etudiantId]);
        $profil = $requete->fetch() ?: [];

        if ($profil !== []) {
            $profil['id'] = (int) $profil['id'];
        }

        return $profil;
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
}
