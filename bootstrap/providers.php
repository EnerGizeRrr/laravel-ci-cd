<?php

use App\Providers\AppServiceProvider;
use App\Providers\RepositoryServiceProvider;
use Illuminate\Queue\QueueServiceProvider;

return [
    AppServiceProvider::class,
    RepositoryServiceProvider::class,
    QueueServiceProvider::class,
];
