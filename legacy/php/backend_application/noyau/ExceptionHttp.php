<?php

declare(strict_types=1);

namespace Application\Noyau;

use RuntimeException;

class ExceptionHttp extends RuntimeException
{
    public function __construct(string $message, private readonly int $statut = 400, private readonly array $erreurs = [])
    {
        parent::__construct($message, $statut);
    }

    public function statut(): int
    {
        return $this->statut;
    }

    public function erreurs(): array
    {
        return $this->erreurs;
    }
}
