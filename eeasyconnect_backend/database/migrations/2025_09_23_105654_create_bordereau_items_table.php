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
        Schema::create('bordereau_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('bordereau_id')->constrained()->onDelete('cascade');
            $table->string('designation');
            $table->string('unite');
            $table->integer('quantite');
            $table->decimal('prix_unitaire', 10, 2);
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('bordereau_items');
    }
};
