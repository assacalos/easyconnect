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
            // Ajouter client_id si n'existe pas (car le frontend utilise client_id directement)
            if (!Schema::hasColumn('paiements', 'client_id')) {
                $table->unsignedBigInteger('client_id')->nullable()->after('facture_id');
                $table->foreign('client_id')->references('id')->on('clients')->onDelete('set null');
            }
            
            // Ajouter comptable_id si n'existe pas (car le frontend utilise comptable_id au lieu de user_id)
            if (!Schema::hasColumn('paiements', 'comptable_id')) {
                $table->unsignedBigInteger('comptable_id')->nullable()->after('user_id');
                $table->foreign('comptable_id')->references('id')->on('users')->onDelete('set null');
            }
            
            // Rendre facture_id nullable car le frontend peut ne pas passer par facture
            $table->unsignedBigInteger('facture_id')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('paiements', function (Blueprint $table) {
            if (Schema::hasColumn('paiements', 'client_id')) {
                $table->dropForeign(['client_id']);
                $table->dropColumn('client_id');
            }
            
            if (Schema::hasColumn('paiements', 'comptable_id')) {
                $table->dropForeign(['comptable_id']);
                $table->dropColumn('comptable_id');
            }
            
            $table->unsignedBigInteger('facture_id')->nullable(false)->change();
        });
    }
};
