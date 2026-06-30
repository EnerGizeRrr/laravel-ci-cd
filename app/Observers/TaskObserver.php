<?php

namespace App\Observers;

use App\Events\TaskCompleted;
use App\Models\Task;
use Illuminate\Support\Facades\Auth;

class TaskObserver
{
    /**
     * Handle the Task "updated" event.
     */
    public function updated(Task $task): void
    {
        if ($task->isDirty('status') && $task->status === 'done') {
            $previousStatus = $task->getOriginal('status');
            $user = Auth::user();

            if ($user) {
                TaskCompleted::dispatch($task, $user, $previousStatus);
            }
        }
    }
}
