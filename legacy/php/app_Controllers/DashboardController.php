<?php

declare(strict_types=1);

namespace App\Controllers;

use App\Core\Auth;
use App\Core\Controller;
use App\Core\Request;

class DashboardController extends Controller
{
    public function status(Request $request): void
    {
        $this->json([
            'project' => 'Smart Faculty',
            'api' => 'PHP MVC',
            'authenticated' => Auth::user() !== null,
        ], 'API en ligne.');
    }
}
