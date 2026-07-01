<?php

namespace App\Listeners;

use App\Events\TaskCompleted;
use App\Jobs\SendTaskCompletedNotification;
use App\Models\TaskAudit;

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
