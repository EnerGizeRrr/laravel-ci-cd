<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Contracts\TaskRepositoryInterface;
use App\Repositories\EloquentTaskRepository;

class RepositoryServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        $this->app->bind(
            TaskRepositoryInterface::class,
            EloquentTaskRepository::class
        );
    }
}
