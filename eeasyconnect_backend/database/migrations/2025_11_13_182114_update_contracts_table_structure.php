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
        // Vérifier si la colonne contract_number existe déjà
        $hasColumns = false;
        try {
            $columns = DB::select("SHOW COLUMNS FROM contracts");
            $columnNames = array_column($columns, 'Field');
            $hasColumns = in_array('contract_number', $columnNames);
        } catch (\Exception $e) {
            // Table n'existe pas ou erreur
        }

        if (!$hasColumns) {
            Schema::table('contracts', function (Blueprint $table) {
                $table->string('contract_number', 100)->unique()->after('id');
                $table->unsignedBigInteger('employee_id')->after('contract_number');
                $table->string('employee_name', 255)->nullable()->after('employee_id');
                $table->string('employee_email', 255)->nullable()->after('employee_name');
                $table->enum('contract_type', ['permanent', 'fixed_term', 'temporary', 'internship', 'consultant'])->after('employee_email');
                $table->string('position', 100)->after('contract_type');
                $table->string('department', 100)->after('position');
                $table->string('job_title', 100)->after('department');
                $table->text('job_description')->after('job_title');
                $table->decimal('gross_salary', 10, 2)->after('job_description');
                $table->decimal('net_salary', 10, 2)->after('gross_salary');
                $table->string('salary_currency', 10)->default('FCFA')->after('net_salary');
                $table->enum('payment_frequency', ['monthly', 'weekly', 'daily', 'hourly'])->after('salary_currency');
                $table->date('start_date')->after('payment_frequency');
                $table->date('end_date')->nullable()->after('start_date');
                $table->integer('duration_months')->nullable()->after('end_date');
                $table->string('work_location', 255)->after('duration_months');
                $table->enum('work_schedule', ['full_time', 'part_time', 'flexible'])->after('work_location');
                $table->integer('weekly_hours')->nullable()->after('work_schedule');
                $table->enum('probation_period', ['none', '1_month', '3_months', '6_months'])->nullable()->after('weekly_hours');
                $table->string('reporting_manager', 255)->nullable()->after('probation_period');
                $table->text('health_insurance')->nullable()->after('reporting_manager');
                $table->text('retirement_plan')->nullable()->after('health_insurance');
                $table->integer('vacation_days')->nullable()->after('retirement_plan');
                $table->text('other_benefits')->nullable()->after('vacation_days');
                $table->enum('status', ['draft', 'pending', 'active', 'expired', 'terminated', 'cancelled'])->default('draft')->after('other_benefits');
                $table->text('termination_reason')->nullable()->after('status');
                $table->date('termination_date')->nullable()->after('termination_reason');
                $table->text('notes')->nullable()->after('termination_date');
                $table->string('contract_template', 255)->nullable()->after('notes');
                $table->timestamp('approved_at')->nullable()->after('contract_template');
                $table->unsignedBigInteger('approved_by')->nullable()->after('approved_at');
                $table->text('rejection_reason')->nullable()->after('approved_by');
                $table->unsignedBigInteger('created_by')->nullable()->after('rejection_reason');
                $table->unsignedBigInteger('updated_by')->nullable()->after('created_by');
            });

            // Ajouter les index
            Schema::table('contracts', function (Blueprint $table) {
                $table->index('contract_number');
                $table->index('employee_id');
                $table->index('contract_type');
                $table->index('department');
                $table->index('status');
                $table->index('start_date');
                $table->index('end_date');
            });

            // Ajouter les clés étrangères
            Schema::table('contracts', function (Blueprint $table) {
                $table->foreign('employee_id')->references('id')->on('employees')->onDelete('cascade');
                $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('approved_by')->references('id')->on('users')->onDelete('set null');
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Ne rien faire en rollback pour éviter de perdre des données
    }
};
