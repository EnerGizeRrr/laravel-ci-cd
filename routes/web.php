<?php

use App\Events\TaskCompleted;
use App\Models\Task;
use App\Models\User;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

Route::get('/test-task-completed', function () {
    $user = User::firstOrCreate(
        ['email' => 'test@example.com'],
        ['name' => 'Test User', 'password' => bcrypt('password')]
    );

    $task = Task::firstOrCreate(
        ['title' => 'Тестовая задача для очереди'],
        ['description' => 'Описание тестовой задачи для очереди', 'user_id' => $user->id, 'status' => 'done']
    );

    TaskCompleted::dispatch($task, $user, 'done');

    return response()->json(['message' => 'Событие TaskCompleted отправлено.']);
});
