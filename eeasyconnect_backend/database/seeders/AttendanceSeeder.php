<?php

namespace Database\Seeders;

use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use App\Models\Attendance;
use App\Models\AttendanceSettings;
use App\Models\User;
use Carbon\Carbon;

class AttendanceSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        // Créer les paramètres de pointage par défaut
        AttendanceSettings::create([
            'allowed_radius' => 100,
            'work_start_time' => '08:00:00',
            'work_end_time' => '17:00:00',
            'late_threshold_minutes' => 15,
            'require_photo' => true,
            'require_location' => true,
            'allowed_locations' => [
                [
                    'name' => 'Bureau Principal',
                    'latitude' => 5.359952,
                    'longitude' => -4.008256,
                    'address' => 'Abidjan, Côte d\'Ivoire'
                ],
                [
                    'name' => 'Succursale Cocody',
                    'latitude' => 5.359952,
                    'longitude' => -4.008256,
                    'address' => 'Cocody, Abidjan'
                ]
            ],
            'is_active' => true
        ]);

        $users = User::all();

        if ($users->isEmpty()) {
            $this->command->warn('Utilisateurs manquants. Veuillez d\'abord exécuter UserSeeder.');
            return;
        }

        $statuses = ['present', 'late', 'early_leave'];
        $workStartTime = '08:00';
        $workEndTime = '17:00';

        foreach ($users as $user) {
            // Créer des pointages pour les 30 derniers jours
            for ($i = 0; $i < 30; $i++) {
                $date = Carbon::now()->subDays($i);
                
                // Skip weekends
                if ($date->isWeekend()) {
                    continue;
                }

                $status = $statuses[array_rand($statuses)];
                
                // Heure d'arrivée
                $checkInTime = $date->copy()->setTimeFromTimeString($workStartTime);
                
                // Ajouter du retard aléatoire
                if ($status === 'late') {
                    $checkInTime->addMinutes(rand(15, 60));
                } elseif ($status === 'present') {
                    $checkInTime->addMinutes(rand(-30, 15));
                }

                // Heure de départ
                $checkOutTime = $date->copy()->setTimeFromTimeString($workEndTime);
                
                // Départ anticipé si early_leave
                if ($status === 'early_leave') {
                    $checkOutTime->subMinutes(rand(30, 120));
                } else {
                    $checkOutTime->addMinutes(rand(-30, 60));
                }

                // Géolocalisation aléatoire autour d'Abidjan
                $baseLat = 5.359952;
                $baseLng = -4.008256;
                $latOffset = (rand(-100, 100) / 1000); // ±100m
                $lngOffset = (rand(-100, 100) / 1000); // ±100m

                $location = [
                    'latitude' => $baseLat + $latOffset,
                    'longitude' => $baseLng + $lngOffset,
                    'address' => 'Abidjan, Côte d\'Ivoire',
                    'accuracy' => rand(5, 20),
                    'timestamp' => $checkInTime->toISOString()
                ];

                Attendance::create([
                    'user_id' => $user->id,
                    'check_in_time' => $checkInTime,
                    'check_out_time' => $checkOutTime,
                    'status' => $status,
                    'location' => $location,
                    'photo_path' => rand(0, 1) ? 'photos/attendance_' . $user->id . '_' . $date->format('Y_m_d') . '.jpg' : null,
                    'notes' => $this->getRandomNotes($status)
                ]);
            }
        }

        $this->command->info('Pointages créés avec succès pour tous les utilisateurs.');
    }

    /**
     * Générer des notes aléatoires selon le statut
     */
    private function getRandomNotes($status)
    {
        $notes = [
            'present' => [
                'Arrivée à l\'heure',
                'Journée normale',
                'Travail productif',
                null
            ],
            'late' => [
                'Retard dû aux embouteillages',
                'Problème de transport',
                'Réunion matinale',
                'Retard justifié'
            ],
            'early_leave' => [
                'Rendez-vous médical',
                'Urgence familiale',
                'Travail terminé en avance',
                'Formation externe'
            ]
        ];

        $statusNotes = $notes[$status] ?? [null];
        return $statusNotes[array_rand($statusNotes)];
    }
}