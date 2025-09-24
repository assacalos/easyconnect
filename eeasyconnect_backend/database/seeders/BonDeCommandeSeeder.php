<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\BonDeCommande;
use App\Models\Client;
use App\Models\Fournisseur;
use App\Models\User;

class BonDeCommandeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Récupérer les clients et fournisseurs existants
        $clients = Client::all();
        $fournisseurs = Fournisseur::all();
        $users = User::all();

        if ($clients->isEmpty() || $fournisseurs->isEmpty() || $users->isEmpty()) {
            $this->command->warn('Clients, fournisseurs ou utilisateurs manquants. Veuillez d\'abord exécuter leurs seeders.');
            return;
        }

        $statuts = ['en_attente', 'valide', 'en_cours', 'livre', 'annule'];
        $descriptions = [
            'Commande de matériel informatique',
            'Fourniture de bureau',
            'Équipement de sécurité',
            'Matériel de construction',
            'Services de maintenance',
            'Produits alimentaires',
            'Équipement médical',
            'Matériel de transport'
        ];

        $conditionsPaiement = [
            'Paiement à 30 jours',
            'Paiement comptant',
            'Paiement à 60 jours',
            'Paiement à réception',
            'Paiement échelonné'
        ];

        for ($i = 1; $i <= 20; $i++) {
            $client = $clients->random();
            $fournisseur = $fournisseurs->random();
            $user = $users->random();
            $statut = $statuts[array_rand($statuts)];
            
            $dateCommande = now()->subDays(rand(1, 90));
            $dateLivraisonPrevue = $dateCommande->copy()->addDays(rand(7, 30));
            
            $bon = BonDeCommande::create([
                'client_id' => $client->id,
                'fournisseur_id' => $fournisseur->id,
                'numero_commande' => 'BC-' . date('Y') . '-' . str_pad($i, 4, '0', STR_PAD_LEFT),
                'date_commande' => $dateCommande->toDateString(),
                'date_livraison_prevue' => $dateLivraisonPrevue->toDateString(),
                'date_livraison' => $statut === 'livre' ? $dateLivraisonPrevue->copy()->addDays(rand(-5, 5))->toDateString() : null,
                'montant_total' => rand(500, 50000),
                'description' => $descriptions[array_rand($descriptions)],
                'status' => $statut,
                'commentaire' => $statut === 'annule' ? 'Commande annulée par le client' : null,
                'conditions_paiement' => $conditionsPaiement[array_rand($conditionsPaiement)],
                'delai_livraison' => rand(7, 30),
                'date_validation' => in_array($statut, ['valide', 'en_cours', 'livre']) ? $dateCommande->copy()->addDays(rand(1, 5))->toDateString() : null,
                'date_debut_traitement' => in_array($statut, ['en_cours', 'livre']) ? $dateCommande->copy()->addDays(rand(5, 10))->toDateString() : null,
                'date_annulation' => $statut === 'annule' ? $dateCommande->copy()->addDays(rand(1, 15))->toDateString() : null,
                'user_id' => $user->id
            ]);
        }

        $this->command->info('20 bons de commande créés avec succès.');
    }
}
