<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Symfony\Component\HttpFoundation\Response;

class RequestIdMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $requestId = $request->header('X-Request-ID') ?: Str::uuid();

        $request->attributes->set('request_id', $requestId);

        return $next($request)->header('X-Request-ID', $requestId);
    }
}
