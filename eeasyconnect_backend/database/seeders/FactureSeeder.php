<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Facture;
use App\Models\Client;
use App\Models\User;

class FactureSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $clients = Client::all();
        $users = User::all();

        if ($clients->isEmpty() || $users->isEmpty()) {
            $this->command->warn('Clients ou utilisateurs manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        $statuts = ['brouillon', 'envoyee', 'payee', 'en_retard', 'annulee'];
        $typesPaiement = ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money'];

        for ($i = 1; $i <= 30; $i++) {
            $client = $clients->random();
            $user = $users->random();
            $statut = $statuts[array_rand($statuts)];
            
            $dateFacture = now()->subDays(rand(1, 90));
            $dateEcheance = $dateFacture->copy()->addDays(rand(15, 45));
            
            Facture::create([
                'client_id' => $client->id,
                'numero_facture' => 'FAC-' . date('Y') . '-' . str_pad($i, 4, '0', STR_PAD_LEFT),
                'date_facture' => $dateFacture->toDateString(),
                'date_echeance' => $dateEcheance->toDateString(),
                'montant_ht' => rand(50000, 500000),
                'tva' => 18.0,
                'montant_ttc' => 0, // Sera calculé
                'statut' => $statut,
                'type_paiement' => $typesPaiement[array_rand($typesPaiement)],
                'notes' => $statut === 'en_retard' ? 'Facture en retard de paiement' : null,
                'user_id' => $user->id
            ]);
        }

        // Recalculer les montants TTC
        Facture::all()->each(function($facture) {
            $facture->montant_ttc = $facture->montant_ht * (1 + $facture->tva / 100);
            $facture->save();
        });

        $this->command->info('30 factures créées avec succès.');
    }
}