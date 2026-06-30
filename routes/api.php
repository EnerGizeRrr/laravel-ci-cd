<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\TaskController;
use App\Http\Controllers\HealthController;

Route::get('/test', function () {
    \Illuminate\Support\Facades\Log::info('Test route was hit');
    return response()->json(['message' => 'API is working!']);
});

Route::get('/health', [HealthController::class, 'health']);
Route::get('/ready', [HealthController::class, 'ready']);
Route::get('/metrics', [HealthController::class, 'metrics']);



Route::middleware('auth:sanctum')->group(function () {
    Route::apiResource('tasks', TaskController::class);
});

Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return $request->user();
})->withoutMiddleware('throttle');

Route::post('/login', function (Request $request) {
    if (!auth()->attempt($request->only('email', 'password'))) {
        return response()->json(['message' => 'Invalid credentials'], 401);
    }

    $user = \App\Models\User::where('email', $request->email)->firstOrFail();

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json(['token' => $token]);
})->withoutMiddleware('throttle');
