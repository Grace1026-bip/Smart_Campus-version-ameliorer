<?php

declare(strict_types=1);

namespace Application\Services;

use Application\Noyau\BaseDeDonnees;
use Application\Noyau\ExceptionHttp;
use PDO;

class AppariteurService
{
    private const STATUTS_RECLAMATION = ['en_attente', 'en_cours', 'resolue', 'rejetee', 'transmise', 'transmise_apparitorat'];

    public static function tableauDeBord(): array
    {
        $etudiants = self::compter('etudiants');
        $enseignants = self::compter('enseignants');
        $promotions = self::compter('promotions');
        $cours = self::compter('cours');
        $reclamationsOuvertes = self::compterReclamationsOuvertes();
        $risques = count(self::risques());
        $projets = self::projets();
        $stages = self::stages();
        $notesNonPubliees = self::notesNonPubliees();

        return [
            'nombre_etudiants' => $etudiants,
            'nombre_enseignants' => $enseignants,
            'nombre_promotions' => $promotions,
            'nombre_cours' => $cours,
            'reclamations_ouvertes' => $reclamationsOuvertes,
            'etudiants_a_risque' => $risques,
            'projets_actifs' => count(array_filter($projets, static fn (array $item): bool => ($item['statut'] ?? '') !== 'termine')),
            'stages_actifs' => count(array_filter($stages, static fn (array $item): bool => ($item['statut'] ?? '') !== 'termine')),
            'notes_non_publiees' => $notesNonPubliees,
            'dernieres_activites' => self::dernieresActivites(),
            'alertes_importantes' => self::alertesImportantes($reclamationsOuvertes, $risques, $notesNonPubliees),
            'indicateurs' => [
                'taux_reclamations_ouvertes' => self::pourcentage($reclamationsOuvertes, max(1, self::compter('reclamations'))),
                'taux_cours_publies' => self::pourcentage(self::compterCoursPublies(), max(1, $cours)),
                'taux_etudiants_risque' => self::pourcentage($risques, max(1, $etudiants)),
            ],
            'graphiques' => [
                'risques_par_promotion' => self::risquesParPromotion(),
                'cours_par_promotion' => self::coursParPromotion(),
            ],
        ];
    }

    public static function etudiants(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT e.id, e.utilisateur_id, e.matricule,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email, u.statut,
                    p.id AS promotion_id, p.nom AS promotion, p.niveau,
                    (
                        SELECT ROUND(AVG(n.valeur), 2)
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        WHERE n.etudiant_id = e.id AND n.statut = "publie"
                    ) AS moyenne_generale,
                    (
                        SELECT COALESCE(SUM(c.credits), 0)
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        INNER JOIN cours c ON c.id = n.cours_id
                        WHERE n.etudiant_id = e.id AND n.statut = "publie" AND n.valeur >= 10
                    ) AS credits_valides,
                    (
                        SELECT COUNT(*) FROM inscriptions_cours ic WHERE ic.etudiant_id = e.id
                    ) AS nombre_cours,
                    (
                        SELECT COUNT(*) FROM reclamations r WHERE r.etudiant_id = e.id
                    ) AS nombre_reclamations,
                    (
                        SELECT COUNT(*) FROM alertes_academiques aa WHERE aa.etudiant_id = e.id AND aa.lue = 0
                    ) AS alertes_actives
             FROM etudiants e
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN promotions p ON p.id = e.promotion_id
             ORDER BY p.nom ASC, u.nom ASC, u.prenom ASC'
        );

