<?php

declare(strict_types=1);

function champs_obligatoires(array $donnees, array $champs): array
{
    $erreurs = [];

    foreach ($champs as $champ) {
        if (!array_key_exists($champ, $donnees) || trim((string) $donnees[$champ]) === '') {
            $erreurs[$champ] = 'Champ obligatoire.';
        }
    }

    return $erreurs;
}

function email_valide(?string $email): bool
{
    return $email !== null && filter_var($email, FILTER_VALIDATE_EMAIL) !== false;
}

function mot_de_passe_valide(string $motDePasse): bool
{
    return strlen($motDePasse) >= 8;
}
