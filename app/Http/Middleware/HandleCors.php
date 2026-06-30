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
        $this->allowedOrigins = array_filter(explode(',', env('CORS_ALLOWED_ORIGINS', '*')));
        $this->supportsCredentials = env('CORS_SUPPORTS_CREDENTIALS', false);
    }
}
