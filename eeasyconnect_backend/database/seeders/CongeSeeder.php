<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Conge;
use App\Models\User;

class CongeSeeder extends Seeder
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

        $typesConge = ['annuel', 'maladie', 'maternite', 'paternite', 'exceptionnel', 'formation'];
        $statuts = ['en_attente', 'approuve', 'refuse', 'annule'];

        for ($i = 1; $i <= 25; $i++) {
            $user = $users->random();
            $typeConge = $typesConge[array_rand($typesConge)];
            $statut = $statuts[array_rand($statuts)];
            
            $dateDebut = now()->addDays(rand(1, 60));
            $dateFin = $dateDebut->copy()->addDays(rand(1, 15));
            
            Conge::create([
                'user_id' => $user->id,
                'type_conge' => $typeConge,
                'date_debut' => $dateDebut->toDateString(),
                'date_fin' => $dateFin->toDateString(),
                'nombre_jours' => $dateDebut->diffInDays($dateFin) + 1,
                'statut' => $statut,
                'motif' => $this->getMotifByType($typeConge),
                'commentaire_rh' => $statut === 'refuse' ? 'Congé refusé pour cause de surcharge de travail' : null,
                'urgent' => rand(0, 1) === 1
            ]);
        }

        $this->command->info('25 congés créés avec succès.');
    }

    private function getMotifByType($type)
    {
        $motifs = [
            'annuel' => 'Congé annuel pour repos',
            'maladie' => 'Arrêt maladie',
            'maternite' => 'Congé maternité',
            'paternite' => 'Congé paternité',
            'exceptionnel' => 'Congé exceptionnel pour événement familial',
            'formation' => 'Congé pour formation professionnelle'
        ];

        return $motifs[$type] ?? 'Demande de congé';
    }
}