<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Redis;

class HealthController extends Controller
{
    public function health(): JsonResponse
    {
        return response()->json([
            'status' => 'alive',
            'timestamp' => now()->toIso8601String(),
        ]);
    }

    public function ready(): JsonResponse
    {
        try {
            DB::connection()->getPdo();
            Redis::ping();
            
            return response()->json([
                'status' => 'ready',
                'database' => 'connected',
                'cache' => 'connected',
                'timestamp' => now()->toIso8601String(),
            ]);
        } catch (QueryException $e) {
            return response()->json([
                'status' => 'not_ready',
                'database' => 'disconnected',
                'error' => 'Database unavailable',
            ], 503);
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'not_ready',
                'cache' => 'disconnected',
                'error' => 'Cache unavailable',
            ], 503);
        }
    }

    public function metrics(): JsonResponse|string
    {
        $stats = [
            'requests_total' => (int) Redis::get('metrics:requests_total') ?: 0,
            'requests_by_method' => [
                'GET' => (int) Redis::get('metrics:requests:GET') ?: 0,
                'POST' => (int) Redis::get('metrics:requests:POST') ?: 0,
                'PUT' => (int) Redis::get('metrics:requests:PUT') ?: 0,
                'DELETE' => (int) Redis::get('metrics:requests:DELETE') ?: 0,
                'PATCH' => (int) Redis::get('metrics:requests:PATCH') ?: 0,
            ],
            'response_time_avg_ms' => (float) Redis::get('metrics:response_time_avg') ?: 0,
            'response_time_p95_ms' => (float) Redis::get('metrics:response_time_p95') ?: 0,
            'response_time_p99_ms' => (float) Redis::get('metrics:response_time_p99') ?: 0,
            'errors_4xx' => (int) Redis::get('metrics:errors:4xx') ?: 0,
            'errors_5xx' => (int) Redis::get('metrics:errors:5xx') ?: 0,
        ];

        $accept = request()->header('Accept', 'application/json');

        if (str_contains($accept, 'text/plain')) {
            return $this->formatPrometheus($stats);
        }

        return response()->json($stats);
    }

    private function formatPrometheus(array $stats): string
    {
        $lines = [
            '# HELP http_requests_total Total HTTP requests',
            '# TYPE http_requests_total counter',
            'http_requests_total ' . $stats['requests_total'],
            '',
            '# HELP http_requests_by_method HTTP requests by method',
            '# TYPE http_requests_by_method counter',
        ];

        foreach ($stats['requests_by_method'] as $method => $count) {
            $lines[] = "http_requests_by_method{method=\"$method\"} $count";
        }

        $lines[] = '';
        $lines[] = '# HELP http_response_time_avg Average response time in milliseconds';
        $lines[] = '# TYPE http_response_time_avg gauge';
        $lines[] = 'http_response_time_avg ' . $stats['response_time_avg_ms'];
        $lines[] = '';
        $lines[] = '# HELP http_response_time_p95 P95 response time in milliseconds';
        $lines[] = '# TYPE http_response_time_p95 gauge';
        $lines[] = 'http_response_time_p95 ' . $stats['response_time_p95_ms'];
        $lines[] = '';
        $lines[] = '# HELP http_response_time_p99 P99 response time in milliseconds';
        $lines[] = '# TYPE http_response_time_p99 gauge';
        $lines[] = 'http_response_time_p99 ' . $stats['response_time_p99_ms'];
        $lines[] = '';
        $lines[] = '# HELP http_errors_4xx HTTP 4xx errors';
        $lines[] = '# TYPE http_errors_4xx counter';
        $lines[] = 'http_errors_4xx ' . $stats['errors_4xx'];
        $lines[] = '';
        $lines[] = '# HELP http_errors_5xx HTTP 5xx errors';
        $lines[] = '# TYPE http_errors_5xx counter';
        $lines[] = 'http_errors_5xx ' . $stats['errors_5xx'];

        return implode("\n", $lines);
    }
}
