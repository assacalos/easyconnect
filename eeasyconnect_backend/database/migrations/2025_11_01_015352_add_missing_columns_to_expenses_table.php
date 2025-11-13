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
        Schema::table('expenses', function (Blueprint $table) {
            // Ajouter employee_id si n'existe pas (remplace user_id dans le nouveau modèle)
            if (!Schema::hasColumn('expenses', 'employee_id')) {
                $table->unsignedBigInteger('employee_id')->nullable()->after('expense_category_id');
            }
            
            // Ajouter comptable_id si n'existe pas
            if (!Schema::hasColumn('expenses', 'comptable_id')) {
                $table->unsignedBigInteger('comptable_id')->nullable()->after('employee_id');
            }
            
            // Ajouter expense_number si n'existe pas
            if (!Schema::hasColumn('expenses', 'expense_number')) {
                $table->string('expense_number')->nullable()->after('id');
            }
            
            // Ajouter submission_date si n'existe pas
            if (!Schema::hasColumn('expenses', 'submission_date')) {
                $table->date('submission_date')->nullable()->after('expense_date');
            }
            
            // Ajouter currency si n'existe pas
            if (!Schema::hasColumn('expenses', 'currency')) {
                $table->string('currency', 4)->default('FCFA')->after('amount');
            }
            
            // Ajouter justification si n'existe pas
            if (!Schema::hasColumn('expenses', 'justification')) {
                $table->text('justification')->nullable()->after('description');
            }
            
            // Ajouter receipt_path si n'existe pas
            if (!Schema::hasColumn('expenses', 'receipt_path')) {
                $table->string('receipt_path')->nullable()->after('justification');
            }
            
            // Ajouter rejection_reason si n'existe pas
            if (!Schema::hasColumn('expenses', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('status');
            }
            
            // Ajouter approval_history si n'existe pas
            if (!Schema::hasColumn('expenses', 'approval_history')) {
                $table->json('approval_history')->nullable()->after('rejection_reason');
            }
            
            // Ajouter approved_at si n'existe pas
            if (!Schema::hasColumn('expenses', 'approved_at')) {
                $table->timestamp('approved_at')->nullable()->after('approval_history');
            }
            
            // Ajouter approved_by si n'existe pas
            if (!Schema::hasColumn('expenses', 'approved_by')) {
                $table->unsignedBigInteger('approved_by')->nullable()->after('approved_at');
            }
            
            // Ajouter rejected_at si n'existe pas
            if (!Schema::hasColumn('expenses', 'rejected_at')) {
                $table->timestamp('rejected_at')->nullable()->after('approved_by');
            }
            
            // Ajouter rejected_by si n'existe pas
            if (!Schema::hasColumn('expenses', 'rejected_by')) {
                $table->unsignedBigInteger('rejected_by')->nullable()->after('rejected_at');
            }
            
            // Ajouter paid_at si n'existe pas
            if (!Schema::hasColumn('expenses', 'paid_at')) {
                $table->timestamp('paid_at')->nullable()->after('rejected_by');
            }
            
            // Ajouter paid_by si n'existe pas
            if (!Schema::hasColumn('expenses', 'paid_by')) {
                $table->unsignedBigInteger('paid_by')->nullable()->after('paid_at');
            }
        });
        
        // Ajouter les clés étrangères après avoir ajouté les colonnes
        Schema::table('expenses', function (Blueprint $table) {
            // Clé étrangère pour employee_id
            if (Schema::hasColumn('expenses', 'employee_id')) {
                try {
                    $table->foreign('employee_id')->references('id')->on('users')->onDelete('set null');
                } catch (\Exception $e) {
                    // La clé existe peut-être déjà
                }
            }
            
            // Clé étrangère pour comptable_id
            if (Schema::hasColumn('expenses', 'comptable_id')) {
                try {
                    $table->foreign('comptable_id')->references('id')->on('users')->onDelete('set null');
                } catch (\Exception $e) {
                    // La clé existe peut-être déjà
                }
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('expenses', function (Blueprint $table) {
            // Supprimer les clés étrangères d'abord
            if (Schema::hasColumn('expenses', 'employee_id')) {
                $table->dropForeign(['employee_id']);
            }
            if (Schema::hasColumn('expenses', 'comptable_id')) {
                $table->dropForeign(['comptable_id']);
            }
            
            // Supprimer les colonnes
            $columnsToDrop = [
                'employee_id',
                'comptable_id',
                'expense_number',
                'submission_date',
                'currency',
                'justification',
                'receipt_path',
                'rejection_reason',
                'approval_history',
                'approved_at',
                'approved_by',
                'rejected_at',
                'rejected_by',
                'paid_at',
                'paid_by'
            ];
            
            foreach ($columnsToDrop as $column) {
                if (Schema::hasColumn('expenses', $column)) {
                    $table->dropColumn($column);
                }
            }
        });
    }
};
