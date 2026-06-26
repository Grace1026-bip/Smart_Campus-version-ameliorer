<?php

declare(strict_types=1);

return [
    'name' => env_value('APP_NAME', 'Smart Faculty API'),
    'env' => env_value('APP_ENV', 'local'),
    'debug' => (bool) env_value('APP_DEBUG', true),
    'timezone' => env_value('APP_TIMEZONE', 'Africa/Kinshasa'),
    'frontend_login_url' => env_value('FRONTEND_LOGIN_URL', '/login'),

    'session_name' => env_value('SESSION_NAME', 'SMART_FACULTY_SESSION'),
    'session_secure' => (bool) env_value('SESSION_SECURE', false),
    'session_same_site' => env_value('SESSION_SAME_SITE', 'Lax'),

    'remember_cookie' => env_value('REMEMBER_COOKIE', 'remember_token'),
    'remember_days' => (int) env_value('REMEMBER_DAYS', 10),

    'cors_allowed_origins' => array_values(array_filter(array_map(
        'trim',
        explode(',', (string) env_value('CORS_ALLOWED_ORIGINS', '*'))
    ))),
];
