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
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->string('payment_number')->unique();
            $table->enum('type', ['one_time', 'monthly'])->default('one_time');
            $table->unsignedBigInteger('client_id');
            $table->unsignedBigInteger('comptable_id'); // Comptable responsable
            $table->date('payment_date');
            $table->date('due_date')->nullable();
            $table->enum('status', ['draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'])->default('draft');
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('EUR');
            $table->enum('payment_method', ['bank_transfer', 'check', 'cash', 'card', 'direct_debit'])->default('bank_transfer');
            $table->text('description')->nullable();
            $table->text('notes')->nullable();
            $table->string('reference')->nullable();
            $table->unsignedBigInteger('payment_schedule_id')->nullable(); // Pour les paiements mensuels
            $table->timestamp('submitted_at')->nullable();
            $table->timestamp('approved_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->foreign('client_id')->references('id')->on('clients')->onDelete('cascade');
            $table->foreign('comptable_id')->references('id')->on('users')->onDelete('cascade');
            // $table->foreign('payment_schedule_id')->references('id')->on('payment_schedules')->onDelete('set null');
            $table->index(['client_id', 'payment_date']);
            $table->index(['comptable_id', 'status']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};