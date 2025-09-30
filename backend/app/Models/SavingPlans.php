<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class SavingPlans extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'description',
        'min_amount',
        'max_amount',
        'duration_months',
        'interest_rate',
        'interest_type',
        'with_interest',
        'is_locked',
    ];

    public function userSavings()
    {
        return $this->hasMany(UserSaving::class);
    }
}
