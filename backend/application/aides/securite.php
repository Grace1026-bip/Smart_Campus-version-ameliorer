<?php

declare(strict_types=1);

function chemin_base(string $chemin = ''): string
{
    $racine = dirname(__DIR__, 2);

    if ($chemin === '') {
        return $racine;
    }

    return $racine . DIRECTORY_SEPARATOR . ltrim($chemin, DIRECTORY_SEPARATOR);
}

function charger_env(string $fichier): void
{
    if (!is_readable($fichier)) {
        return;
    }

    foreach (file($fichier, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) ?: [] as $ligne) {
        $ligne = trim($ligne);

        if ($ligne === '' || str_starts_with($ligne, '#') || !str_contains($ligne, '=')) {
            continue;
        }

        [$cle, $valeur] = array_map('trim', explode('=', $ligne, 2));
        $valeur = trim($valeur, "\"'");

        if (getenv($cle) === false) {
            putenv($cle . '=' . $valeur);
            $_ENV[$cle] = $valeur;
            $_SERVER[$cle] = $valeur;
        }
    }
}

function env_fr(string $cle, mixed $defaut = null): mixed
{
    $valeur = getenv($cle);

    if ($valeur === false) {
        return $defaut;
    }

    return match (strtolower((string) $valeur)) {
        'true' => true,
        'false' => false,
        'null' => null,
        default => $valeur,
    };
}

function normaliser_booleen(mixed $valeur): bool
{
    return filter_var($valeur, FILTER_VALIDATE_BOOLEAN);
}

function nettoyer_chaine(mixed $valeur): string
{
    return trim((string) $valeur);
}
