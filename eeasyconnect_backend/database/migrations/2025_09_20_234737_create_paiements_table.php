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
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('facture_id');
            $table->decimal('montant', 10, 2);
            $table->date('date_paiement');
            $table->enum('type_paiement', ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money']);
            $table->enum('statut', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->string('reference')->unique();
            $table->text('commentaire')->nullable();
            $table->unsignedBigInteger('user_id'); // Enregistré par
            $table->timestamps();

            $table->foreign('facture_id')->references('id')->on('factures')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('paiements');
    }
};
