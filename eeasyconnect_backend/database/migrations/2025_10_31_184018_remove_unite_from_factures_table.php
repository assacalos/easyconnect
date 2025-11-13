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
        Schema::table('factures', function (Blueprint $table) {
            // Supprimer la colonne unite si elle existe
            if (Schema::hasColumn('factures', 'unite')) {
                $table->dropColumn('unite');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('factures', function (Blueprint $table) {
            // Recréer la colonne unite si elle n'existe pas
            if (!Schema::hasColumn('factures', 'unite')) {
                $table->string('unite')->nullable()->after('notes');
            }
        });
    }
};
