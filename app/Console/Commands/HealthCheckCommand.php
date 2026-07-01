<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class HealthCheckCommand extends Command
{
    /**
     * The name and signature of the console command.
     *
     * @var string
     */
    protected $signature = 'health:check';

    /**
     * The console command description.
     *
     * @var string
     */
    protected $description = 'Check application health';

    /**
     * Execute the console command.
     */
    public function handle()
    {
        try {
            // Check database connection
            \DB::connection()->getPdo();

            return Command::SUCCESS;
        } catch (\Exception $e) {
            return Command::FAILURE;
        }
    }
}
