<?php

namespace App\Jobs;

use App\Models\Task;
use App\Models\User;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Facades\Log;

class SendTaskCompletedNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public Task $task,
        public User $user
    ) {
    }

    public function handle(): void
    {
        Log::info('Задача выполнена!', [
            'task_id' => $this->task->id,
            'task_title' => $this->task->title,
            'user_id' => $this->user->id,
            'user_name' => $this->user->name,
        ]);
    }
}