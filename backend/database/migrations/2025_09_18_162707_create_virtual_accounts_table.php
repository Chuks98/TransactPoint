<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('virtual_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');

            // Flutterwave fields
            $table->string('account_number')->unique();
            $table->string('account_name')->nullable();
            $table->string('bank_name')->nullable();
            $table->string('bank_code')->nullable();
            $table->string('currency', 10)->nullable();
            $table->string('currency_sign', 5)->nullable();
            $table->string('country', 5)->nullable();

            // References / status
            $table->string('reference')->nullable();
            $table->string('order_ref')->nullable();
            $table->string('status')->nullable();

            // JSON field for anything Flutterwave may add in future (BVN, email, etc.)
            $table->json('meta')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('virtual_accounts');
    }
};
