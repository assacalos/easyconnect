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
        Schema::table('employee_leaves', function (Blueprint $table) {
            // Ajouter le champ comments s'il n'existe pas
            if (!Schema::hasColumn('employee_leaves', 'comments')) {
                $table->text('comments')->nullable()->after('reason');
            }

            // Ajouter approved_by_name s'il n'existe pas
            if (!Schema::hasColumn('employee_leaves', 'approved_by_name')) {
                $table->string('approved_by_name', 255)->nullable()->after('approved_by');
            }

            // Ajouter updated_at s'il n'existe pas
            if (!Schema::hasColumn('employee_leaves', 'updated_at')) {
                $table->timestamp('updated_at')->nullable()->after('created_at');
            }
        });

        // Modifier l'enum type pour ajouter 'emergency'
        DB::statement("ALTER TABLE employee_leaves MODIFY COLUMN type ENUM('annual', 'sick', 'maternity', 'paternity', 'personal', 'emergency', 'unpaid')");

        // Modifier l'enum status pour ajouter 'cancelled'
        DB::statement("ALTER TABLE employee_leaves MODIFY COLUMN status ENUM('pending', 'approved', 'rejected', 'cancelled') DEFAULT 'pending'");
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('employee_leaves', function (Blueprint $table) {
            if (Schema::hasColumn('employee_leaves', 'comments')) {
                $table->dropColumn('comments');
            }
            if (Schema::hasColumn('employee_leaves', 'approved_by_name')) {
                $table->dropColumn('approved_by_name');
            }
            if (Schema::hasColumn('employee_leaves', 'updated_at')) {
                $table->dropColumn('updated_at');
            }
        });

        // Revenir aux enums précédents
        DB::statement("ALTER TABLE employee_leaves MODIFY COLUMN type ENUM('annual', 'sick', 'maternity', 'paternity', 'personal', 'unpaid')");
        DB::statement("ALTER TABLE employee_leaves MODIFY COLUMN status ENUM('pending', 'approved', 'rejected') DEFAULT 'pending'");
    }
};
