<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class UserSeeder extends Seeder
{
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Test User 1',
            'email' => 'user1@example.com',
            'password' => 'password',
        ]);

        User::factory()->create([
            'name' => 'Test User 2',
            'email' => 'user2@example.com',
            'password' => 'password',
        ]);
    }
}