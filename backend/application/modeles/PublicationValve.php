<?php

declare(strict_types=1);

namespace Application\Modeles;

class PublicationValve
{
    public const TYPES = [
        'annonce',
        'communique',
        'devoir',
        'support_de_cours',
        'changement_horaire',
        'consigne_examen',
        'publication_notes',
        'rappel',
    ];
}
