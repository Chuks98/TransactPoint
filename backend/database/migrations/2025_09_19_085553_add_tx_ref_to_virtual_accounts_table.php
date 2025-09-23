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
        Schema::table('virtual_accounts', function (Blueprint $table) {
            $table->string('tx_ref')->nullable()->after('order_ref'); // 👈 adds the tx_ref column
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('virtual_accounts', function (Blueprint $table) {
            $table->dropColumn('tx_ref');
        });
    }
};
