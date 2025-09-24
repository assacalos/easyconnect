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
        Schema::create('conges', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('type_conge'); // annuel, maladie, maternite, paternite, formation, etc.
            $table->date('date_debut');
            $table->date('date_fin');
            $table->integer('nombre_jours');
            $table->text('motif');
            $table->string('statut')->default('en_attente'); // en_attente, approuve, rejete
            $table->text('commentaire_rh')->nullable();
            $table->foreignId('approuve_par')->nullable()->constrained('users');
            $table->timestamp('date_approbation')->nullable();
            $table->text('raison_rejet')->nullable();
            $table->boolean('urgent')->default(false);
            $table->string('piece_jointe')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('conges');
    }
};
