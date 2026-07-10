<?php

declare(strict_types=1);

namespace Application\Noyau;

class Routeur
{
    private array $routes = [];

    public function get(string $uri, callable|array $action, array $middlewares = []): void
    {
        $this->ajouter('GET', $uri, $action, $middlewares);
    }

    public function post(string $uri, callable|array $action, array $middlewares = []): void
    {
        $this->ajouter('POST', $uri, $action, $middlewares);
    }

    public function put(string $uri, callable|array $action, array $middlewares = []): void
    {
        $this->ajouter('PUT', $uri, $action, $middlewares);
    }

    public function delete(string $uri, callable|array $action, array $middlewares = []): void
    {
        $this->ajouter('DELETE', $uri, $action, $middlewares);
    }

    public function ajouter(string $methode, string $uri, callable|array $action, array $middlewares = []): void
    {
        $this->routes[] = [
            'methode' => strtoupper($methode),
            'uri' => '/' . trim($uri, '/'),
            'action' => $action,
            'middlewares' => $middlewares,
        ];
    }

    public function distribuer(Requete $requete): void
    {
        foreach ($this->routes as $route) {
            $parametres = $this->correspond($route, $requete);

            if ($parametres === null) {
                continue;
            }

            foreach ($route['middlewares'] as $middleware) {
                if ($middleware($requete) === false) {
                    return;
                }
            }

            $this->executer($route['action'], $requete, $parametres);
            return;
        }

        Reponse::erreur('Endpoint introuvable.', 404);
    }

    private function correspond(array $route, Requete $requete): ?array
    {
        if ($route['methode'] !== $requete->methode()) {
            return null;
        }

        $motif = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[^/]+)', $route['uri']);
        $motif = '#^' . $motif . '$#';

        if (!preg_match($motif, $requete->chemin(), $correspondances)) {
            return null;
        }

        return array_filter(
            $correspondances,
            static fn ($cle): bool => is_string($cle),
            ARRAY_FILTER_USE_KEY
        );
    }

    private function executer(callable|array $action, Requete $requete, array $parametres): void
    {
        if (is_array($action) && is_string($action[0])) {
            $controleur = new $action[0]();
            $methode = $action[1];
            $controleur->{$methode}($requete, ...array_values($parametres));
            return;
        }

        $action($requete, ...array_values($parametres));
    }
}
