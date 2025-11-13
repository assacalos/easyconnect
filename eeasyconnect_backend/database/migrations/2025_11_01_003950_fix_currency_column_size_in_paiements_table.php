<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Modifier la colonne currency de VARCHAR(3) à VARCHAR(4) pour supporter "FCFA"
        if (Schema::hasColumn('paiements', 'currency')) {
            DB::statement('ALTER TABLE paiements MODIFY currency VARCHAR(4)');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Revenir à VARCHAR(3)
        if (Schema::hasColumn('paiements', 'currency')) {
            DB::statement('ALTER TABLE paiements MODIFY currency VARCHAR(3)');
        }
    }
};
