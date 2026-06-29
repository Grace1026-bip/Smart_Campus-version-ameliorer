<?php

declare(strict_types=1);

namespace Application\Modeles;

class Note
{
    public static function statutDepuisMoyenne(?float $moyenne): string
    {
        if ($moyenne === null) {
            return 'en_attente';
        }

        return $moyenne >= 10.0 ? 'reussi' : 'echoue';
    }
}
