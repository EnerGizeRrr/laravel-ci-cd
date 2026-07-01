<?php

namespace App\Http\Middleware;

use Illuminate\Http\Middleware\HandleCors as BaseHandleCors;

class HandleCors extends BaseHandleCors
{
    protected $paths = ['api/*'];

    protected $allowedOrigins = [];

    protected $allowedOriginsPatterns = [];

    protected $allowedMethods = ['*'];

    protected $allowedHeaders = ['*'];

    protected $exposedHeaders = [];

    protected $maxAge = 0;

    protected $supportsCredentials = false;

    public function __construct()
    {
        $this->allowedOrigins = array_filter(explode(',', config('app.cors.allowed_origins', '*')));
        $this->supportsCredentials = (bool) config('app.cors.supports_credentials', false);
    }
}
