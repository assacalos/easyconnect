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
        // Supprimer les tables existantes et les recréer avec la structure consolidée
        Schema::dropIfExists('intervention_reports');
        Schema::dropIfExists('interventions');
        Schema::dropIfExists('intervention_types');
        
        // Créer les tables dans l'ordre correct
        Schema::create('intervention_types', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->timestamps();
        });

        Schema::create('interventions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('type_id');
            $table->unsignedBigInteger('client_id');
            $table->unsignedBigInteger('user_id');
            $table->string('title');
            $table->text('description');
            $table->date('scheduled_date');
            $table->date('completed_date')->nullable();
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->decimal('cost', 10, 2)->nullable();
            $table->timestamps();

            $table->foreign('type_id')->references('id')->on('intervention_types')->onDelete('cascade');
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });

        Schema::create('intervention_reports', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('intervention_id');
            $table->text('report_content');
            $table->json('attachments')->nullable();
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->unsignedBigInteger('user_id');
            $table->timestamps();

            $table->foreign('intervention_id')->references('id')->on('interventions')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('intervention_reports');
        Schema::dropIfExists('interventions');
        Schema::dropIfExists('intervention_types');
    }
};
