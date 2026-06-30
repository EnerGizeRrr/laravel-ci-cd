<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TaskAudit extends Model
{
    use HasFactory;

    protected $fillable = [
        'task_id',
        'event',
        'meta',
        'occurred_at',
    ];

    public $timestamps = false;

    protected $casts = [
        'meta' => 'array',
        'occurred_at' => 'datetime',
    ];
}
