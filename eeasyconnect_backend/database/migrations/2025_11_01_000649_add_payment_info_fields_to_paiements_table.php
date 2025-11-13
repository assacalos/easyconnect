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
        Schema::table('paiements', function (Blueprint $table) {
            // Ajouter les champs pour stocker les informations client et comptable
            // (utilisés par le frontend pour éviter les jointures)
            if (!Schema::hasColumn('paiements', 'client_name')) {
                $table->string('client_name')->nullable()->after('client_id');
            }
            
            if (!Schema::hasColumn('paiements', 'client_email')) {
                $table->string('client_email')->nullable()->after('client_name');
            }
            
            if (!Schema::hasColumn('paiements', 'client_address')) {
                $table->text('client_address')->nullable()->after('client_email');
            }
            
            if (!Schema::hasColumn('paiements', 'comptable_name')) {
                $table->string('comptable_name')->nullable()->after('comptable_id');
            }
            
            // Ajouter notes (en plus de commentaire)
            if (!Schema::hasColumn('paiements', 'notes')) {
                $table->text('notes')->nullable()->after('commentaire');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('paiements', function (Blueprint $table) {
            if (Schema::hasColumn('paiements', 'client_name')) {
                $table->dropColumn('client_name');
            }
            
            if (Schema::hasColumn('paiements', 'client_email')) {
                $table->dropColumn('client_email');
            }
            
            if (Schema::hasColumn('paiements', 'client_address')) {
                $table->dropColumn('client_address');
            }
            
            if (Schema::hasColumn('paiements', 'comptable_name')) {
                $table->dropColumn('comptable_name');
            }
            
            if (Schema::hasColumn('paiements', 'notes')) {
                $table->dropColumn('notes');
            }
        });
    }
};