        return array_map([self::class, 'formaterEtudiant'], $requete->fetchAll());
    }

    public static function enseignants(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT e.id, e.utilisateur_id,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email, u.statut,
                    d.nom AS departement,
                    e.cours AS specialites,
                    (
                        SELECT COUNT(DISTINCT ce.cours_id)
                        FROM cours_enseignants ce
                        WHERE ce.enseignant_id = e.id
                    ) AS nombre_cours,
                    (
                        SELECT COUNT(*)
                        FROM publications_valve pv
                        WHERE pv.enseignant_id = e.id
                    ) AS nombre_publications,
                    (
                        SELECT COUNT(DISTINCT r.id)
                        FROM reclamations r
                        INNER JOIN cours_enseignants ce ON ce.cours_id = r.cours_id
                        WHERE ce.enseignant_id = e.id
                    ) AS nombre_reclamations
             FROM enseignants e
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN departements d ON d.id = e.departement_id
             ORDER BY u.nom ASC, u.prenom ASC'
        );

        return array_map([self::class, 'formaterEnseignant'], $requete->fetchAll());
    }

    public static function promotions(): array
    {
        $requete = BaseDeDonnees::connexion()->query(self::promotionsSql() . ' ORDER BY p.nom ASC');

        return array_map([self::class, 'formaterPromotion'], $requete->fetchAll());
    }

    public static function promotion(int $promotionId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(self::promotionsSql('p.id = :id') . ' LIMIT 1');
        $requete->execute(['id' => $promotionId]);
        $promotion = $requete->fetch();

        if (!$promotion) {
            throw new ExceptionHttp('Promotion introuvable.', 404);
        }

        $promotion = self::formaterPromotion($promotion);
        $promotion['etudiants'] = array_values(array_filter(
            self::etudiants(),
            static fn (array $etudiant): bool => (int) ($etudiant['promotion_id'] ?? 0) === $promotionId
        ));
        $promotion['cours'] = array_values(array_filter(
            self::cours(),
            static fn (array $cours): bool => (int) ($cours['promotion_id'] ?? 0) === $promotionId
        ));
        $promotion['risques'] = array_values(array_filter(
            self::risques(),
            static fn (array $risque): bool => (int) ($risque['promotion_id'] ?? 0) === $promotionId
        ));
        $promotion['reclamations'] = array_values(array_filter(
            self::reclamations(),
            static fn (array $reclamation): bool => (int) ($reclamation['promotion_id'] ?? 0) === $promotionId
        ));

        return $promotion;
    }

    public static function cours(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT c.id, c.code, c.nom, c.description, c.nombre_heures, c.credits,
                    c.objectifs, c.modalites_evaluation, c.statut_notes,
                    p.id AS promotion_id, p.nom AS promotion, p.niveau,
                    s.nom AS semestre, aa.libelle AS annee_academique,
                    (
                        SELECT CONCAT_WS(" ", u.nom, u.postnom, u.prenom)
                        FROM cours_enseignants ce
                        INNER JOIN enseignants e ON e.id = ce.enseignant_id
                        INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                        WHERE ce.cours_id = c.id AND ce.role_enseignement = "principal"
                        LIMIT 1
                    ) AS enseignant_principal,
                    (
                        SELECT GROUP_CONCAT(CONCAT_WS(" ", u.nom, u.postnom, u.prenom) SEPARATOR "||")
                        FROM cours_enseignants ce
                        INNER JOIN enseignants e ON e.id = ce.enseignant_id
                        INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
                        WHERE ce.cours_id = c.id AND ce.role_enseignement = "assistant"
                    ) AS assistants,
                    (
                        SELECT COUNT(*) FROM inscriptions_cours ic WHERE ic.cours_id = c.id
                    ) AS nombre_etudiants,
                    (
                        SELECT ROUND(AVG(n.valeur), 2)
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        WHERE n.cours_id = c.id AND n.statut = "publie"
                    ) AS moyenne_cours,
                    (
                        SELECT COUNT(*)
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        WHERE n.cours_id = c.id AND n.statut = "publie" AND n.valeur < 12
                    ) AS etudiants_a_risque
             FROM cours c
             INNER JOIN promotions p ON p.id = c.promotion_id
             INNER JOIN semestres s ON s.id = c.semestre_id
             INNER JOIN annees_academiques aa ON aa.id = s.annee_academique_id
             ORDER BY p.nom ASC, s.ordre ASC, c.nom ASC'
        );

        return array_map([self::class, 'formaterCours'], $requete->fetchAll());
    }

    public static function detailCours(int $coursId): array
    {
        $cours = CoursService::detailCours($coursId);
        $cours['etudiants'] = self::etudiantsCours($coursId);
        $cours['reclamations'] = array_values(array_filter(
            self::reclamations(),
            static fn (array $reclamation): bool => (int) ($reclamation['cours_id'] ?? 0) === $coursId
        ));
        $cours['risques'] = array_values(array_filter(
            self::risques(),
            static fn (array $risque): bool => (int) ($risque['cours_id'] ?? 0) === $coursId
        ));

        return $cours;
    }

    public static function etudiantsCours(int $coursId): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT e.id, e.matricule,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS nom_complet,
                    u.email, p.nom AS promotion,
                    (
                        SELECT n.valeur
                        FROM notes n
                        INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
                        WHERE n.etudiant_id = e.id AND n.cours_id = :cours_id_moyenne
                        LIMIT 1
                    ) AS moyenne
             FROM inscriptions_cours ic
             INNER JOIN etudiants e ON e.id = ic.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             INNER JOIN promotions p ON p.id = e.promotion_id
             WHERE ic.cours_id = :cours_id
             ORDER BY u.nom ASC, u.prenom ASC'
        );
        $requete->execute([
            'cours_id' => $coursId,
            'cours_id_moyenne' => $coursId,
        ]);

        return array_map(static function (array $etudiant): array {
            $etudiant['id'] = (int) $etudiant['id'];
            $etudiant['moyenne'] = $etudiant['moyenne'] === null ? null : (float) $etudiant['moyenne'];

            return $etudiant;
        }, $requete->fetchAll());
    }

    public static function reclamations(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT r.*, c.code AS code_cours, c.nom AS cours,
                    p.id AS promotion_id, p.nom AS promotion,
                    n.valeur AS note_concernee,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant,
                    e.matricule,
                    (
                        SELECT CONCAT_WS(" ", up.nom, up.postnom, up.prenom)
                        FROM cours_enseignants ce
                        INNER JOIN enseignants ens ON ens.id = ce.enseignant_id
                        INNER JOIN utilisateurs up ON up.id = ens.utilisateur_id
                        WHERE ce.cours_id = r.cours_id AND ce.role_enseignement = "principal"
                        LIMIT 1
                    ) AS enseignant
             FROM reclamations r
             INNER JOIN etudiants e ON e.id = r.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN cours c ON c.id = r.cours_id
             LEFT JOIN promotions p ON p.id = c.promotion_id
             LEFT JOIN notes n ON n.id = r.note_id
             ORDER BY r.date_creation DESC'
        );

        return array_map([self::class, 'formaterReclamation'], $requete->fetchAll());
    }

    public static function detailReclamation(int $id): array
    {
        $reclamations = array_values(array_filter(
            self::reclamations(),
            static fn (array $reclamation): bool => (int) $reclamation['id'] === $id
        ));

        if ($reclamations === []) {
            throw new ExceptionHttp('Reclamation introuvable.', 404);
        }

        $reclamation = $reclamations[0];
        $reclamation['reponses'] = self::reponsesReclamation($id);

        return $reclamation;
    }

    public static function changerStatutReclamation(int $utilisateurId, int $id, array $donnees): array
    {
        $statut = (string) ($donnees['statut'] ?? '');
        if ($statut === 'transmise') {
            $statut = 'transmise_apparitorat';
        }

        if (!in_array($statut, self::STATUTS_RECLAMATION, true)) {
            throw new ExceptionHttp('Statut de reclamation invalide.', 422);
        }

        self::detailReclamation($id);

        BaseDeDonnees::transaction(function (PDO $pdo) use ($utilisateurId, $id, $donnees, $statut): void {
            $miseAJour = $pdo->prepare('UPDATE reclamations SET statut = :statut WHERE id = :id');
            $miseAJour->execute(['statut' => $statut, 'id' => $id]);

            $message = nettoyer_chaine($donnees['message'] ?? '');
            if ($message !== '') {
                $reponse = $pdo->prepare(
                    'INSERT INTO reponses_reclamations (reclamation_id, utilisateur_id, message)
                     VALUES (:reclamation_id, :utilisateur_id, :message)'
                );
                $reponse->execute([
                    'reclamation_id' => $id,
                    'utilisateur_id' => $utilisateurId,
                    'message' => $message,
                ]);
            }
        });

        return self::detailReclamation($id);
    }

    public static function risques(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT e.id AS etudiant_id, e.matricule,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant,
                    p.id AS promotion_id, p.nom AS promotion,
                    c.id AS cours_id, c.code AS code_cours, c.nom AS cours,
                    n.valeur AS moyenne,
                    CASE
                        WHEN n.valeur < 10 THEN "eleve"
                        WHEN n.valeur < 12 THEN "moyen"
                        ELSE "faible"
                    END AS niveau,
                    CASE
                        WHEN n.valeur < 10 THEN "Moyenne inferieure au seuil de reussite"
                        ELSE "Moyenne proche du seuil de reussite"
                    END AS motif
             FROM notes n
             INNER JOIN types_notes tn ON tn.id = n.type_note_id AND tn.code = "moyenne_finale"
             INNER JOIN etudiants e ON e.id = n.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             INNER JOIN cours c ON c.id = n.cours_id
             INNER JOIN promotions p ON p.id = c.promotion_id
             WHERE n.statut = "publie" AND n.valeur < 12
             ORDER BY n.valeur ASC, p.nom ASC, u.nom ASC'
        );

        return array_map([self::class, 'formaterRisque'], $requete->fetchAll());
    }

    public static function projets(): array
    {
        if (!self::tableExiste('projets_academiques')) {
            return [];
        }

        $requete = BaseDeDonnees::connexion()->query(
            'SELECT pa.*, p.nom AS promotion, CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS encadreur
             FROM projets_academiques pa
             LEFT JOIN promotions p ON p.id = pa.promotion_id
             LEFT JOIN enseignants e ON e.id = pa.encadreur_id
             LEFT JOIN utilisateurs u ON u.id = e.utilisateur_id
             ORDER BY pa.date_echeance ASC, pa.titre ASC'
        );

        return array_map([self::class, 'normaliserProjet'], $requete->fetchAll());
    }

    public static function stages(): array
    {
        if (!self::tableExiste('stages')) {
            return [];
        }

        $requete = BaseDeDonnees::connexion()->query(
            'SELECT s.*, e.matricule, p.nom AS promotion,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS etudiant
             FROM stages s
             INNER JOIN etudiants e ON e.id = s.etudiant_id
             INNER JOIN utilisateurs u ON u.id = e.utilisateur_id
             LEFT JOIN promotions p ON p.id = e.promotion_id
             ORDER BY s.date_fin ASC, u.nom ASC'
        );

        return array_map([self::class, 'normaliserStage'], $requete->fetchAll());
    }

    public static function assistant(): array
    {
        $dashboard = self::tableauDeBord();
        $risquesEleves = count(array_filter(
            self::risques(),
            static fn (array $risque): bool => ($risque['niveau'] ?? '') === 'eleve'
        ));
        $projetsEnRetard = count(array_filter(
            self::projets(),
            static fn (array $projet): bool => ($projet['en_retard'] ?? false) === true
        ));
        $stagesEnRetard = count(array_filter(
            self::stages(),
            static fn (array $stage): bool => ($stage['en_retard'] ?? false) === true
        ));

        return [
            'priorites' => [
                [
                    'titre' => 'Reclamations en attente',
                    'detail' => $dashboard['reclamations_ouvertes'] . ' reclamation(s) sont ouvertes.',
                    'valeur' => $dashboard['reclamations_ouvertes'],
                    'niveau' => $dashboard['reclamations_ouvertes'] > 0 ? 'attention' : 'info',
                ],
                [
                    'titre' => 'Notes non publiees',
                    'detail' => $dashboard['notes_non_publiees'] . ' cours ont des notes non publiees.',
                    'valeur' => $dashboard['notes_non_publiees'],
                    'niveau' => $dashboard['notes_non_publiees'] > 0 ? 'attention' : 'info',
                ],
                [
                    'titre' => 'Etudiants a risque eleve',
                    'detail' => $risquesEleves . ' etudiant(s) sont en risque eleve.',
                    'valeur' => $risquesEleves,
                    'niveau' => $risquesEleves > 0 ? 'danger' : 'info',
                ],
                [
                    'titre' => 'Projets en retard',
                    'detail' => $projetsEnRetard . ' projet(s) sont en retard.',
                    'valeur' => $projetsEnRetard,
                    'niveau' => $projetsEnRetard > 0 ? 'attention' : 'info',
                ],
                [
                    'titre' => 'Stages en retard',
                    'detail' => $stagesEnRetard . ' stage(s) sont en retard.',
                    'valeur' => $stagesEnRetard,
                    'niveau' => $stagesEnRetard > 0 ? 'attention' : 'info',
                ],
            ],
            'actions' => self::actionsAssistant($dashboard, $risquesEleves, $projetsEnRetard, $stagesEnRetard),
        ];
    }

    public static function rapports(): array
    {
        $dashboard = self::tableauDeBord();

        return [
            'rapports' => [
                ['code' => 'etudiants', 'titre' => 'Rapport etudiants', 'description' => $dashboard['nombre_etudiants'] . ' etudiant(s) suivis.'],
                ['code' => 'enseignants', 'titre' => 'Rapport enseignants', 'description' => $dashboard['nombre_enseignants'] . ' enseignant(s) suivis.'],
                ['code' => 'promotions', 'titre' => 'Rapport promotions', 'description' => $dashboard['nombre_promotions'] . ' promotion(s).'],
                ['code' => 'cours', 'titre' => 'Rapport cours', 'description' => $dashboard['nombre_cours'] . ' cours.'],
                ['code' => 'reclamations', 'titre' => 'Rapport reclamations', 'description' => $dashboard['reclamations_ouvertes'] . ' reclamation(s) ouvertes.'],
                ['code' => 'risques', 'titre' => 'Rapport risques academiques', 'description' => $dashboard['etudiants_a_risque'] . ' risque(s).'],
            ],
            'exports_prevus' => ['pdf', 'excel'],
        ];
    }

    private static function promotionsSql(string $where = ''): string
    {
        $filtre = $where === '' ? '' : ' WHERE ' . $where;

        return 'SELECT p.id, p.nom, p.niveau,
                       COUNT(DISTINCT e.id) AS effectif,
                       COUNT(DISTINCT c.id) AS nombre_cours,
                       COUNT(DISTINCT ce.enseignant_id) AS nombre_enseignants,
                       ROUND(AVG(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" THEN n.valeur END), 2) AS moyenne_generale,
                       SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur >= 10 THEN 1 ELSE 0 END) AS reussites,
                       SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur < 10 THEN 1 ELSE 0 END) AS echecs,
                       SUM(CASE WHEN tn.code = "moyenne_finale" AND n.statut = "publie" AND n.valeur < 12 THEN 1 ELSE 0 END) AS etudiants_a_risque
                FROM promotions p
                LEFT JOIN etudiants e ON e.promotion_id = p.id
                LEFT JOIN cours c ON c.promotion_id = p.id
                LEFT JOIN cours_enseignants ce ON ce.cours_id = c.id
                LEFT JOIN notes n ON n.etudiant_id = e.id AND n.cours_id = c.id
                LEFT JOIN types_notes tn ON tn.id = n.type_note_id
                ' . $filtre . '
                GROUP BY p.id, p.nom, p.niveau';
    }

    private static function dernieresActivites(): array
    {
        $activites = [];

        foreach (array_slice(self::reclamations(), 0, 4) as $reclamation) {
            $activites[] = [
                'type' => 'reclamation',
                'titre' => $reclamation['titre'] ?? 'Reclamation',
                'detail' => ($reclamation['etudiant'] ?? '-') . ' - ' . ($reclamation['statut'] ?? '-'),
                'date' => $reclamation['date_creation'] ?? null,
            ];
        }

        $requete = BaseDeDonnees::connexion()->query(
            'SELECT pv.titre, pv.date_publication, c.code AS code_cours
             FROM publications_valve pv
             INNER JOIN cours c ON c.id = pv.cours_id
             ORDER BY pv.date_publication DESC
             LIMIT 4'
        );
        foreach ($requete->fetchAll() as $publication) {
            $activites[] = [
                'type' => 'publication',
                'titre' => $publication['titre'] ?? 'Publication',
                'detail' => ($publication['code_cours'] ?? '-') . ' - valve',
                'date' => $publication['date_publication'] ?? null,
            ];
        }

        usort($activites, static fn (array $a, array $b): int => strcmp((string) ($b['date'] ?? ''), (string) ($a['date'] ?? '')));

        return array_slice($activites, 0, 8);
    }

    private static function alertesImportantes(int $reclamationsOuvertes, int $risques, int $notesNonPubliees): array
    {
        $alertes = [];

        if ($reclamationsOuvertes > 0) {
            $alertes[] = ['niveau' => 'attention', 'message' => $reclamationsOuvertes . ' reclamation(s) ouvertes necessitent un suivi.'];
        }
        if ($risques > 0) {
            $alertes[] = ['niveau' => 'danger', 'message' => $risques . ' etudiant(s) sont a risque academique.'];
        }
        if ($notesNonPubliees > 0) {
            $alertes[] = ['niveau' => 'attention', 'message' => $notesNonPubliees . ' cours n ont pas encore publie les notes.'];
        }

        return $alertes;
    }

    private static function actionsAssistant(array $dashboard, int $risquesEleves, int $projetsEnRetard, int $stagesEnRetard): array
    {
        $actions = [];

        if ($dashboard['reclamations_ouvertes'] > 0) {
            $actions[] = 'Verifier et orienter les reclamations en attente.';
        }
        if ($dashboard['notes_non_publiees'] > 0) {
            $actions[] = 'Relancer les enseignants dont les notes ne sont pas publiees.';
        }
        if ($risquesEleves > 0) {
            $actions[] = 'Generer la liste des etudiants a risque eleve.';
        }
        if ($projetsEnRetard > 0) {
            $actions[] = 'Suivre les projets en retard avec les encadreurs.';
        }
        if ($stagesEnRetard > 0) {
            $actions[] = 'Verifier les rapports de stage en retard.';
        }

        return $actions;
    }

    private static function reponsesReclamation(int $id): array
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT rr.id, rr.message, rr.date_reponse,
                    CONCAT_WS(" ", u.nom, u.postnom, u.prenom) AS auteur
             FROM reponses_reclamations rr
             INNER JOIN utilisateurs u ON u.id = rr.utilisateur_id
             WHERE rr.reclamation_id = :id
             ORDER BY rr.date_reponse ASC'
        );
        $requete->execute(['id' => $id]);

        return $requete->fetchAll();
    }

    private static function risquesParPromotion(): array
    {
        $groupes = [];
        foreach (self::risques() as $risque) {
            $promotion = (string) ($risque['promotion'] ?? '-');
            $groupes[$promotion] = ($groupes[$promotion] ?? 0) + 1;
        }

        return array_map(
            static fn (string $label, int $valeur): array => ['label' => $label, 'value' => $valeur],
            array_keys($groupes),
            array_values($groupes)
        );
    }

    private static function coursParPromotion(): array
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT p.nom AS label, COUNT(c.id) AS value
             FROM promotions p
             LEFT JOIN cours c ON c.promotion_id = p.id
             GROUP BY p.id, p.nom
             ORDER BY p.nom ASC'
        );

        return array_map(static fn (array $ligne): array => [
            'label' => $ligne['label'],
            'value' => (int) $ligne['value'],
        ], $requete->fetchAll());
    }

    private static function notesNonPubliees(): int
    {
        $requete = BaseDeDonnees::connexion()->query('SELECT COUNT(*) FROM cours WHERE statut_notes <> "publiees"');

        return (int) $requete->fetchColumn();
    }

    private static function compterCoursPublies(): int
    {
        $requete = BaseDeDonnees::connexion()->query('SELECT COUNT(*) FROM cours WHERE statut_notes = "publiees"');

        return (int) $requete->fetchColumn();
    }

    private static function compterReclamationsOuvertes(): int
    {
        $requete = BaseDeDonnees::connexion()->query(
            'SELECT COUNT(*) FROM reclamations WHERE statut IN ("en_attente", "en_cours", "transmise", "transmise_apparitorat")'
        );

        return (int) $requete->fetchColumn();
    }

    private static function compter(string $table): int
    {
        $requete = BaseDeDonnees::connexion()->query('SELECT COUNT(*) FROM ' . $table);

        return (int) $requete->fetchColumn();
    }

    private static function pourcentage(int|float $valeur, int|float $total): float
    {
        if ($total <= 0) {
            return 0.0;
        }

        return round(((float) $valeur / (float) $total) * 100, 2);
    }

    private static function tableExiste(string $table): bool
    {
        $requete = BaseDeDonnees::connexion()->prepare(
            'SELECT COUNT(*)
             FROM INFORMATION_SCHEMA.TABLES
             WHERE TABLE_SCHEMA = DATABASE()
               AND TABLE_NAME = :table'
        );
        $requete->execute(['table' => $table]);

        return (int) $requete->fetchColumn() > 0;
    }

    private static function formaterEtudiant(array $etudiant): array
    {
        $etudiant['id'] = (int) $etudiant['id'];
        $etudiant['utilisateur_id'] = (int) $etudiant['utilisateur_id'];
        $etudiant['promotion_id'] = $etudiant['promotion_id'] === null ? null : (int) $etudiant['promotion_id'];
        $etudiant['moyenne_generale'] = $etudiant['moyenne_generale'] === null ? null : (float) $etudiant['moyenne_generale'];
        $etudiant['credits_valides'] = (int) $etudiant['credits_valides'];
        $etudiant['nombre_cours'] = (int) $etudiant['nombre_cours'];
        $etudiant['nombre_reclamations'] = (int) $etudiant['nombre_reclamations'];
        $etudiant['alertes_actives'] = (int) $etudiant['alertes_actives'];

        return $etudiant;
    }

    private static function formaterEnseignant(array $enseignant): array
    {
        $enseignant['id'] = (int) $enseignant['id'];
        $enseignant['utilisateur_id'] = (int) $enseignant['utilisateur_id'];
        $enseignant['nombre_cours'] = (int) $enseignant['nombre_cours'];
        $enseignant['nombre_publications'] = (int) $enseignant['nombre_publications'];
        $enseignant['nombre_reclamations'] = (int) $enseignant['nombre_reclamations'];

        return $enseignant;
    }

    private static function formaterPromotion(array $promotion): array
    {
        $promotion['id'] = (int) $promotion['id'];
        $promotion['effectif'] = (int) $promotion['effectif'];
        $promotion['nombre_cours'] = (int) $promotion['nombre_cours'];
        $promotion['nombre_enseignants'] = (int) $promotion['nombre_enseignants'];
        $promotion['moyenne_generale'] = $promotion['moyenne_generale'] === null ? null : (float) $promotion['moyenne_generale'];
        $promotion['reussites'] = (int) $promotion['reussites'];
        $promotion['echecs'] = (int) $promotion['echecs'];
        $promotion['etudiants_a_risque'] = (int) $promotion['etudiants_a_risque'];

        return $promotion;
    }

    private static function formaterCours(array $cours): array
    {
        $cours['id'] = (int) $cours['id'];
        $cours['promotion_id'] = (int) $cours['promotion_id'];
        $cours['nombre_heures'] = (int) $cours['nombre_heures'];
        $cours['credits'] = (int) $cours['credits'];
        $cours['nombre_etudiants'] = (int) $cours['nombre_etudiants'];
        $cours['moyenne_cours'] = $cours['moyenne_cours'] === null ? null : (float) $cours['moyenne_cours'];
        $cours['etudiants_a_risque'] = (int) $cours['etudiants_a_risque'];
        $cours['assistants'] = $cours['assistants'] ? explode('||', $cours['assistants']) : [];

        return $cours;
    }

    private static function formaterReclamation(array $reclamation): array
    {
        $reclamation['id'] = (int) $reclamation['id'];
        $reclamation['etudiant_id'] = (int) $reclamation['etudiant_id'];
        $reclamation['cours_id'] = $reclamation['cours_id'] === null ? null : (int) $reclamation['cours_id'];
        $reclamation['promotion_id'] = $reclamation['promotion_id'] === null ? null : (int) $reclamation['promotion_id'];
        $reclamation['note_id'] = $reclamation['note_id'] === null ? null : (int) $reclamation['note_id'];
        $reclamation['note_concernee'] = $reclamation['note_concernee'] === null ? null : (float) $reclamation['note_concernee'];
        if ($reclamation['statut'] === 'transmise') {
            $reclamation['statut'] = 'transmise_apparitorat';
        }

        return $reclamation;
    }

    private static function formaterRisque(array $risque): array
    {
        $risque['etudiant_id'] = (int) $risque['etudiant_id'];
        $risque['promotion_id'] = (int) $risque['promotion_id'];
        $risque['cours_id'] = (int) $risque['cours_id'];
        $risque['moyenne'] = (float) $risque['moyenne'];

        return $risque;
    }

    private static function normaliserProjet(array $projet): array
    {
        $projet['id'] = (int) $projet['id'];
        $projet['promotion_id'] = $projet['promotion_id'] === null ? null : (int) $projet['promotion_id'];
        $projet['encadreur_id'] = $projet['encadreur_id'] === null ? null : (int) $projet['encadreur_id'];
        $projet['progression'] = isset($projet['progression']) ? (float) $projet['progression'] : 0.0;
        $projet['en_retard'] = !empty($projet['date_echeance'])
            && !in_array(($projet['statut'] ?? ''), ['termine', 'valide'], true)
            && strtotime((string) $projet['date_echeance']) < time();

        return $projet;
    }

    private static function normaliserStage(array $stage): array
    {
        $stage['id'] = (int) $stage['id'];
        $stage['etudiant_id'] = (int) $stage['etudiant_id'];
        $stage['en_retard'] = !empty($stage['date_fin'])
            && !in_array(($stage['statut'] ?? ''), ['termine', 'valide'], true)
            && strtotime((string) $stage['date_fin']) < time();

        return $stage;
    }
}
