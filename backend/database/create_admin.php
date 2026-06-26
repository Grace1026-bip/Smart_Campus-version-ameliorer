<?php

declare(strict_types=1);

use App\Core\Database;

require_once dirname(__DIR__) . '/app/Helpers/functions.php';

load_env_file(dirname(base_path()) . DIRECTORY_SEPARATOR . '.env');
load_env_file(base_path('.env'));

spl_autoload_register(static function (string $class): void {
    $prefix = 'App\\';

    if (strncmp($class, $prefix, strlen($prefix)) !== 0) {
        return;
    }

    $relative = substr($class, strlen($prefix));
    $relativePath = str_replace('\\', DIRECTORY_SEPARATOR, $relative) . '.php';
    $candidates = [
        base_path('app' . DIRECTORY_SEPARATOR . $relativePath),
    ];

    $parts = explode(DIRECTORY_SEPARATOR, $relativePath);
    $parts[0] = strtolower($parts[0]);
    $candidates[] = base_path('app' . DIRECTORY_SEPARATOR . implode(DIRECTORY_SEPARATOR, $parts));

    foreach ($candidates as $file) {
        if (is_readable($file)) {
            require_once $file;
            return;
        }
    }
});

$email = getenv('ADMIN_EMAIL') ?: 'admin@smartfaculty.test';
$password = getenv('ADMIN_PASSWORD') ?: 'Admin@123456';

$pdo = Database::connection();
$pdo->beginTransaction();

try {
    $existing = $pdo->prepare('SELECT id FROM utilisateurs WHERE email = :email LIMIT 1');
    $existing->execute(['email' => $email]);
    $userId = $existing->fetchColumn();

    if (!$userId) {
        $statement = $pdo->prepare(
            'INSERT INTO utilisateurs (nom, postnom, prenom, email, telephone, password_hash, active)
             VALUES (:nom, :postnom, :prenom, :email, :telephone, :password_hash, 1)'
        );
        $statement->execute([
            'nom' => 'Admin',
            'postnom' => null,
            'prenom' => 'Smart Faculty',
            'email' => $email,
            'telephone' => null,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
        ]);

        $userId = (int) $pdo->lastInsertId();
    }

    $role = $pdo->prepare('SELECT id FROM roles WHERE code = :code LIMIT 1');
    $role->execute(['code' => 'administrateur']);
    $roleId = $role->fetchColumn();

    if (!$roleId) {
        throw new RuntimeException('Role administrateur introuvable. Importez smart_faculty.sql avant ce script.');
    }

    $attach = $pdo->prepare(
        'INSERT IGNORE INTO roles_utilisateurs (user_id, role_id) VALUES (:user_id, :role_id)'
    );
    $attach->execute([
        'user_id' => $userId,
        'role_id' => $roleId,
    ]);

    $pdo->commit();

    echo "Administrateur pret: {$email}\n";
    echo "Mot de passe dev: {$password}\n";
} catch (Throwable $throwable) {
    $pdo->rollBack();
    fwrite(STDERR, $throwable->getMessage() . PHP_EOL);
    exit(1);
}
