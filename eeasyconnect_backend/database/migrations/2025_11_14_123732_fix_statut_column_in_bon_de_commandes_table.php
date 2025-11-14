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
        // Vérifier si la colonne status existe
        if (Schema::hasColumn('bon_de_commandes', 'status')) {
            // Mapper les anciennes valeurs vers les nouvelles si nécessaire
            // 'rejete' n'est plus utilisé, on peut le mapper vers 'annule'
            DB::statement("UPDATE bon_de_commandes SET status = 'annule' WHERE status = 'rejete'");
            
            // Renommer la colonne status en statut et modifier l'enum
            DB::statement("ALTER TABLE bon_de_commandes CHANGE COLUMN status statut ENUM('en_attente', 'valide', 'en_cours', 'livre', 'annule') DEFAULT 'en_attente'");
        } elseif (!Schema::hasColumn('bon_de_commandes', 'statut')) {
            // Si la colonne statut n'existe pas du tout, la créer
            Schema::table('bon_de_commandes', function (Blueprint $table) {
                $table->enum('statut', ['en_attente', 'valide', 'en_cours', 'livre', 'annule'])->default('en_attente')->after('description');
            });
        } else {
            // Si la colonne statut existe déjà, juste modifier l'enum
            DB::statement("ALTER TABLE bon_de_commandes MODIFY COLUMN statut ENUM('en_attente', 'valide', 'en_cours', 'livre', 'annule') DEFAULT 'en_attente'");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Vérifier si la colonne statut existe
        if (Schema::hasColumn('bon_de_commandes', 'statut')) {
            // Mapper les valeurs vers l'ancien enum
            DB::statement("UPDATE bon_de_commandes SET statut = 'en_attente' WHERE statut IN ('en_cours', 'livre')");
            DB::statement("UPDATE bon_de_commandes SET statut = 'rejete' WHERE statut = 'annule'");
            
            // Renommer la colonne statut en status et remettre l'ancien enum
            DB::statement("ALTER TABLE bon_de_commandes CHANGE COLUMN statut status ENUM('en_attente', 'valide', 'rejete') DEFAULT 'en_attente'");
        }
    }
};
