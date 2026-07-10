<?php

declare(strict_types=1);

namespace App\Core;

class Router
{
    private array $routes = [];

    public function get(string $uri, callable|array $handler, array $middlewares = []): void
    {
        $this->add('GET', $uri, $handler, $middlewares);
    }

    public function post(string $uri, callable|array $handler, array $middlewares = []): void
    {
        $this->add('POST', $uri, $handler, $middlewares);
    }

    public function add(string $method, string $uri, callable|array $handler, array $middlewares = []): void
    {
        $this->routes[] = [
            'method' => strtoupper($method),
            'uri' => '/' . trim($uri, '/'),
            'handler' => $handler,
            'middlewares' => $middlewares,
        ];
    }

    public function dispatch(Request $request): void
    {
        foreach ($this->routes as $route) {
            $params = $this->match($route, $request);

            if ($params === null) {
                continue;
            }

            foreach ($route['middlewares'] as $middleware) {
                if ($middleware($request) === false) {
                    return;
                }
            }

            $this->callHandler($route['handler'], $request, $params);

            return;
        }

        Response::error('Endpoint introuvable.', 404);
    }

    private function match(array $route, Request $request): ?array
    {
        if ($route['method'] !== $request->method()) {
            return null;
        }

        $pattern = preg_replace('#\{([a-zA-Z_][a-zA-Z0-9_]*)\}#', '(?P<$1>[^/]+)', $route['uri']);
        $pattern = '#^' . $pattern . '$#';

        if (!preg_match($pattern, $request->path(), $matches)) {
            return null;
        }

        return array_filter(
            $matches,
            static fn ($key) => is_string($key),
            ARRAY_FILTER_USE_KEY
        );
    }

    private function callHandler(callable|array $handler, Request $request, array $params): void
    {
        if (is_array($handler) && is_string($handler[0])) {
            $controller = new $handler[0]();
            $method = $handler[1];
            $controller->{$method}($request, ...array_values($params));

            return;
        }

        $handler($request, ...array_values($params));
    }
}
