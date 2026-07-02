<?php

declare(strict_types=1);

namespace Application\Services;

class PromotionService
{
    public static function promotionsSupervisees(): array
    {
        return AppariteurService::promotions();
    }

    public static function detailSupervision(int $promotionId): array
    {
        return AppariteurService::promotion($promotionId);
    }
}
