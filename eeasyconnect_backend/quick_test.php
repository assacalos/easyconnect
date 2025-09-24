<?php

// Script de test rapide
echo "🧪 Test rapide des seeders\n";
echo "========================\n\n";

// Vérifier que les migrations sont OK
echo "1. Vérification des migrations...\n";
try {
    \Artisan::call('migrate:status');
    echo "✅ Migrations: OK\n\n";
} catch (Exception $e) {
    echo "❌ Migrations: " . $e->getMessage() . "\n\n";
}

// Test des seeders principaux
$seeders = [
    'UserSeeder' => 'Utilisateurs',
    'FournisseurSeeder' => 'Fournisseurs', 
    'ClientSeeder' => 'Clients',
    'FactureSeeder' => 'Factures',
    'PaiementSeeder' => 'Paiements'
];

foreach ($seeders as $seeder => $description) {
    echo "2. Test $description...\n";
    try {
        \Artisan::call('db:seed', ['--class' => $seeder]);
        echo "✅ $seeder: OK\n";
    } catch (Exception $e) {
        echo "❌ $seeder: " . $e->getMessage() . "\n";
    }
}

echo "\n🎉 Tests terminés !\n";

