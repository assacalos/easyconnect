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
        Schema::create('commandes_entreprise', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->unsignedBigInteger('client_id');
            $table->unsignedBigInteger('user_id'); // commercial
            $table->dateTime('date_creation');
            $table->dateTime('date_validation')->nullable();
            $table->dateTime('date_livraison_prevue')->nullable();
            $table->text('adresse_livraison')->nullable();
            $table->text('notes')->nullable();
            $table->decimal('remise_globale', 5, 2)->nullable(); // pourcentage
            $table->decimal('tva', 5, 2)->default(20.0); // pourcentage
            $table->text('conditions')->nullable();
            $table->tinyInteger('status')->default(1); // 1: soumis, 2: validé, 3: rejeté, 4: livré
            $table->text('commentaire_rejet')->nullable();
            $table->string('numero_facture')->nullable();
            $table->boolean('est_facture')->default(false);
            $table->boolean('est_livre')->default(false);
            $table->timestamps();

            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('commandes_entreprise');
    }
};
