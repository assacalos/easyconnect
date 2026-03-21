<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('inventory_session_items', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('inventory_session_id');
            $table->unsignedBigInteger('stock_id');
            $table->decimal('quantity_theoretical', 12, 3)->default(0)->comment('Quantité théorique (stock actuel au moment de la session)');
            $table->decimal('quantity_counted', 12, 3)->nullable()->comment('Quantité comptée');
            $table->timestamps();

            $table->foreign('inventory_session_id')->references('id')->on('inventory_sessions')->onDelete('cascade');
            $table->foreign('stock_id')->references('id')->on('stocks')->onDelete('cascade');
            $table->unique(['inventory_session_id', 'stock_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inventory_session_items');
    }
};
