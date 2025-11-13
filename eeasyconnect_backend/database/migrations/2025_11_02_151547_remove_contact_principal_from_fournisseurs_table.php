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
        Schema::table('fournisseurs', function (Blueprint $table) {
            // Supprimer le champ contact_principal
            if (Schema::hasColumn('fournisseurs', 'contact_principal')) {
                $table->dropColumn('contact_principal');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('fournisseurs', function (Blueprint $table) {
            // Recréer le champ contact_principal
            $table->string('contact_principal')->nullable()->after('pays');
        });
    }
};
