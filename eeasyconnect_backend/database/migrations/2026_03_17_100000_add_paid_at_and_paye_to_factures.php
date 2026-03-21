<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('factures', function (Blueprint $table) {
            $table->timestamp('paid_at')->nullable()->after('rejection_comment');
        });
        // Étendre l'enum status pour inclure 'paye' (MySQL)
        DB::statement("ALTER TABLE factures MODIFY COLUMN status ENUM('en_attente', 'valide', 'rejete', 'payee') DEFAULT 'en_attente'");
    }

    public function down(): void
    {
        DB::statement("ALTER TABLE factures MODIFY COLUMN status ENUM('en_attente', 'valide', 'rejete') DEFAULT 'en_attente'");
        Schema::table('factures', function (Blueprint $table) {
            $table->dropColumn('paid_at');
        });
    }
};
