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
        // Vérifier si la colonne first_name existe déjà
        $hasColumns = false;
        try {
            $columns = DB::select("SHOW COLUMNS FROM employees");
            $columnNames = array_column($columns, 'Field');
            $hasColumns = in_array('first_name', $columnNames);
        } catch (\Exception $e) {
            // Table n'existe pas ou erreur
        }

        if (!$hasColumns) {
            Schema::table('employees', function (Blueprint $table) {
                $table->string('first_name', 255)->after('id');
                $table->string('last_name', 255)->after('first_name');
                $table->string('email', 255)->unique()->after('last_name');
                $table->string('phone', 50)->nullable()->after('email');
                $table->text('address')->nullable()->after('phone');
                $table->date('birth_date')->nullable()->after('address');
                $table->enum('gender', ['male', 'female', 'other'])->nullable()->after('birth_date');
                $table->enum('marital_status', ['single', 'married', 'divorced', 'widowed'])->nullable()->after('gender');
                $table->string('nationality', 100)->nullable()->after('marital_status');
                $table->string('id_number', 50)->nullable()->after('nationality');
                $table->string('social_security_number', 50)->nullable()->after('id_number');
                $table->string('position', 255)->nullable()->after('social_security_number');
                $table->string('department', 255)->nullable()->after('position');
                $table->string('manager', 255)->nullable()->after('department');
                $table->date('hire_date')->nullable()->after('manager');
                $table->date('contract_start_date')->nullable()->after('hire_date');
                $table->date('contract_end_date')->nullable()->after('contract_start_date');
                $table->enum('contract_type', ['permanent', 'temporary', 'internship', 'consultant'])->nullable()->after('contract_end_date');
                $table->decimal('salary', 10, 2)->nullable()->after('contract_type');
                $table->string('currency', 10)->default('fcfa')->after('salary');
                $table->enum('work_schedule', ['full_time', 'part_time', 'flexible', 'shift'])->nullable()->after('currency');
                $table->enum('status', ['active', 'inactive', 'terminated', 'on_leave'])->default('active')->after('work_schedule');
                $table->string('profile_picture', 255)->nullable()->after('status');
                $table->text('notes')->nullable()->after('profile_picture');
                $table->unsignedBigInteger('created_by')->nullable()->after('notes');
                $table->unsignedBigInteger('updated_by')->nullable()->after('created_by');
            });

            // Ajouter les index
            Schema::table('employees', function (Blueprint $table) {
                $table->index('email');
                $table->index('department');
                $table->index('position');
                $table->index('status');
                $table->index('hire_date');
            });

            // Ajouter les clés étrangères
            Schema::table('employees', function (Blueprint $table) {
                $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
                $table->foreign('updated_by')->references('id')->on('users')->onDelete('set null');
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
