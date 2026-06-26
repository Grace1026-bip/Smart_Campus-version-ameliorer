<?php

declare(strict_types=1);

namespace App\Core;

use RuntimeException;

class HttpException extends RuntimeException
{
    private int $status;

    public function __construct(string $message, int $status = 400)
    {
        $this->status = $status;
        parent::__construct($message);
    }

    public function status(): int
    {
        return $this->status;
    }
}
