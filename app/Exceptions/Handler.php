<?php

namespace App\Exceptions;

use Illuminate\Auth\AuthenticationException;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpFoundation\Response;
use Throwable;

class Handler extends ExceptionHandler
{
    protected $dontFlash = [
        'current_password',
        'password',
        'password_confirmation',
    ];

    public function register(): void
    {
        $this->reportable(function (Throwable $e) {
        });
    }

    public function render($request, Throwable $exception): Response
    {
        if ($request->expectsJson()) {
            return $this->renderJsonException($request, $exception);
        }

        return parent::render($request, $exception);
    }

    private function renderJsonException(Request $request, Throwable $exception): JsonResponse
    {
        $statusCode = $this->getStatusCode($exception);
        $response = [
            'message' => $this->getErrorMessage($exception),
        ];

        if (config('app.debug')) {
            $response['exception'] = class_basename($exception);
            $response['file'] = $exception->getFile();
            $response['line'] = $exception->getLine();
            $response['trace'] = collect($exception->getTrace())->map(function ($trace) {
                return collect($trace)->only(['file', 'line', 'function'])->toArray();
            })->all();
        }

        return response()->json($response, $statusCode);
    }

    private function getStatusCode(Throwable $exception): int
    {
        if (method_exists($exception, 'getStatusCode')) {
            return $exception->getStatusCode();
        }

        if ($exception instanceof ValidationException) {
            return 422;
        }

        if ($exception instanceof AuthenticationException) {
            return 401;
        }

        return 500;
    }

    private function getErrorMessage(Throwable $exception): string
    {
        if (config('app.debug')) {
            return $exception->getMessage();
        }

        if ($exception instanceof ValidationException) {
            return 'Validation failed';
        }

        if ($exception instanceof AuthenticationException) {
            return 'Unauthenticated';
        }

        if (method_exists($exception, 'getStatusCode') && $exception->getStatusCode() === 404) {
            return 'Not found';
        }

        return 'An error occurred';
    }
}
