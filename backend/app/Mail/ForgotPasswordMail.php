<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Queue\SerializesModels;

class ForgotPasswordMail extends Mailable
{
    use Queueable, SerializesModels;

    public $user;
    public $pin;

    /**
     * Create a new message instance.
     */
    public function __construct($user, $pin)
    {
        $this->user = $user;
        $this->pin = $pin;
    }

    /**
     * Build the message.
     */
    public function build()
    {
        return $this->subject('Transact Point - Password Recovery')
                    ->view('emails.forgot_password')
                    ->with([
                        'user' => $this->user,
                        'pin'  => $this->pin,
                    ]);
    }
}
