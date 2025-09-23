<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->string('code')->nullable()->after('transaction_id');
            $table->string('currencySign', 10)->nullable()->after('code');
            $table->string('country', 50)->nullable()->after('currencySign');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropColumn(['code', 'currencySign', 'country']);
        });
    }
};
