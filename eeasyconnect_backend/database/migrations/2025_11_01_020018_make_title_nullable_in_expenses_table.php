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
        if (Schema::hasColumn('expenses', 'title')) {
            // Rendre la colonne title nullable
            DB::statement('ALTER TABLE expenses MODIFY title VARCHAR(255) NULL');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('expenses', 'title')) {
            // Remettre title comme NOT NULL (avec valeur par défaut pour les valeurs existantes)
            DB::statement("UPDATE expenses SET title = COALESCE(description, 'Dépense') WHERE title IS NULL");
            DB::statement('ALTER TABLE expenses MODIFY title VARCHAR(255) NOT NULL');
        }
    }
};
