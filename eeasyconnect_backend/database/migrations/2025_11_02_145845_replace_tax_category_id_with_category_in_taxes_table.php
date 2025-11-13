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
        // Récupérer les catégories existantes pour les migrer AVANT de modifier la table
        $taxCategories = DB::table('tax_categories')->get();
        $categoryMap = [];
        foreach ($taxCategories as $cat) {
            $categoryMap[$cat->id] = $cat->name;
        }
        
        Schema::table('taxes', function (Blueprint $table) {
            // Ajouter la nouvelle colonne category (temporairement nullable)
            $table->string('category')->nullable()->after('id');
        });
        
        // Migrer les données : copier le nom de la catégorie dans le nouveau champ
        foreach ($categoryMap as $categoryId => $categoryName) {
            DB::table('taxes')
                ->where('tax_category_id', $categoryId)
                ->update(['category' => $categoryName]);
        }
        
        Schema::table('taxes', function (Blueprint $table) {
            // Rendre category obligatoire
            $table->string('category')->nullable(false)->change();
            
            // Supprimer la clé étrangère si elle existe
            try {
                $table->dropForeign(['tax_category_id']);
            } catch (\Exception $e) {
                // La clé étrangère n'existe peut-être pas, on continue
            }
            
            // Supprimer l'ancienne colonne
            $table->dropColumn('tax_category_id');
        });
        
        // Supprimer l'index ancien et créer le nouveau
        try {
            Schema::table('taxes', function (Blueprint $table) {
                $table->dropIndex(['period', 'tax_category_id']);
            });
        } catch (\Exception $e) {
            // L'index n'existe peut-être pas
        }
        
        Schema::table('taxes', function (Blueprint $table) {
            // Ajouter un nouvel index
            $table->index(['period', 'category']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('taxes', function (Blueprint $table) {
            // Recréer la colonne tax_category_id
            $table->unsignedBigInteger('tax_category_id')->nullable()->after('id');
            
            // Essayer de récupérer les catégories correspondantes
            // Note : Cette migration ne peut pas parfaitement restaurer car on peut avoir plusieurs catégories avec le même nom
            $taxes = DB::table('taxes')->whereNotNull('category')->get();
            foreach ($taxes as $tax) {
                $category = DB::table('tax_categories')->where('name', $tax->category)->first();
                if ($category) {
                    DB::table('taxes')
                        ->where('id', $tax->id)
                        ->update(['tax_category_id' => $category->id]);
                }
            }
            
            // Rendre tax_category_id obligatoire
            $table->unsignedBigInteger('tax_category_id')->nullable(false)->change();
            
            // Recréer la clé étrangère
            $table->foreign('tax_category_id')->references('id')->on('tax_categories')->onDelete('cascade');
            
            // Recréer l'index
            $table->index(['period', 'tax_category_id']);
            
            // Supprimer la colonne category
            $table->dropColumn('category');
        });
    }
};
