<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class UserSaving extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'plan_id',
        'principal',
        'maturity_amount',
        'start_date',
        'end_date',
        'withdrawn',
    ];

    protected $casts = [
        'start_date' => 'datetime',
        'end_date' => 'datetime',
        'withdrawn' => 'boolean',
    ];

    // Each saving belongs to one plan
    public function plan()
    {
        return $this->belongsTo(SavingPlans::class, 'plan_id');
    }

    // Each saving belongs to one user
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
