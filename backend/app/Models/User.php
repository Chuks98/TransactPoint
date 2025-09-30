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
<<<<<<< HEAD
        'biometric',
        'otp',
        'otp_expires_at',
=======
        'biometric', // ✅ replaced walletId & walletBalance
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
    ];

    // Relationship with transactions
    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }
<<<<<<< HEAD

    // public function virtualAccount()
    // {
    //     return $this->hasOne(VirtualAccount::class, 'user_id', 'id');
    // }
=======
>>>>>>> 5f33a7596b3d2552366f9f64ab656233b022e0a9
}
