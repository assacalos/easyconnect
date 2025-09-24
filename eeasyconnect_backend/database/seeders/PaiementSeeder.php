<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Paiement;
use App\Models\Facture;
use App\Models\User;

class PaiementSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $factures = Facture::where('statut', '!=', 'annulee')->get();
        $users = User::all();

        if ($factures->isEmpty() || $users->isEmpty()) {
            $this->command->warn('Factures ou utilisateurs manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        $statuts = ['en_attente', 'valide', 'rejete'];
        $typesPaiement = ['especes', 'virement', 'cheque', 'carte_bancaire', 'mobile_money'];

        foreach ($factures->take(20) as $facture) {
            $user = $users->random();
            $statut = $statuts[array_rand($statuts)];
            $typePaiement = $typesPaiement[array_rand($typesPaiement)];
            
            $datePaiement = $facture->date_facture;
            $datePaiement = \Carbon\Carbon::parse($datePaiement)->addDays(rand(1, 30));
            
            Paiement::create([
                'facture_id' => $facture->id,
                'montant' => $facture->montant_ttc,
                'date_paiement' => $datePaiement->toDateString(),
                'type_paiement' => $typePaiement,
                'statut' => $statut,
                'reference' => 'PAY-' . date('Y') . '-' . str_pad(rand(1, 9999), 4, '0', STR_PAD_LEFT),
                'commentaire' => $statut === 'rejete' ? 'Paiement rejeté par la banque' : null,
                'user_id' => $user->id
            ]);
        }

        $this->command->info('20 paiements créés avec succès.');
    }
}