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
        Schema::table('reportings', function (Blueprint $table) {
            // Notes pour les métriques commerciales
            $table->text('notes_clients_prospectes')->nullable();
            $table->text('notes_rdv_obtenus')->nullable();
            $table->text('notes_devis_crees')->nullable();
            $table->text('notes_devis_acceptes')->nullable();
            $table->text('notes_chiffre_affaires')->nullable();
            $table->text('notes_nouveaux_clients')->nullable();
            $table->text('notes_appels_effectues')->nullable();
            $table->text('notes_emails_envoyes')->nullable();
            $table->text('notes_visites_realisees')->nullable();
            
            // Notes pour les métriques comptables
            $table->text('notes_factures_emises')->nullable();
            $table->text('notes_factures_payees')->nullable();
            $table->text('notes_montant_facture')->nullable();
            $table->text('notes_montant_encaissement')->nullable();
            $table->text('notes_bordereaux_traites')->nullable();
            $table->text('notes_bons_commande_traites')->nullable();
            $table->text('notes_clients_factures')->nullable();
            $table->text('notes_relances_effectuees')->nullable();
            $table->text('notes_encaissements')->nullable();
            
            // Notes pour les métriques techniques
            $table->text('notes_interventions_planifiees')->nullable();
            $table->text('notes_interventions_realisees')->nullable();
            $table->text('notes_interventions_annulees')->nullable();
            $table->text('notes_clients_visites')->nullable();
            $table->text('notes_problemes_resolus')->nullable();
            $table->text('notes_problemes_en_cours')->nullable();
            $table->text('notes_temps_travail')->nullable();
            $table->text('notes_deplacements')->nullable();
            $table->text('notes_techniques')->nullable();
            
            // Notes générales
            $table->text('notes_generales')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('reportings', function (Blueprint $table) {
            $table->dropColumn([
                'notes_clients_prospectes',
                'notes_rdv_obtenus',
                'notes_devis_crees',
                'notes_devis_acceptes',
                'notes_chiffre_affaires',
                'notes_nouveaux_clients',
                'notes_appels_effectues',
                'notes_emails_envoyes',
                'notes_visites_realisees',
                'notes_factures_emises',
                'notes_factures_payees',
                'notes_montant_facture',
                'notes_montant_encaissement',
                'notes_bordereaux_traites',
                'notes_bons_commande_traites',
                'notes_clients_factures',
                'notes_relances_effectuees',
                'notes_encaissements',
                'notes_interventions_planifiees',
                'notes_interventions_realisees',
                'notes_interventions_annulees',
                'notes_clients_visites',
                'notes_problemes_resolus',
                'notes_problemes_en_cours',
                'notes_temps_travail',
                'notes_deplacements',
                'notes_techniques',
                'notes_generales'
            ]);
        });
    }
};
