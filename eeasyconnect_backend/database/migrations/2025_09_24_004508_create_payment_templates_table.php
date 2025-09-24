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
        Schema::create('payment_templates', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->text('description')->nullable();
            $table->enum('type', ['one_time', 'monthly']);
            $table->decimal('default_amount', 10, 2)->default(0);
            $table->enum('default_payment_method', ['bank_transfer', 'check', 'cash', 'card', 'direct_debit'])->default('bank_transfer');
            $table->integer('default_frequency')->nullable(); // Pour les paiements mensuels
            $table->longText('template'); // Template HTML/PDF
            $table->boolean('is_default')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_templates');
    }
};
