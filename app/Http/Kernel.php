<?php

namespace App\Http;

use App\Http\Middleware\HandleCors;
use App\Http\Middleware\MetricsMiddleware;
use App\Http\Middleware\RequestIdMiddleware;
use App\Http\Middleware\RequestLoggingMiddleware;
use Illuminate\Foundation\Http\Kernel as HttpKernel;
use Illuminate\Routing\Middleware\ThrottleRequests;

class Kernel extends HttpKernel
{
    /**
     * The application's global HTTP middleware stack.
     *
     * These middleware are run during every request to your application.
     *
     * @var array<int, class-string|string>
     */
    protected $middleware = [
        RequestIdMiddleware::class,
        MetricsMiddleware::class,
        RequestLoggingMiddleware::class,
        HandleCors::class,
    ];

    /**
     * The application's route middleware groups.
     *
     * @var array<string, array<int, class-string|string>>
     */
    protected $middlewareGroups = [
        'web' => [],
        'api' => [
            'throttle:60,1',
        ],
    ];

    /**
     * The application's middleware aliases.
     *
     * Aliases may be used to conveniently assign middleware to routes and groups.
     *
     * @var array<string, class-string|string>
     */
    protected $middlewareAliases = [
        'throttle' => ThrottleRequests::class,
    ];
}
