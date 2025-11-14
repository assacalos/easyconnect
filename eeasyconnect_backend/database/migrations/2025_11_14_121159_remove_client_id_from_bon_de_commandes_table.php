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
        Schema::table('bon_de_commandes', function (Blueprint $table) {
            // Supprimer la clé étrangère d'abord
            $table->dropForeign(['client_id']);
            // Supprimer la colonne
            $table->dropColumn('client_id');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('bon_de_commandes', function (Blueprint $table) {
            // Recréer la colonne
            $table->unsignedBigInteger('client_id')->after('id');
            // Recréer la clé étrangère
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
        });
    }
};
