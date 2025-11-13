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
        if (Schema::hasColumn('expenses', 'status')) {
            // Mapper les anciennes valeurs vers les nouvelles
            DB::statement("UPDATE expenses SET status = 'draft' WHERE status = 'en_attente'");
            DB::statement("UPDATE expenses SET status = 'approved' WHERE status = 'valide'");
            DB::statement("UPDATE expenses SET status = 'rejected' WHERE status = 'rejete'");
            
            // Modifier l'ENUM pour inclure les nouveaux statuts
            DB::statement("ALTER TABLE expenses MODIFY COLUMN status ENUM('draft', 'submitted', 'under_review', 'approved', 'rejected', 'paid') DEFAULT 'draft'");
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('expenses', 'status')) {
            // Mapper les nouvelles valeurs vers les anciennes
            DB::statement("UPDATE expenses SET status = 'en_attente' WHERE status IN ('draft', 'submitted', 'under_review')");
            DB::statement("UPDATE expenses SET status = 'valide' WHERE status = 'approved'");
            DB::statement("UPDATE expenses SET status = 'rejete' WHERE status = 'rejected'");
            
            // Remettre l'ancien ENUM
            DB::statement("ALTER TABLE expenses MODIFY COLUMN status ENUM('en_attente', 'valide', 'rejete') DEFAULT 'en_attente'");
        }
    }
};
