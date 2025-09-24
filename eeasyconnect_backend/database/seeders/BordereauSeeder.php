<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Bordereau;
use App\Models\BordereauItem;
use App\Models\Client;
use App\Models\User;

class BordereauSeeder extends Seeder
{
    public function run(): void
    {
        $clients = Client::all();
        $users = User::all();

        if ($clients->isEmpty() || $users->isEmpty()) {
            $this->command->warn('Clients ou utilisateurs manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        for ($i = 1; $i <= 10; $i++) {
            $client = $clients->random();
            $user = $users->random();
            
            $bordereau = Bordereau::create([
                'reference' => 'BDR-' . date('Y') . '-' . str_pad($i, 4, '0', STR_PAD_LEFT),
                'client_id' => $client->id,
                'user_id' => $user->id,
                'date_creation' => now()->subDays(rand(1, 30))->toDateString(),
                'date_validation' => rand(0, 1) ? now()->subDays(rand(1, 15))->toDateString() : null,
                'notes' => 'Bordereau de prestations pour ' . $client->nom,
                'remise_globale' => rand(0, 15),
                'tva' => 20,
                'conditions' => 'Paiement à 30 jours',
                'status' => rand(0, 3),
                'commentaire' => null,
            ]);

            // Créer des items pour ce bordereau
            for ($j = 1; $j <= rand(2, 5); $j++) {
                BordereauItem::create([
                    'bordereau_id' => $bordereau->id,
                    'designation' => 'Prestation ' . $j,
                    'unite' => 'unité',
                    'quantite' => rand(1, 10),
                    'prix_unitaire' => rand(5000, 50000),
                    'description' => 'Description de la prestation ' . $j
                ]);
            }
        }

        $this->command->info('10 bordereaux créés avec succès.');
    }
}

