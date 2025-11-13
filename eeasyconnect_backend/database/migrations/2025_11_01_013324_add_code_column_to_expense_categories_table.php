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
        Schema::table('expense_categories', function (Blueprint $table) {
            // Ajouter les colonnes manquantes pour correspondre au modèle ExpenseCategory
            if (!Schema::hasColumn('expense_categories', 'code')) {
                $table->string('code')->nullable()->after('name');
            }
            if (!Schema::hasColumn('expense_categories', 'approval_limit')) {
                $table->decimal('approval_limit', 10, 2)->nullable()->after('description');
            }
            if (!Schema::hasColumn('expense_categories', 'requires_approval')) {
                $table->boolean('requires_approval')->default(true)->after('approval_limit');
            }
            if (!Schema::hasColumn('expense_categories', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('requires_approval');
            }
            if (!Schema::hasColumn('expense_categories', 'approval_workflow')) {
                $table->json('approval_workflow')->nullable()->after('is_active');
            }
            
            // Si la colonne status existe et qu'on veut la remplacer par is_active
            // On peut la garder pour compatibilité mais utiliser is_active de préférence
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('expense_categories', function (Blueprint $table) {
            if (Schema::hasColumn('expense_categories', 'code')) {
                $table->dropColumn('code');
            }
            if (Schema::hasColumn('expense_categories', 'approval_limit')) {
                $table->dropColumn('approval_limit');
            }
            if (Schema::hasColumn('expense_categories', 'requires_approval')) {
                $table->dropColumn('requires_approval');
            }
            if (Schema::hasColumn('expense_categories', 'is_active')) {
                $table->dropColumn('is_active');
            }
            if (Schema::hasColumn('expense_categories', 'approval_workflow')) {
                $table->dropColumn('approval_workflow');
            }
        });
    }
};
