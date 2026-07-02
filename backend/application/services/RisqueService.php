<?php

declare(strict_types=1);

namespace Application\Services;

class RisqueService
{
    public static function risquesAcademiques(): array
    {
        return AppariteurService::risques();
    }
}
