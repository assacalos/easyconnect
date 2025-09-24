<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Pointage;
use App\Models\User;

class PointageSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $users = User::all(); // Tous les utilisateurs

        if ($users->isEmpty()) {
            $this->command->warn('Utilisateurs manquants.');
            return;
        }

        $statuts = ['present', 'absent', 'retard', 'congé', 'maladie'];
        $types = ['arrivee', 'depart', 'pause_debut', 'pause_fin'];

        // Créer des pointages pour les 30 derniers jours
        for ($i = 0; $i < 30; $i++) {
            $date = now()->subDays($i);
            
            foreach ($users as $user) {
                // Pointage d'arrivée (80% de chance)
                if (rand(1, 100) <= 80) {
                    $heureArrivee = $date->copy()->setHour(rand(7, 9))->setMinute(rand(0, 59));
                    
                    Pointage::create([
                        'user_id' => $user->id,
                        'date' => $date->toDateString(),
                        'heure' => $heureArrivee->toTimeString(),
                        'type' => 'arrivee',
                        'statut' => $heureArrivee->hour > 8 ? 'retard' : 'present',
                        'commentaire' => $heureArrivee->hour > 8 ? 'Arrivée en retard' : null
                    ]);
                }

                // Pointage de départ (70% de chance)
                if (rand(1, 100) <= 70) {
                    $heureDepart = $date->copy()->setHour(rand(17, 19))->setMinute(rand(0, 59));
                    
                    Pointage::create([
                        'user_id' => $user->id,
                        'date' => $date->toDateString(),
                        'heure' => $heureDepart->toTimeString(),
                        'type' => 'depart',
                        'statut' => 'present',
                        'commentaire' => null
                    ]);
                }
            }
        }

        $this->command->info('Pointages créés avec succès pour les 30 derniers jours.');
    }
}