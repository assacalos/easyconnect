<?php

require_once 'vendor/autoload.php';

use App\Models\User;
use App\Models\Attendance;

// Créer un utilisateur de test s'il n'existe pas
$user = User::where('email', 'test@example.com')->first();
if (!$user) {
    $user = User::create([
        'nom' => 'Test',
        'prenom' => 'User',
        'email' => 'test@example.com',
        'password' => bcrypt('password'),
        'role' => 2
    ]);
    echo "Utilisateur créé\n";
}

// Créer un token
$token = $user->createToken('test-token')->plainTextToken;
echo "Token: $token\n";

// Créer quelques pointages de test
$attendance1 = Attendance::create([
    'user_id' => $user->id,
    'check_in_time' => now()->subDays(1),
    'check_out_time' => now()->subDays(1)->addHours(8),
    'status' => 'present',
    'location' => [
        'latitude' => 48.8566,
        'longitude' => 2.3522,
        'address' => 'Paris, France'
    ],
    'notes' => 'Pointage de test 1'
]);

$attendance2 = Attendance::create([
    'user_id' => $user->id,
    'check_in_time' => now()->subDays(2),
    'check_out_time' => now()->subDays(2)->addHours(7),
    'status' => 'late',
    'location' => [
        'latitude' => 48.8566,
        'longitude' => 2.3522,
        'address' => 'Paris, France'
    ],
    'notes' => 'Pointage de test 2 - en retard'
]);

echo "Pointages créés\n";
echo "Total utilisateurs: " . User::count() . "\n";
echo "Total pointages: " . Attendance::count() . "\n";
