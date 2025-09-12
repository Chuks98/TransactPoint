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
        Schema::table('wallets', function (Blueprint $table) {
            $table->string('currency')->nullable()->after('balance');
            $table->string('code')->nullable()->after('currency');
            $table->string('currencySign')->nullable()->after('code');
            $table->string('country')->nullable()->after('currencySign');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('wallets', function (Blueprint $table) {
            $table->dropColumn(['currency', 'code', 'currencySign', 'country']);
        });
    }
};
