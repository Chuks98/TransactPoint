<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class VirtualAccount extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'account_number',
        'account_name',
        'bank_name',
        'bank_code',
        'currency',
        'currency_sign',
        'country',
        'reference',
        'order_ref',
        'status',

        // extra fields you may want to persist outside of meta
        'flw_ref',
        'account_status',
        'frequency',
        'expiry_date',
        'note',
        'amount',
        'va_ref',

        'meta',
    ];

    protected $casts = [
        'meta' => 'array',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}
