<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;
use Symfony\Component\HttpFoundation\Response;

class RequestLoggingMiddleware
{
    public function handle(Request $request, Closure $next): Response
    {
        $requestId = $request->attributes->get('request_id');

        Log::withContext(['request_id' => $requestId]);

        Log::info('Request started', [
            'method' => $request->method(),
            'path' => $request->path(),
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        $response = $next($request);

        Log::info('Request completed', [
            'status_code' => $response->getStatusCode(),
        ]);

        return $response;
    }
}
