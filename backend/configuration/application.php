<?php

declare(strict_types=1);

return [
    'nom' => env_fr('APP_NAME', 'Smart Faculty API'),
    'environnement' => env_fr('APP_ENV', 'local'),
    'debug' => (bool) env_fr('APP_DEBUG', true),
    'fuseau_horaire' => env_fr('APP_TIMEZONE', 'Africa/Kinshasa'),

    'nom_session' => env_fr('SESSION_NAME', 'SMART_FACULTY_SESSION'),
    'chemin_sessions' => env_fr('SESSION_SAVE_PATH', 'stockage/sessions'),
    'session_secure' => (bool) env_fr('SESSION_SECURE', false),
    'session_same_site' => env_fr('SESSION_SAME_SITE', 'Lax'),

    'cookie_souvenir' => env_fr('REMEMBER_COOKIE', 'souvenir_smart_faculty'),
    'jours_souvenir' => (int) env_fr('REMEMBER_DAYS', 15),

    'origines_cors' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env_fr('CORS_ALLOWED_ORIGINS', '*'))
    ))),
];
