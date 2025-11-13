<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // Vérifier si la table stocks existe et a category_id
        if (Schema::hasTable('stocks') && Schema::hasColumn('stocks', 'category_id')) {
            // Récupérer les catégories existantes pour les migrer
            if (Schema::hasTable('stock_categories')) {
                $categories = DB::table('stock_categories')->get();
                $categoryMap = [];
                foreach ($categories as $cat) {
                    $categoryMap[$cat->id] = $cat->name;
                }
            } else {
                $categoryMap = [];
            }
            
            // Ajouter la nouvelle colonne category (temporairement nullable)
            Schema::table('stocks', function (Blueprint $table) {
                $table->string('category')->nullable()->after('id');
            });
            
            // Migrer les données : copier le nom de la catégorie dans le nouveau champ
            if (!empty($categoryMap)) {
                foreach ($categoryMap as $categoryId => $categoryName) {
                    DB::table('stocks')
                        ->where('category_id', $categoryId)
                        ->update(['category' => $categoryName]);
                }
            }
            
            // Rendre category obligatoire
            Schema::table('stocks', function (Blueprint $table) {
                $table->string('category')->nullable(false)->change();
            });
            
            // Supprimer la clé étrangère si elle existe
            try {
                Schema::table('stocks', function (Blueprint $table) {
                    $table->dropForeign(['category_id']);
                });
            } catch (\Exception $e) {
                // La clé étrangère n'existe peut-être pas, on continue
            }
            
            // Supprimer l'ancienne colonne
            Schema::table('stocks', function (Blueprint $table) {
                $table->dropColumn('category_id');
            });
        }
        
        // Supprimer la table stock_categories si elle existe
        Schema::dropIfExists('stock_categories');
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Recréer la table stock_categories
        if (!Schema::hasTable('stock_categories')) {
            Schema::create('stock_categories', function (Blueprint $table) {
                $table->id();
                $table->string('name');
                $table->text('description')->nullable();
                $table->enum('status', ['en_attente', 'valide', 'rejete'])->default('en_attente');
                $table->timestamps();
            });
        }
        
        // Si stocks existe avec category, recréer category_id
        if (Schema::hasTable('stocks') && Schema::hasColumn('stocks', 'category')) {
            // Récupérer les catégories uniques depuis stocks
            $categories = DB::table('stocks')->distinct()->pluck('category')->toArray();
            
            // Insérer les catégories dans stock_categories
            foreach ($categories as $categoryName) {
                DB::table('stock_categories')->insertOrIgnore([
                    'name' => $categoryName,
                    'status' => 'valide',
                    'created_at' => now(),
                    'updated_at' => now(),
                ]);
            }
            
            Schema::table('stocks', function (Blueprint $table) {
                // Ajouter category_id
                $table->unsignedBigInteger('category_id')->nullable()->after('id');
            });
            
            // Mapper les catégories
            $categoryMap = DB::table('stock_categories')->pluck('id', 'name')->toArray();
            foreach ($categoryMap as $categoryName => $categoryId) {
                DB::table('stocks')
                    ->where('category', $categoryName)
                    ->update(['category_id' => $categoryId]);
            }
            
            Schema::table('stocks', function (Blueprint $table) {
                $table->unsignedBigInteger('category_id')->nullable(false)->change();
                $table->foreign('category_id')->references('id')->on('stock_categories')->onDelete('cascade');
            });
            
            // Supprimer category
            Schema::table('stocks', function (Blueprint $table) {
                $table->dropColumn('category');
            });
        }
    }
};
