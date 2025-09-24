<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Notification;
use App\Models\User;

class NotificationSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all();

        if ($users->isEmpty()) {
            $this->command->warn('Utilisateurs manquants. Veuillez d\'abord exécuter UserSeeder.');
            return;
        }

        $types = ['info', 'warning', 'success', 'error', 'urgent'];
        $categories = ['systeme', 'rh', 'commercial', 'comptabilite', 'technique'];
        $statuts = ['non_lue', 'lue', 'archivee'];

        $notifications = [
            [
                'titre' => 'Nouveau client ajouté',
                'message' => 'Un nouveau client a été ajouté au système',
                'type' => 'info',
                'categorie' => 'commercial'
            ],
            [
                'titre' => 'Facture en retard',
                'message' => 'Une facture est en retard de paiement',
                'type' => 'warning',
                'categorie' => 'comptabilite'
            ],
            [
                'titre' => 'Demande de congé approuvée',
                'message' => 'Votre demande de congé a été approuvée',
                'type' => 'success',
                'categorie' => 'rh'
            ],
            [
                'titre' => 'Erreur système',
                'message' => 'Une erreur technique a été détectée',
                'type' => 'error',
                'categorie' => 'systeme'
            ],
            [
                'titre' => 'Maintenance urgente',
                'message' => 'Maintenance système programmée ce soir',
                'type' => 'urgent',
                'categorie' => 'technique'
            ],
            [
                'titre' => 'Rapport mensuel disponible',
                'message' => 'Le rapport mensuel est maintenant disponible',
                'type' => 'info',
                'categorie' => 'comptabilite'
            ],
            [
                'titre' => 'Évaluation à compléter',
                'message' => 'Votre évaluation annuelle est en attente',
                'type' => 'warning',
                'categorie' => 'rh'
            ],
            [
                'titre' => 'Paiement reçu',
                'message' => 'Un paiement a été enregistré',
                'type' => 'success',
                'categorie' => 'comptabilite'
            ]
        ];

        foreach ($users as $user) {
            // Créer 3-8 notifications par utilisateur
            $nombreNotifications = rand(3, 8);
            
            for ($i = 0; $i < $nombreNotifications; $i++) {
                $notification = $notifications[array_rand($notifications)];
                $statut = $statuts[array_rand($statuts)];
                $dateCreation = now()->subDays(rand(0, 30));
                
                Notification::create([
                    'user_id' => $user->id,
                    'titre' => $notification['titre'],
                    'message' => $notification['message'],
                    'type' => $notification['type'],
                    'statut' => $statut,
                    'priorite' => $notification['type'] === 'urgent' ? 'urgente' : 'normale',
                    'date_lecture' => $statut === 'lue' ? $dateCreation->copy()->addHours(rand(1, 24))->toDateTimeString() : null,
                    'envoyee' => rand(0, 1) === 1,
                    'created_at' => $dateCreation,
                    'updated_at' => $dateCreation
                ]);
            }
        }

        $this->command->info('Notifications créées avec succès pour tous les utilisateurs.');
    }
}