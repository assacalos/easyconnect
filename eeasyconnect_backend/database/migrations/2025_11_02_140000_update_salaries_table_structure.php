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
        // Renommer user_id en hr_id si nécessaire
        if (Schema::hasColumn('salaries', 'user_id') && !Schema::hasColumn('salaries', 'hr_id')) {
            // Supprimer la clé étrangère existante
            try {
                DB::statement('ALTER TABLE salaries DROP FOREIGN KEY salaries_user_id_foreign');
            } catch (\Exception $e) {
                // Essayer d'autres noms possibles
                try {
                    $foreignKeys = DB::select("
                        SELECT CONSTRAINT_NAME 
                        FROM information_schema.KEY_COLUMN_USAGE 
                        WHERE TABLE_SCHEMA = DATABASE()
                        AND TABLE_NAME = 'salaries'
                        AND COLUMN_NAME = 'user_id'
                        AND CONSTRAINT_NAME != 'PRIMARY'
                    ");
                    
                    foreach ($foreignKeys as $fk) {
                        DB::statement("ALTER TABLE salaries DROP FOREIGN KEY {$fk->CONSTRAINT_NAME}");
                    }
                } catch (\Exception $e2) {
                    // Ignorer
                }
            }
            
            // Renommer la colonne (utiliser SQL direct car renameColumn peut ne pas fonctionner)
            DB::statement('ALTER TABLE salaries CHANGE user_id hr_id BIGINT UNSIGNED NOT NULL');
            
            // Recréer la clé étrangère
            DB::statement('ALTER TABLE salaries ADD CONSTRAINT salaries_hr_id_foreign 
                          FOREIGN KEY (hr_id) REFERENCES users(id) ON DELETE CASCADE');
        }
        
        Schema::table('salaries', function (Blueprint $table) {
            
            // Supprimer total_salary si elle existe (remplacé par gross_salary et net_salary)
            if (Schema::hasColumn('salaries', 'total_salary')) {
                $table->dropColumn('total_salary');
            }
            
            // Ajouter les colonnes manquantes si elles n'existent pas
            
            // salary_number
            if (!Schema::hasColumn('salaries', 'salary_number')) {
                $table->string('salary_number')->unique()->nullable()->after('id');
            }
            
            // period
            if (!Schema::hasColumn('salaries', 'period')) {
                $table->string('period')->nullable()->after('hr_id');
            }
            
            // period_start
            if (!Schema::hasColumn('salaries', 'period_start')) {
                $table->date('period_start')->nullable()->after('period');
            }
            
            // period_end
            if (!Schema::hasColumn('salaries', 'period_end')) {
                $table->date('period_end')->nullable()->after('period_start');
            }
            
            // gross_salary
            if (!Schema::hasColumn('salaries', 'gross_salary')) {
                $table->decimal('gross_salary', 10, 2)->default(0)->after('base_salary');
            }
            
            // net_salary
            if (!Schema::hasColumn('salaries', 'net_salary')) {
                $table->decimal('net_salary', 10, 2)->default(0)->after('gross_salary');
            }
            
            // total_allowances
            if (!Schema::hasColumn('salaries', 'total_allowances')) {
                $table->decimal('total_allowances', 10, 2)->default(0)->after('net_salary');
            }
            
            // total_deductions
            if (!Schema::hasColumn('salaries', 'total_deductions')) {
                $table->decimal('total_deductions', 10, 2)->default(0)->after('total_allowances');
            }
            
            // total_taxes
            if (!Schema::hasColumn('salaries', 'total_taxes')) {
                $table->decimal('total_taxes', 10, 2)->default(0)->after('total_deductions');
            }
            
            // total_social_security
            if (!Schema::hasColumn('salaries', 'total_social_security')) {
                $table->decimal('total_social_security', 10, 2)->default(0)->after('total_taxes');
            }
            
            // notes
            if (!Schema::hasColumn('salaries', 'notes')) {
                $table->text('notes')->nullable()->after('status');
            }
            
            // salary_breakdown (JSON)
            if (!Schema::hasColumn('salaries', 'salary_breakdown')) {
                $table->json('salary_breakdown')->nullable()->after('notes');
            }
            
            // components (JSON)
            if (!Schema::hasColumn('salaries', 'components')) {
                $table->json('components')->nullable()->after('salary_breakdown');
            }
            
            // calculated_at
            if (!Schema::hasColumn('salaries', 'calculated_at')) {
                $table->timestamp('calculated_at')->nullable()->after('components');
            }
            
            // approved_at
            if (!Schema::hasColumn('salaries', 'approved_at')) {
                $table->timestamp('approved_at')->nullable()->after('calculated_at');
            }
            
            // approved_by
            if (!Schema::hasColumn('salaries', 'approved_by')) {
                $table->unsignedBigInteger('approved_by')->nullable()->after('approved_at');
                $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
            }
            
            // paid_at
            if (!Schema::hasColumn('salaries', 'paid_at')) {
                $table->timestamp('paid_at')->nullable()->after('approved_by');
            }
            
            // paid_by
            if (!Schema::hasColumn('salaries', 'paid_by')) {
                $table->unsignedBigInteger('paid_by')->nullable()->after('paid_at');
                $table->foreign('paid_by')->references('id')->on('users')->onDelete('set null');
            }
        });
        
        // Modifier le type de status si nécessaire (enum -> string)
        // Note: MySQL/MariaDB nécessite souvent de supprimer et recréer l'enum
        // On va plutôt utiliser un string pour plus de flexibilité
        try {
            DB::statement("ALTER TABLE salaries MODIFY COLUMN status VARCHAR(50) DEFAULT 'draft'");
        } catch (\Exception $e) {
            // Si la modification échoue, c'est peut-être que c'est déjà un string
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('salaries', function (Blueprint $table) {
            // Supprimer les colonnes ajoutées
            $columnsToDrop = [
                'salary_number', 'period', 'period_start', 'period_end',
                'gross_salary', 'net_salary', 'total_allowances', 'total_deductions',
                'total_taxes', 'total_social_security', 'notes', 'salary_breakdown',
                'components', 'calculated_at', 'approved_at', 'approved_by',
                'paid_at', 'paid_by'
            ];
            
            foreach ($columnsToDrop as $column) {
                if (Schema::hasColumn('salaries', $column)) {
                    // Supprimer les clés étrangères d'abord
                    if ($column === 'approved_by' || $column === 'paid_by') {
                        try {
                            $table->dropForeign([$column]);
                        } catch (\Exception $e) {
                            // Ignorer si la clé n'existe pas
                        }
                    }
                    $table->dropColumn($column);
                }
            }
            
            // Renommer hr_id en user_id (utiliser SQL direct)
            if (Schema::hasColumn('salaries', 'hr_id') && !Schema::hasColumn('salaries', 'user_id')) {
                try {
                    DB::statement('ALTER TABLE salaries DROP FOREIGN KEY salaries_hr_id_foreign');
                } catch (\Exception $e) {
                    // Ignorer si la clé n'existe pas
                }
                DB::statement('ALTER TABLE salaries CHANGE hr_id user_id BIGINT UNSIGNED NOT NULL');
                DB::statement('ALTER TABLE salaries ADD CONSTRAINT salaries_user_id_foreign 
                              FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE');
            }
            
            // Recréer total_salary
            if (!Schema::hasColumn('salaries', 'total_salary')) {
                $table->decimal('total_salary', 10, 2)->nullable()->after('base_salary');
            }
        });
    }
};
