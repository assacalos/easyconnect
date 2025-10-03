<?php

require_once 'vendor/autoload.php';

use App\Models\User;
use App\Models\Attendance;
use Illuminate\Support\Facades\Hash;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "🚀 Création des données de test pour le système de pointage...\n";

try {
    // Créer un utilisateur de test
    $user = User::firstOrCreate(
        ['email' => 'test@example.com'],
        [
            'nom' => 'Test User',
            'email' => 'test@example.com',
            'password' => Hash::make('password'),
            'role' => 2, // Commercial
        ]
    );

    echo "✅ Utilisateur de test créé: {$user->nom} (ID: {$user->id})\n";

    // Créer des pointages de test
    $attendances = [
        [
            'user_id' => $user->id,
            'type' => 'check_in',
            'timestamp' => now()->subDays(2)->setTime(8, 0),
            'latitude' => 48.8566,
            'longitude' => 2.3522,
            'address' => 'Paris, France',
            'accuracy' => 10.0,
            'photo_path' => 'attendances/' . $user->id . '/test_photo_1.jpg',
            'notes' => 'Pointage de test - arrivée',
            'status' => 'approved',
            'approved_by' => $user->id,
            'approved_at' => now()->subDays(2)->setTime(8, 5),
        ],
        [
            'user_id' => $user->id,
            'type' => 'check_out',
            'timestamp' => now()->subDays(2)->setTime(17, 0),
            'latitude' => 48.8566,
            'longitude' => 2.3522,
            'address' => 'Paris, France',
            'accuracy' => 10.0,
            'photo_path' => 'attendances/' . $user->id . '/test_photo_2.jpg',
            'notes' => 'Pointage de test - départ',
            'status' => 'approved',
            'approved_by' => $user->id,
            'approved_at' => now()->subDays(2)->setTime(17, 5),
        ],
        [
            'user_id' => $user->id,
            'type' => 'check_in',
            'timestamp' => now()->subDays(1)->setTime(8, 30),
            'latitude' => 48.8566,
            'longitude' => 2.3522,
            'address' => 'Paris, France',
            'accuracy' => 10.0,
            'photo_path' => 'attendances/' . $user->id . '/test_photo_3.jpg',
            'notes' => 'Pointage de test - arrivée avec retard',
            'status' => 'pending',
        ],
        [
            'user_id' => $user->id,
            'type' => 'check_in',
            'timestamp' => now()->setTime(8, 0),
            'latitude' => 48.8566,
            'longitude' => 2.3522,
            'address' => 'Paris, France',
            'accuracy' => 10.0,
            'photo_path' => 'attendances/' . $user->id . '/test_photo_4.jpg',
            'notes' => 'Pointage de test - arrivée aujourd\'hui',
            'status' => 'pending',
        ],
    ];

    foreach ($attendances as $attendanceData) {
        $attendance = Attendance::create($attendanceData);
        echo "✅ Pointage créé: {$attendance->type} le {$attendance->timestamp->format('d/m/Y H:i')} (ID: {$attendance->id})\n";
    }

    echo "\n🎉 Données de test créées avec succès !\n";
    echo "📊 Résumé:\n";
    echo "- Utilisateur: {$user->nom} (ID: {$user->id})\n";
    echo "- Pointages créés: " . count($attendances) . "\n";
    echo "- Pointages approuvés: " . Attendance::where('status', 'approved')->count() . "\n";
    echo "- Pointages en attente: " . Attendance::where('status', 'pending')->count() . "\n";

} catch (Exception $e) {
    echo "❌ Erreur: " . $e->getMessage() . "\n";
    exit(1);
}
