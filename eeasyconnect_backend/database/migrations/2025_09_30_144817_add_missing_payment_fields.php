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
        // Vérifier si les colonnes existent déjà
        $columns = DB::select("SHOW COLUMNS FROM paiements");
        $existingColumns = array_column($columns, 'Field');
        
        // Ajouter payment_number s'il n'existe pas
        if (!in_array('payment_number', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->string('payment_number')->nullable()->after('id');
            });
        }
        
        // Ajouter type s'il n'existe pas
        if (!in_array('type', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->enum('type', ['one_time', 'monthly'])->default('one_time')->after('payment_number');
            });
        }
        
        // Ajouter due_date s'il n'existe pas
        if (!in_array('due_date', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->date('due_date')->nullable()->after('date_paiement');
            });
        }
        
        // Ajouter currency s'il n'existe pas
        if (!in_array('currency', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->string('currency', 3)->after('montant');
            });
        }
        
        // Ajouter description s'il n'existe pas
        if (!in_array('description', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->text('description')->nullable()->after('commentaire');
            });
        }
        
        // Ajouter submitted_at s'il n'existe pas
        if (!in_array('submitted_at', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->timestamp('submitted_at')->nullable()->after('updated_at');
            });
        }
        
        // Ajouter approved_at s'il n'existe pas
        if (!in_array('approved_at', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->timestamp('approved_at')->nullable()->after('submitted_at');
            });
        }
        
        // Ajouter paid_at s'il n'existe pas
        if (!in_array('paid_at', $existingColumns)) {
            Schema::table('paiements', function (Blueprint $table) {
                $table->timestamp('paid_at')->nullable()->after('approved_at');
            });
        }
        
        // Générer des numéros de paiement pour les enregistrements existants
        $paiements = DB::table('paiements')->whereNull('payment_number')->get();
        foreach ($paiements as $paiement) {
            $paymentNumber = 'PAY' . date('Ymd') . str_pad($paiement->id, 4, '0', STR_PAD_LEFT);
            DB::table('paiements')->where('id', $paiement->id)->update(['payment_number' => $paymentNumber]);
        }
        
        // Ajouter la contrainte unique sur payment_number
        try {
            Schema::table('paiements', function (Blueprint $table) {
                $table->unique('payment_number');
            });
        } catch (Exception $e) {
            // La contrainte existe peut-être déjà
        }
        
        // Modifier le statut si nécessaire
        $statusColumn = DB::select("SHOW COLUMNS FROM paiements LIKE 'status'");
        if (!empty($statusColumn)) {
            $currentStatus = $statusColumn[0];
            if ($currentStatus->Type !== "enum('draft','submitted','approved','rejected','paid','overdue')") {
                // Supprimer et recréer la colonne status
                Schema::table('paiements', function (Blueprint $table) {
                    $table->dropColumn('status');
                });
                
                Schema::table('paiements', function (Blueprint $table) {
                    $table->enum('status', ['draft', 'submitted', 'approved', 'rejected', 'paid', 'overdue'])->default('draft')->after('type_paiement');
                });
            }
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('paiements', function (Blueprint $table) {
            $table->dropColumn([
                'payment_number',
                'type',
                'due_date',
                'currency',
                'description',
                'submitted_at',
                'approved_at',
                'paid_at'
            ]);
        });
    }
};