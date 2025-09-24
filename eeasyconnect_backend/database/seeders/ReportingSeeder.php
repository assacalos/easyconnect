<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Reporting;
use App\Models\User;
use Carbon\Carbon;

class ReportingSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::whereIn('role', [2, 3, 5])->get(); // Commercial, Comptable, Technicien

        if ($users->isEmpty()) {
            $this->command->warn('Utilisateurs avec rôles appropriés manquants. Veuillez d\'abord exécuter UserSeeder.');
            return;
        }

        $statuses = ['draft', 'submitted', 'approved'];

        foreach ($users as $user) {
            // Créer 3-5 reportings par utilisateur pour les 3 derniers mois
            for ($i = 0; $i < rand(3, 5); $i++) {
                $reportDate = Carbon::now()->subMonths(rand(0, 2))->startOfMonth()->addDays(rand(1, 15));
                $status = $statuses[array_rand($statuses)];
                
                $reporting = new Reporting();
                $reporting->user_id = $user->id;
                
                // Générer les métriques selon le rôle
                $metrics = $this->generateMetricsForUser($user, $reportDate);
                
                $reportingData = [
                    'user_id' => $user->id,
                    'report_date' => $reportDate->toDateString(),
                    'metrics' => $metrics,
                    'status' => $status,
                    'submitted_at' => $status === 'submitted' || $status === 'approved' ? $reportDate->copy()->addDays(rand(1, 5)) : null,
                    'approved_at' => $status === 'approved' ? $reportDate->copy()->addDays(rand(5, 10)) : null,
                    'approved_by' => $status === 'approved' ? User::whereIn('role', [1, 4, 6])->inRandomOrder()->first()->id : null,
                    'comments' => $status === 'approved' ? 'Reporting approuvé avec succès' : null
                ];

                Reporting::create($reportingData);
            }
        }

        $this->command->info('Reportings créés avec succès pour tous les utilisateurs.');
    }

    /**
     * Générer les métriques selon le rôle de l'utilisateur
     */
    private function generateMetricsForUser($user, $reportDate)
    {
        $startDate = $reportDate->copy()->startOfMonth();
        $endDate = $reportDate->copy()->endOfMonth();

        $reporting = new Reporting();
        $reporting->user_id = $user->id;

        switch ($user->role) {
            case 2: // Commercial
                return $this->generateCommercialMetrics($startDate, $endDate);
            case 3: // Comptable
                return $this->generateComptableMetrics($startDate, $endDate);
            case 5: // Technicien
                return $this->generateTechnicienMetrics($startDate, $endDate);
            default:
                return [
                    'message' => 'Métriques non disponibles pour ce rôle',
                    'role' => $user->role
                ];
        }
    }

    /**
     * Générer les métriques commerciales
     */
    private function generateCommercialMetrics($startDate, $endDate)
    {
        return [
            'clients_prospectes' => rand(5, 15),
            'rdv_obtenus' => rand(8, 20),
            'rdv_list' => $this->generateRdvList(),
            'devis_crees' => rand(10, 25),
            'devis_acceptes' => rand(5, 15),
            'chiffre_affaires' => rand(50000, 200000),
            'nouveaux_clients' => rand(3, 8),
            'appels_effectues' => rand(30, 80),
            'emails_envoyes' => rand(50, 120),
            'visites_realisees' => rand(10, 25)
        ];
    }

    /**
     * Générer les métriques comptables
     */
    private function generateComptableMetrics($startDate, $endDate)
    {
        return [
            'factures_emises' => rand(20, 50),
            'factures_payees' => rand(15, 40),
            'montant_facture' => rand(100000, 500000),
            'montant_encaissement' => rand(80000, 400000),
            'bordereaux_traites' => rand(10, 30),
            'bons_commande_traites' => rand(15, 35),
            'chiffre_affaires' => rand(200000, 800000),
            'clients_factures' => rand(15, 40),
            'relances_effectuees' => rand(5, 15),
            'encaissements' => rand(150000, 600000)
        ];
    }

    /**
     * Générer les métriques techniques
     */
    private function generateTechnicienMetrics($startDate, $endDate)
    {
        return [
            'interventions_planifiees' => rand(20, 40),
            'interventions_realisees' => rand(15, 35),
            'interventions_annulees' => rand(2, 8),
            'interventions_list' => $this->generateInterventionsList(),
            'clients_visites' => rand(10, 25),
            'problemes_resolus' => rand(20, 45),
            'problemes_en_cours' => rand(3, 10),
            'temps_travail' => rand(120, 200), // heures
            'deplacements' => rand(25, 50),
            'notes_techniques' => 'Rapport technique détaillé du mois'
        ];
    }

    /**
     * Générer une liste de RDV
     */
    private function generateRdvList()
    {
        $rdvList = [];
        $clients = ['Client A', 'Client B', 'Client C', 'Client D', 'Client E'];
        $types = ['presentiel', 'telephone', 'video'];
        $statuses = ['planifie', 'realise', 'annule'];

        for ($i = 0; $i < rand(3, 8); $i++) {
            $rdvList[] = [
                'client_name' => $clients[array_rand($clients)],
                'date_rdv' => Carbon::now()->addDays(rand(-30, 30))->format('Y-m-d'),
                'heure_rdv' => rand(8, 18) . ':' . str_pad(rand(0, 59), 2, '0', STR_PAD_LEFT),
                'type_rdv' => $types[array_rand($types)],
                'status' => $statuses[array_rand($statuses)],
                'notes' => 'RDV ' . ($i + 1) . ' - Notes importantes'
            ];
        }

        return $rdvList;
    }

    /**
     * Générer une liste d'interventions
     */
    private function generateInterventionsList()
    {
        $interventions = [];
        $clients = ['Client A', 'Client B', 'Client C', 'Client D', 'Client E'];
        $types = ['maintenance', 'reparation', 'installation', 'formation'];
        $statuses = ['planifiee', 'realisee', 'annulee'];

        for ($i = 0; $i < rand(5, 12); $i++) {
            $interventions[] = [
                'client_name' => $clients[array_rand($clients)],
                'date_intervention' => Carbon::now()->addDays(rand(-30, 30))->format('Y-m-d'),
                'heure_debut' => rand(8, 16) . ':' . str_pad(rand(0, 59), 2, '0', STR_PAD_LEFT),
                'heure_fin' => (rand(8, 16) + 2) . ':' . str_pad(rand(0, 59), 2, '0', STR_PAD_LEFT),
                'type_intervention' => $types[array_rand($types)],
                'status' => $statuses[array_rand($statuses)],
                'description' => 'Intervention ' . ($i + 1) . ' - Description détaillée',
                'resultat' => 'Résultat de l\'intervention ' . ($i + 1)
            ];
        }

        return $interventions;
    }
}