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
        Schema::create('bordereaus', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('client_id')->constrained()->onDelete('cascade');
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->date('date_creation');
            $table->date('date_validation')->nullable();
            $table->text('notes')->nullable();
            $table->decimal('remise_globale', 8, 2)->nullable();
            $table->decimal('tva', 5, 2)->default(20);
            $table->text('conditions')->nullable();
            $table->tinyInteger('status')->default(0); // 0:brouillon,1:soumis,2:validé,3:rejeté
            $table->text('commentaire')->nullable();
            $table->timestamps();

            
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bordereaus');
    }
};
