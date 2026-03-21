<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (Schema::hasTable('inventory_sessions')) {
            return;
        }
        Schema::create('inventory_sessions', function (Blueprint $table) {
            $table->id();
            $table->date('date');
            $table->string('depot')->nullable()->comment('Dépôt / entrepôt');
            $table->enum('status', ['en_cours', 'cloture'])->default('en_cours');
            $table->unsignedBigInteger('created_by')->nullable();
            $table->unsignedBigInteger('closed_by')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamps();

            $table->foreign('created_by')->references('id')->on('users')->onDelete('set null');
            $table->foreign('closed_by')->references('id')->on('users')->onDelete('set null');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_sessions');
    }
};
