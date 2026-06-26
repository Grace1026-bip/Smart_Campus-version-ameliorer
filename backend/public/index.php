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
    http_response_code(204);
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
$routeur->get('/api/enseignant/tableau-de-bord', [EnseignantControleur::class, 'tableauDeBord'], [
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
    header('Access-Control-Allow-Headers: Content-Type, Accept, X-Requested-With');
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');

    if ($origine !== '*') {
        header('Vary: Origin');
    }
}
