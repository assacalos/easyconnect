<?php

// Script de test rapide pour les seeders
echo "🧪 Test des seeders EasyConnect\n";
echo "===============================\n\n";

// Test 1: UserSeeder
echo "1. Test UserSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'UserSeeder']);
    echo "✅ UserSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ UserSeeder: " . $e->getMessage() . "\n";
}

// Test 2: FournisseurSeeder
echo "\n2. Test FournisseurSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'FournisseurSeeder']);
    echo "✅ FournisseurSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ FournisseurSeeder: " . $e->getMessage() . "\n";
}

// Test 3: ClientSeeder
echo "\n3. Test ClientSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'ClientSeeder']);
    echo "✅ ClientSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ ClientSeeder: " . $e->getMessage() . "\n";
}

// Test 4: FactureSeeder
echo "\n4. Test FactureSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'FactureSeeder']);
    echo "✅ FactureSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ FactureSeeder: " . $e->getMessage() . "\n";
}

// Test 5: PaiementSeeder
echo "\n5. Test PaiementSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'PaiementSeeder']);
    echo "✅ PaiementSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ PaiementSeeder: " . $e->getMessage() . "\n";
}

// Test 6: PointageSeeder
echo "\n6. Test PointageSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'PointageSeeder']);
    echo "✅ PointageSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ PointageSeeder: " . $e->getMessage() . "\n";
}

// Test 7: CongeSeeder
echo "\n7. Test CongeSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'CongeSeeder']);
    echo "✅ CongeSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ CongeSeeder: " . $e->getMessage() . "\n";
}

// Test 8: EvaluationSeeder
echo "\n8. Test EvaluationSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'EvaluationSeeder']);
    echo "✅ EvaluationSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ EvaluationSeeder: " . $e->getMessage() . "\n";
}

// Test 9: NotificationSeeder
echo "\n9. Test NotificationSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'NotificationSeeder']);
    echo "✅ NotificationSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ NotificationSeeder: " . $e->getMessage() . "\n";
}

// Test 10: DevisSeeder
echo "\n10. Test DevisSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'DevisSeeder']);
    echo "✅ DevisSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ DevisSeeder: " . $e->getMessage() . "\n";
}

// Test 11: BordereauSeeder
echo "\n11. Test BordereauSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'BordereauSeeder']);
    echo "✅ BordereauSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ BordereauSeeder: " . $e->getMessage() . "\n";
}

// Test 12: BonDeCommandeSeeder
echo "\n12. Test BonDeCommandeSeeder...\n";
try {
    \Artisan::call('db:seed', ['--class' => 'BonDeCommandeSeeder']);
    echo "✅ BonDeCommandeSeeder: OK\n";
} catch (Exception $e) {
    echo "❌ BonDeCommandeSeeder: " . $e->getMessage() . "\n";
}

echo "\n🎉 Tests terminés !\n";
echo "📊 Vérifiez les données dans votre base de données.\n";

