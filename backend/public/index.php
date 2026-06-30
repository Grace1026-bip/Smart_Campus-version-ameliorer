<?php

declare(strict_types=1);

use Application\Controleurs\AuthentificationControleur;
use Application\Controleurs\EnseignantControleur;
use Application\Controleurs\EtudiantControleur;
use Application\Controleurs\InscriptionControleur;
use Application\Controleurs\UtilisateurControleur;
use Application\Middlewares\AuthentificationMiddleware;
use Application\Middlewares\RoleMiddleware;
use Application\Noyau\ExceptionHttp;
use Application\Noyau\Reponse;
use Application\Noyau\Requete;
use Application\Noyau\Routeur;
use Application\Services\AuthentificationService;
use Application\Services\SessionService;

require_once dirname(__DIR__) . '/application/aides/securite.php';
require_once dirname(__DIR__) . '/application/aides/validation.php';

if (PHP_SAPI === 'cli-server' && ($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'GET') {
    $cheminStatique = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
    $fichierStatique = __DIR__ . DIRECTORY_SEPARATOR . ltrim(str_replace('\\', '/', $cheminStatique), '/');

    if (is_file($fichierStatique)) {
        return false;
    }
}

charger_env(dirname(chemin_base()) . DIRECTORY_SEPARATOR . '.env');
charger_env(chemin_base('.env'));

spl_autoload_register(static function (string $classe): void {
    $prefixe = 'Application\\';

    if (strncmp($classe, $prefixe, strlen($prefixe)) !== 0) {
        return;
    }

    $relatif = substr($classe, strlen($prefixe));
    $segments = explode('\\', $relatif);
    $segments[0] = strtolower($segments[0]);
    $fichier = chemin_base('application' . DIRECTORY_SEPARATOR . implode(DIRECTORY_SEPARATOR, $segments) . '.php');

    if (is_readable($fichier)) {
        require_once $fichier;
    }
});

$configuration = require chemin_base('configuration/application.php');
date_default_timezone_set((string) $configuration['fuseau_horaire']);

appliquer_cors($configuration);

if (($_SERVER['REQUEST_METHOD'] ?? 'GET') === 'OPTIONS') {
    Reponse::succes([], 'Preflight CORS OK.');
    exit;
}

SessionService::configurer($configuration);
SessionService::demarrer();
AuthentificationService::configurer($configuration);

$routeur = new Routeur();

$auth = [[AuthentificationMiddleware::class, 'gerer']];
$approbateurs = ['icp', 'paritaire', 'doyen', 'vice_doyen', 'administrateur'];
$gestionnaires = ['administrateur', 'doyen', 'vice_doyen'];

$routeur->get('/api/status', static function (Requete $requete): void {
    Reponse::succes([
        'application' => 'Smart Faculty',
        'api' => 'PHP POO MVC',
        'connecte' => AuthentificationService::utilisateurConnecte() !== null,
    ], 'API en ligne.');
});

$routeur->post('/api/connexion', [AuthentificationControleur::class, 'connexion']);
$routeur->post('/api/deconnexion', [AuthentificationControleur::class, 'deconnexion'], $auth);
$routeur->post('/api/inscription/etudiant', [InscriptionControleur::class, 'inscrireEtudiant']);
$routeur->post('/api/inscription/enseignant', [InscriptionControleur::class, 'inscrireEnseignant']);
$routeur->get('/api/utilisateur/connecte', [UtilisateurControleur::class, 'connecte'], $auth);

$routeur->get('/api/demandes-inscription', [InscriptionControleur::class, 'demandes'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);
$routeur->post('/api/demandes-inscription/{id}/approuver', [InscriptionControleur::class, 'approuver'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);
$routeur->post('/api/demandes-inscription/{id}/rejeter', [InscriptionControleur::class, 'rejeter'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);

$routeur->get('/api/etudiant/tableau-de-bord', [EtudiantControleur::class, 'tableauDeBord'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/cours', [EtudiantControleur::class, 'cours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/cours/{id}', [EtudiantControleur::class, 'detailCours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/valve', [EtudiantControleur::class, 'valve'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/valve/cours/{id}', [EtudiantControleur::class, 'valveCours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/notes', [EtudiantControleur::class, 'notes'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->get('/api/etudiant/alertes', [EtudiantControleur::class, 'alertes'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);
$routeur->post('/api/etudiant/reclamations', [EtudiantControleur::class, 'creerReclamation'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['etudiant', 'chef_promotion', 'administrateur']),
]);

$routeur->get('/api/enseignant/tableau-de-bord', [EnseignantControleur::class, 'tableauDeBord'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/cours', [EnseignantControleur::class, 'cours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/cours/{id}', [EnseignantControleur::class, 'detailCours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/valve', [EnseignantControleur::class, 'valve'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->post('/api/enseignant/valve/publication', [EnseignantControleur::class, 'creerPublication'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->put('/api/enseignant/valve/publication/{id}', [EnseignantControleur::class, 'modifierPublication'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->delete('/api/enseignant/valve/publication/{id}', [EnseignantControleur::class, 'supprimerPublication'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/cours/{id}/etudiants', [EnseignantControleur::class, 'etudiantsCours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/cours/{id}/notes', [EnseignantControleur::class, 'notesCours'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->post('/api/enseignant/cours/{id}/notes/brouillon', [EnseignantControleur::class, 'enregistrerBrouillon'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->post('/api/enseignant/cours/{id}/notes/publier', [EnseignantControleur::class, 'publierNotes'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/cours/{id}/etudiants-a-risque', [EnseignantControleur::class, 'etudiantsRisque'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/reclamations', [EnseignantControleur::class, 'reclamations'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->get('/api/enseignant/reclamations/{id}', [EnseignantControleur::class, 'detailReclamation'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);
$routeur->post('/api/enseignant/reclamations/{id}/repondre', [EnseignantControleur::class, 'repondreReclamation'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser(['enseignant', 'doyen', 'vice_doyen', 'administrateur']),
]);

$routeur->get('/api/roles', [UtilisateurControleur::class, 'roles']);
$routeur->get('/api/utilisateurs', [UtilisateurControleur::class, 'utilisateurs'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($gestionnaires),
]);

// Alias utiles pour les premiers essais Flutter/Postman et l'ancien brouillon.
$routeur->post('/api/login', [AuthentificationControleur::class, 'connexion']);
$routeur->post('/api/logout', [AuthentificationControleur::class, 'deconnexion'], $auth);
$routeur->get('/api/me', [UtilisateurControleur::class, 'connecte'], $auth);
$routeur->post('/api/register-request', [InscriptionControleur::class, 'inscrireGenerique']);
$routeur->get('/api/registration-requests', [InscriptionControleur::class, 'demandes'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);
$routeur->post('/api/registration-requests/{id}/approve', [InscriptionControleur::class, 'approuver'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);
$routeur->post('/api/registration-requests/{id}/reject', [InscriptionControleur::class, 'rejeter'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($approbateurs),
]);
$routeur->get('/api/users', [UtilisateurControleur::class, 'utilisateurs'], [
    [AuthentificationMiddleware::class, 'gerer'],
    RoleMiddleware::autoriser($gestionnaires),
]);

try {
    $routeur->distribuer(new Requete());
} catch (ExceptionHttp $exception) {
    Reponse::erreur($exception->getMessage(), $exception->statut(), $exception->erreurs());
} catch (Throwable $exception) {
    $erreurs = [];

    if ((bool) $configuration['debug']) {
        $erreurs['exception'] = [
            'type' => $exception::class,
            'message' => $exception->getMessage(),
        ];
    }

    Reponse::erreur('Erreur interne du serveur.', 500, $erreurs);
}

function appliquer_cors(array $configuration): void
{
    $originesAutorisees = $configuration['origines_cors'] ?: ['*'];
    $origineRequete = $_SERVER['HTTP_ORIGIN'] ?? '';
    $origine = '*';

    if (in_array('*', $originesAutorisees, true)) {
        $origine = $origineRequete !== '' ? $origineRequete : '*';
    } elseif ($origineRequete !== '' && in_array($origineRequete, $originesAutorisees, true)) {
        $origine = $origineRequete;
    }

    header('Access-Control-Allow-Origin: ' . $origine);
    header('Access-Control-Allow-Credentials: true');
    header('Access-Control-Allow-Headers: Content-Type, Accept, X-Requested-With, Authorization');
    header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
    header('Access-Control-Max-Age: 86400');

    if ($origine !== '*') {
        header('Vary: Origin');
    }
}
