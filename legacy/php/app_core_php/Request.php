<?php

declare(strict_types=1);

namespace App\Core;

class Request
{
    private ?array $json = null;

    public function method(): string
    {
        return strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');
    }

    public function path(): string
    {
        $uri = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
        $path = '/' . trim($uri, '/');

        return $path === '/' ? '/' : $path;
    }

    public function all(): array
    {
        if ($this->isJson()) {
            return $this->json();
        }

        return $_POST;
    }

    public function json(): array
    {
        if ($this->json !== null) {
            return $this->json;
        }

        $body = file_get_contents('php://input');
        if ($body === false || trim($body) === '') {
            return $this->json = [];
        }

        $decoded = json_decode($body, true);

        return $this->json = is_array($decoded) ? $decoded : [];
    }

    public function input(string $key, mixed $default = null): mixed
    {
        $data = $this->all();

        return $data[$key] ?? $default;
    }

    public function query(string $key, mixed $default = null): mixed
    {
        return $_GET[$key] ?? $default;
    }

    private function isJson(): bool
    {
        $contentType = $_SERVER['CONTENT_TYPE'] ?? '';

        return stripos($contentType, 'application/json') !== false;
    }
}
