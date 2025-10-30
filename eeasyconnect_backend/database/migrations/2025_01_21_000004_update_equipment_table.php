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
        Schema::table('equipment_new', function (Blueprint $table) {
            // Ajouter les colonnes manquantes
            if (!Schema::hasColumn('equipment_new', 'department')) {
                $table->string('department')->nullable()->after('location');
            }
            if (!Schema::hasColumn('equipment_new', 'assigned_to')) {
                $table->string('assigned_to')->nullable()->after('department');
            }
            if (!Schema::hasColumn('equipment_new', 'current_value')) {
                $table->decimal('current_value', 10, 2)->nullable()->after('purchase_price');
            }
            if (!Schema::hasColumn('equipment_new', 'supplier')) {
                $table->string('supplier')->nullable()->after('current_value');
            }
            if (!Schema::hasColumn('equipment_new', 'attachments')) {
                $table->json('attachments')->nullable()->after('notes');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('equipment_new', function (Blueprint $table) {
            $table->dropColumn([
                'department',
                'assigned_to', 
                'current_value',
                'supplier',
                'attachments'
            ]);
        });
    }
};

