<?php

declare(strict_types=1);

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class TaskResource extends JsonResource
{
    /**
     * The "data" wrapper that should be applied.
     *
     * @var string|null
     */
    public static $wrap = 'data';

    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            // @phpstan-ignore-next-line
            'id' => $this->id,
            // @phpstan-ignore-next-line
            'title' => $this->title,
            // @phpstan-ignore-next-line
            'description' => $this->description,
            // @phpstan-ignore-next-line
            'status' => $this->status,
            // @phpstan-ignore-next-line
            'created_at' => $this->created_at->toDateTimeString(),
            // @phpstan-ignore-next-line
            'updated_at' => $this->updated_at->toDateTimeString(),
        ];
    }
}
