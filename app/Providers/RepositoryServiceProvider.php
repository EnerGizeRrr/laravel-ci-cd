<?php

namespace App\Providers;

use App\Contracts\TaskRepositoryInterface;
use App\Repositories\EloquentTaskRepository;
use Illuminate\Support\ServiceProvider;

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
