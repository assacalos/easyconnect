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
        Schema::table('salary_components', function (Blueprint $table) {
            // Ajouter is_active si n'existe pas
            if (!Schema::hasColumn('salary_components', 'is_active')) {
                $table->boolean('is_active')->default(true)->after('status');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('salary_components', function (Blueprint $table) {
            if (Schema::hasColumn('salary_components', 'is_active')) {
                $table->dropColumn('is_active');
            }
        });
    }
};
