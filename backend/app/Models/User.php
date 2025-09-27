<?php

namespace App\Models; // 👈 you’re missing this line

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable; // 👈 this is the right class
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'firstName',
        'lastName',
        'phoneNumber',
        'email',
        'password',
        'biometric', // ✅ replaced walletId & walletBalance
    ];

    // Relationship with transactions
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    // public function virtualAccount()
    // {
    //     return $this->hasOne(VirtualAccount::class, 'user_id', 'id');
    // }
}
