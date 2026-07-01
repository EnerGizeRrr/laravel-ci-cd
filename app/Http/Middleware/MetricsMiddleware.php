<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Redis;
use Symfony\Component\HttpFoundation\Response;

class MetricsMiddleware
{
    private array $responseTimes = [];

    public function handle(Request $request, Closure $next): Response
    {
        $startTime = microtime(true);

        $response = $next($request);

        $duration = (microtime(true) - $startTime) * 1000;

        $this->recordMetrics($request, $response, $duration);

        return $response;
    }

    private function recordMetrics(Request $request, Response $response, float $durationMs): void
    {
        try {
            Redis::incr('metrics:requests_total');
            Redis::incr('metrics:requests:'.$request->method());

            $statusCode = $response->getStatusCode();
            if ($statusCode >= 400 && $statusCode < 500) {
                Redis::incr('metrics:errors:4xx');
            } elseif ($statusCode >= 500) {
                Redis::incr('metrics:errors:5xx');
            }

            $this->updateResponseTimeMetrics($durationMs);
        } catch (\Exception $e) {
        }
    }

    private function updateResponseTimeMetrics(float $durationMs): void
    {
        $key = 'metrics:response_times:'.date('Y-m-d H:i');

        Redis::lpush($key, $durationMs);
        Redis::expire($key, 3600);

        $times = Redis::lrange($key, 0, -1);
        $times = array_map('floatval', $times);

        if (! empty($times)) {
            $avg = array_sum($times) / count($times);
            Redis::set('metrics:response_time_avg', round($avg, 2));

            sort($times);
            $count = count($times);
            $p95Index = (int) ceil($count * 0.95) - 1;
            $p99Index = (int) ceil($count * 0.99) - 1;

            if ($p95Index >= 0) {
                Redis::set('metrics:response_time_p95', round($times[$p95Index], 2));
            }
            if ($p99Index >= 0) {
                Redis::set('metrics:response_time_p99', round($times[$p99Index], 2));
            }
        }
    }
}
