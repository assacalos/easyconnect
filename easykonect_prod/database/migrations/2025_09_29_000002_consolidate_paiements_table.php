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
        // Supprimer la table existante et la recréer avec la structure consolidée
        Schema::dropIfExists('paiements');
        
        Schema::create('paiements', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('facture_id');
            $table->decimal('montant', 10, 2);
            $table->date('date_paiement');
            $table->enum('type_paiement', ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money']);
            $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
            $table->string('reference')->unique();
            $table->text('commentaire')->nullable();
            $table->unsignedBigInteger('user_id'); // Enregistré par
            
            // Champs pour la validation
            $table->unsignedBigInteger('validated_by')->nullable();
            $table->timestamp('validated_at')->nullable();
            $table->text('validation_comment')->nullable();
            
            // Champs pour le rejet
            $table->unsignedBigInteger('rejected_by')->nullable();
            $table->timestamp('rejected_at')->nullable();
            $table->string('rejection_reason')->nullable();
            $table->text('rejection_comment')->nullable();
            
            $table->timestamps();

            // Clés étrangères
            $table->foreign('facture_id')->references('id')->on('factures')->onDelete('cascade');
            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('validated_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('rejected_by')->references('id')->on('users')->onDelete('set null');
            
            // Index
            $table->index(['status', 'date_paiement']);
            $table->index(['facture_id']);
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
