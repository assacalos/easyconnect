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
        Schema::table('interventions', function (Blueprint $table) {
            // Vérifier si les colonnes existent avant de les ajouter
            if (!Schema::hasColumn('interventions', 'type')) {
                $table->string('type')->after('id'); // 'external' ou 'on_site'
            }
            if (!Schema::hasColumn('interventions', 'priority')) {
                $table->string('priority')->default('medium')->after('status'); // 'low', 'medium', 'high', 'urgent'
            }
            if (!Schema::hasColumn('interventions', 'start_date')) {
                $table->datetime('start_date')->nullable()->after('scheduled_date');
            }
            if (!Schema::hasColumn('interventions', 'end_date')) {
                $table->datetime('end_date')->nullable()->after('start_date');
            }
            if (!Schema::hasColumn('interventions', 'location')) {
                $table->string('location')->nullable()->after('end_date');
            }
            if (!Schema::hasColumn('interventions', 'client_name')) {
                $table->string('client_name')->nullable()->after('location');
            }
            if (!Schema::hasColumn('interventions', 'client_phone')) {
                $table->string('client_phone')->nullable()->after('client_name');
            }
            if (!Schema::hasColumn('interventions', 'client_email')) {
                $table->string('client_email')->nullable()->after('client_phone');
            }
            if (!Schema::hasColumn('interventions', 'equipment')) {
                $table->string('equipment')->nullable()->after('client_email');
            }
            if (!Schema::hasColumn('interventions', 'problem_description')) {
                $table->text('problem_description')->nullable()->after('equipment');
            }
            if (!Schema::hasColumn('interventions', 'solution')) {
                $table->text('solution')->nullable()->after('problem_description');
            }
            if (!Schema::hasColumn('interventions', 'notes')) {
                $table->text('notes')->nullable()->after('solution');
            }
            if (!Schema::hasColumn('interventions', 'attachments')) {
                $table->json('attachments')->nullable()->after('notes');
            }
            if (!Schema::hasColumn('interventions', 'estimated_duration')) {
                $table->decimal('estimated_duration', 8, 2)->nullable()->after('attachments');
            }
            if (!Schema::hasColumn('interventions', 'actual_duration')) {
                $table->decimal('actual_duration', 8, 2)->nullable()->after('estimated_duration');
            }
            if (!Schema::hasColumn('interventions', 'created_by')) {
                $table->unsignedBigInteger('created_by')->nullable()->after('actual_duration');
            }
            if (!Schema::hasColumn('interventions', 'approved_by')) {
                $table->unsignedBigInteger('approved_by')->nullable()->after('created_by');
            }
            if (!Schema::hasColumn('interventions', 'approved_at')) {
                $table->datetime('approved_at')->nullable()->after('approved_by');
            }
            if (!Schema::hasColumn('interventions', 'rejection_reason')) {
                $table->text('rejection_reason')->nullable()->after('approved_at');
            }
            if (!Schema::hasColumn('interventions', 'completion_notes')) {
                $table->text('completion_notes')->nullable()->after('rejection_reason');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('interventions', function (Blueprint $table) {
            $table->dropColumn([
                'type', 'priority', 'start_date', 'end_date', 'location',
                'client_name', 'client_phone', 'client_email', 'equipment',
                'problem_description', 'solution', 'notes', 'attachments',
                'estimated_duration', 'actual_duration', 'created_by',
                'approved_by', 'approved_at', 'rejection_reason', 'completion_notes'
            ]);
        });
    }
};

