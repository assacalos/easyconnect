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
        Schema::table('interventions', function (Blueprint $table) {
            // Vérifier si la colonne n'existe pas déjà avant de l'ajouter
            if (!Schema::hasColumn('interventions', 'client_id')) {
                $table->unsignedBigInteger('client_id')->nullable();
                $table->foreign('client_id')->references('id')->on('clients')->onDelete('set null');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('interventions', function (Blueprint $table) {
            // Supprimer la clé étrangère puis la colonne
            if (Schema::hasColumn('interventions', 'client_id')) {
                // Supprimer la clé étrangère (nom par défaut: table_client_id_foreign)
                $table->dropForeign(['client_id']);
                $table->dropColumn('client_id');
            }
        });
    }
};
