<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Contracts\TaskRepositoryInterface;
use App\Http\Requests\StoreTaskRequest;
use App\Http\Requests\UpdateTaskRequest;
use App\Http\Resources\TaskResource;
use App\Models\Task;
use Illuminate\Http\Request;
use Illuminate\Foundation\Auth\Access\AuthorizesRequests;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Log;
use Illuminate\Validation\Rule;
use Illuminate\Database\Eloquent\ModelNotFoundException;

class TaskController extends Controller
{
    use AuthorizesRequests;

    protected $taskRepository;

    public function __construct(TaskRepositoryInterface $taskRepository)
    {
        $this->taskRepository = $taskRepository;
    }

    public function index(Request $request)
    {
        Log::info('Запрошен список задач (tasks).');

        $request->validate([
            'status' => ['nullable', 'string', Rule::in(['new', 'in_progress', 'done'])],
        ]);

        $query = $request->user()->tasks();

        if ($request->filled('status')) {
            $query->where('status', $request->status);
        }

        $tasks = $query->paginate();

        return TaskResource::collection($tasks);
    }
 
    public function store(StoreTaskRequest $request)
    {
        Log::info('Попытка создания новой задачи.');
 
        $this->authorize('create', Task::class);

        $task = $request->user()->tasks()->create($request->validated());
 
        return (new TaskResource($task))->response()->setStatusCode(Response::HTTP_CREATED);
    }
 
    public function show(Task $task)
    {
        Log::info('Запрошена задача с ID: ' . $task->id);
 
        $this->authorize('view', $task);
 
        return new TaskResource($task);
    }
 
    public function update(UpdateTaskRequest $request, Task $task)
    {
        Log::info('Попытка обновления задачи с ID: ' . $task->id);
 
        $this->authorize('update', $task);
 
        $updatedTask = $this->taskRepository->update($task, $request->validated());
 
        return new TaskResource($updatedTask);
    }
 
    public function destroy(Task $task)
    {
        Log::info('Попытка удаления задачи с ID: ' . $task->id);
 
        $this->authorize('delete', $task);
 
        $this->taskRepository->delete($task);
 
        return response()->noContent();
    }
}