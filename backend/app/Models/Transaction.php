<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'type',
        'amount',
        'description',
        'biller_code',
        'item_code',
        'status',
        'currency',
        'transaction_id',
        'code',
        'currencySign',
        'country',
    ];

    // Define relationship to User
    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
