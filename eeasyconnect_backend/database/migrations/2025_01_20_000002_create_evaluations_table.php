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
        Schema::create('evaluations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Employé évalué
            $table->foreignId('evaluateur_id')->constrained('users'); // RH ou Manager qui évalue
            $table->string('type_evaluation'); // annuelle, trimestrielle, probation, etc.
            $table->date('date_evaluation');
            $table->date('periode_debut');
            $table->date('periode_fin');
            $table->json('criteres_evaluation'); // Critères d'évaluation (JSON)
            $table->decimal('note_globale', 4, 2); // Note sur 20 (max 99.99)
            $table->text('commentaires_evaluateur');
            $table->text('commentaires_employe')->nullable();
            $table->text('objectifs_futurs')->nullable();
            $table->string('statut')->default('en_cours'); // en_cours, finalisee, archivee
            $table->date('date_signature_employe')->nullable();
            $table->date('date_signature_evaluateur')->nullable();
            $table->boolean('confidentiel')->default(true);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('evaluations');
    }
};
