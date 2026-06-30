<?php

namespace App\Listeners;

use App\Jobs\SendTaskCompletedNotification;
use App\Events\TaskCompleted;
use App\Models\TaskAudit;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Support\Facades\Auth;

class WriteTaskAuditLog
{
    /**
     * Create the event listener.
     */
    public function __construct()
    {
        //
    }

    /**
     * Handle the event.
     */
    public function handle(TaskCompleted $event): void
    {
        TaskAudit::create([
            'task_id' => $event->task->id,
            'event' => 'completed',
            'meta' => [
                'previous_status' => $event->previousStatus,
                'user_id' => $event->user->id, 
                'user_name' => $event->user->name, 
            ],
            'occurred_at' => now(),
        ]);

        // Отправка в очередь
        SendTaskCompletedNotification::dispatch($event->task, $event->user);
    }
}
