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
        Schema::create('factures', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('client_id');
            $table->string('numero_facture')->unique();
            $table->date('date_facture');
            $table->date('date_echeance');
            $table->decimal('montant_ht', 10, 2);
            $table->decimal('tva', 5, 2)->default(18.0);
            $table->decimal('montant_ttc', 10, 2);
            $table->enum('statut', ['brouillon', 'envoyee', 'payee', 'en_retard', 'annulee'])->default('brouillon');
            $table->enum('type_paiement', ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money'])->nullable();
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('user_id'); // Créateur
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
        Schema::dropIfExists('factures');
    }
};
