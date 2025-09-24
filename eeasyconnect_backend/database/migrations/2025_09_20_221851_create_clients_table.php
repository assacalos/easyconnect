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
        Schema::create('clients', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade');
            $table->string('nom');
            $table->string('prenom');
            $table->string('email')->unique();
            $table->string('contact');
            $table->string('adresse');
            $table->string('situation_geographique');
            $table->string('nom_entreprise');
            $table->text('commentaire')->nullable();
            $table->integer('status'); //0 = en attente | 1 = valide | 2 = rejete
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('clients');
    }
};
