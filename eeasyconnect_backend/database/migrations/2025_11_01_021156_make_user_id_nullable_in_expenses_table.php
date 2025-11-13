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
        if (Schema::hasColumn('expenses', 'user_id')) {
            // Rendre la colonne user_id nullable (employee_id remplace user_id)
            // Mettre à jour les valeurs NULL avec employee_id si disponible
            DB::statement("UPDATE expenses SET user_id = employee_id WHERE user_id IS NULL AND employee_id IS NOT NULL");
            DB::statement('ALTER TABLE expenses MODIFY user_id BIGINT UNSIGNED NULL');
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('expenses', 'user_id')) {
            // Remettre user_id comme NOT NULL
            DB::statement("UPDATE expenses SET user_id = COALESCE(employee_id, 1) WHERE user_id IS NULL");
            DB::statement('ALTER TABLE expenses MODIFY user_id BIGINT UNSIGNED NOT NULL');
        }
    }
};
