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
        Schema::table('reportings', function (Blueprint $table) {
            // Changer le default de 'draft' à 'submitted'
            $table->enum('status', ['draft', 'submitted', 'approved'])->default('submitted')->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reportings', function (Blueprint $table) {
            // Revenir au default 'draft'
            $table->enum('status', ['draft', 'submitted', 'approved'])->default('draft')->change();
        });
    }
};
