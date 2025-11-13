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
        if (Schema::hasColumn('expenses', 'category_id') && !Schema::hasColumn('expenses', 'expense_category_id')) {
            // Renommer la colonne category_id en expense_category_id avec ALTER TABLE
            DB::statement('ALTER TABLE expenses CHANGE category_id expense_category_id BIGINT UNSIGNED NOT NULL');
        } elseif (!Schema::hasColumn('expenses', 'expense_category_id')) {
            // Ajouter la colonne si elle n'existe pas
            Schema::table('expenses', function (Blueprint $table) {
                $table->unsignedBigInteger('expense_category_id')->nullable()->after('id');
            });
            // Ajouter la clé étrangère
            Schema::table('expenses', function (Blueprint $table) {
                $table->foreign('expense_category_id')->references('id')->on('expense_categories')->onDelete('cascade');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        if (Schema::hasColumn('expenses', 'expense_category_id') && !Schema::hasColumn('expenses', 'category_id')) {
            Schema::table('expenses', function (Blueprint $table) {
                $table->renameColumn('expense_category_id', 'category_id');
            });
        }
    }
};
