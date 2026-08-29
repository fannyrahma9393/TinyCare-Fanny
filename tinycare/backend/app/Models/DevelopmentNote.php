<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class DevelopmentNote extends Model
{
    protected $fillable = [
        'child_id',
        'development_category_id',
        'note',
        'date',
        'created_by',
    ];

    protected $casts = [
        'date' => 'date',
    ];

    public function child(): BelongsTo
    {
        return $this->belongsTo(Child::class);
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(DevelopmentCategory::class, 'development_category_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
