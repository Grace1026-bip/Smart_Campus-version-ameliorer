<?php

declare(strict_types=1);

return [
    'pilote' => 'mysql',
    'hote' => env_fr('DB_HOST', '127.0.0.1'),
    'port' => (int) env_fr('DB_PORT', 3306),
    'ports_secours' => array_values(array_filter(array_map(
        static fn (string $port): int => (int) trim($port),
        explode(',', (string) env_fr('DB_PORT_FALLBACKS', ''))
    ), static fn (int $port): bool => $port > 0)),
    'base' => env_fr('DB_DATABASE', 'smart_faculty'),
    'utilisateur' => env_fr('DB_USERNAME', 'root'),
    'mot_de_passe' => env_fr('DB_PASSWORD', ''),
    'encodage' => env_fr('DB_CHARSET', 'utf8mb4'),
    'options' => [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ],
];
