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
        // Vérifier si la colonne existe avant de la supprimer
        if (Schema::hasColumn('salaries', 'employee_id')) {
            Schema::table('salaries', function (Blueprint $table) {
                // Supprimer la clé étrangère si elle existe
                // Laravel génère généralement: salaries_employee_id_foreign
                try {
                    $table->dropForeign(['employee_id']);
                } catch (\Exception $e) {
                    // Si la clé étrangère n'existe pas avec ce nom, essayer avec le nom Laravel standard
                    try {
                        DB::statement('ALTER TABLE salaries DROP FOREIGN KEY salaries_employee_id_foreign');
                    } catch (\Exception $e2) {
                        // La clé étrangère n'existe pas, on continue
                    }
                }
                
                // Supprimer la colonne employee_id
                $table->dropColumn('employee_id');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('salaries', function (Blueprint $table) {
            // Recréer la colonne employee_id
            $table->unsignedBigInteger('employee_id')->nullable()->after('id');
            
            // Recréer la clé étrangère
            $table->foreign('employee_id')
                  ->references('id')
                  ->on('users')
                  ->onDelete('cascade');
        });
    }
};
