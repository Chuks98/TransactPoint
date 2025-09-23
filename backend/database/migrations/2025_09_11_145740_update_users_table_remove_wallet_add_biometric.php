<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['walletId', 'walletBalance']); // remove these
            $table->string('biometric')->nullable(); // add biometric
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('walletId')->nullable();
            $table->double('walletBalance')->default(0.0);
            $table->dropColumn('biometric');
        });
    }
};
