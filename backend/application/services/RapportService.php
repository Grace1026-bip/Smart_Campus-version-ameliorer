<?php

declare(strict_types=1);

namespace Application\Services;

class RapportService
{
    public static function rapportsApparitorat(): array
    {
        return AppariteurService::rapports();
    }
}
