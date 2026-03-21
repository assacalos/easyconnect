<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Rappels personnels du technicien : piles à recharger, radio en maintenance, etc.
     * Associés à une entreprise (client), avec date limite et alerte J-1, J-2 ou J-3.
     */
    public function up(): void
    {
        if (Schema::hasTable('technician_reminders')) {
            return;
        }

        Schema::create('technician_reminders', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('user_id')->comment('Technicien propriétaire du rappel');
            $table->string('title'); // ex: "Piles à recharger", "Radio en maintenance"
            $table->text('notes')->nullable();
            $table->unsignedBigInteger('client_id')->nullable()->comment('Client/entreprise concernée');
            $table->string('company_name')->nullable()->comment('Nom entreprise si pas de client lié');
            $table->date('due_date')->comment('Date limite à respecter');
            $table->unsignedTinyInteger('remind_days_before')->default(1)->comment('1, 2 ou 3 jours avant');
            $table->string('status', 20)->default('pending'); // pending, done, cancelled
            $table->timestamp('reminder_sent_at')->nullable()->comment('Dernier envoi de rappel (évite doublons)');
            $table->timestamps();

            $table->foreign('user_id')->references('id')->on('users')->onDelete('cascade');
            $table->foreign('client_id')->references('id')->on('clients')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('technician_reminders');
    }
};
