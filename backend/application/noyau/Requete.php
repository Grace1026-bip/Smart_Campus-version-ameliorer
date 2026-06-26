<?php

declare(strict_types=1);

namespace Application\Noyau;

class Requete
{
    private ?array $json = null;

    public function methode(): string
    {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public function chemin(): string
    {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $chemin = '/' . trim($uri, '/');

        return $chemin === '/' ? '/' : $chemin;
    }

    public function donnees(): array
    {
        if ($this->estJson()) {
            return $this->json();
        }

        return $_POST;
    }

    public function json(): array
    {
        if ($this->json !== null) {
            return $this->json;
        }

        $corps = file_get_contents('php://input');

        if ($corps === false || trim($corps) === '') {
            return $this->json = [];
        }

        $decode = json_decode($corps, true);

        return $this->json = is_array($decode) ? $decode : [];
    }

    public function entree(string $cle, mixed $defaut = null): mixed
    {
        $donnees = $this->donnees();

        return $donnees[$cle] ?? $defaut;
    }

    public function requete(string $cle, mixed $defaut = null): mixed
    {
        return $_GET[$cle] ?? $defaut;
    }

    private function estJson(): bool
    {
        $type = $_SERVER['CONTENT_TYPE'] ?? '';

        return stripos($type, 'application/json') !== false;
    }
}
