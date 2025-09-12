<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // links to users
            $table->string('type'); // e.g., airtime, data, cable, electricity, loan
            $table->double('amount')->default(0.0);
            $table->string('description')->nullable();
            $table->string('biller_code')->nullable(); // e.g., provider ID
            $table->string('item_code')->nullable();   // e.g., specific product/service code
            $table->string('status')->default('pending'); // Changed from ENUM to STRING
            $table->timestamps(); // created_at = transaction date
        });

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
