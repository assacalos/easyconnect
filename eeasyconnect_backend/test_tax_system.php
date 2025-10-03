<?php

require_once 'vendor/autoload.php';

use App\Models\TaxCategory;
use App\Models\Tax;
use App\Models\TaxPayment;
use App\Models\TaxDeclaration;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du système d'impôts et taxes ===\n\n";

// 1. Créer des catégories d'impôts de test
echo "1. Création des catégories d'impôts:\n";

$categories = [
    [
        'name' => 'TVA Test',
        'code' => 'TVA_TEST',
        'description' => 'TVA pour test',
        'default_rate' => 18.00,
        'type' => 'percentage',
        'frequency' => 'monthly',
        'applicable_to' => ['factures']
    ],
    [
        'name' => 'Patente Test',
        'code' => 'PAT_TEST',
        'description' => 'Patente pour test',
        'default_rate' => 50000.00,
        'type' => 'fixed',
        'frequency' => 'yearly',
        'applicable_to' => ['entreprise']
    ]
];

foreach ($categories as $categoryData) {
    $category = TaxCategory::firstOrCreate(
        ['code' => $categoryData['code']], 
        $categoryData
    );
    echo "   - Catégorie créée: {$category->name} ({$category->code})\n";
}

echo "\n";

// 2. Vérifier les utilisateurs comptables
echo "2. Vérification des comptables:\n";
$comptables = User::where('role', 3)->get();
echo "   - Nombre de comptables: " . $comptables->count() . "\n";

if ($comptables->isEmpty()) {
    echo "   ⚠️ Aucun comptable trouvé. Création d'un comptable de test...\n";
    $comptable = User::create([
        'nom' => 'Test',
        'prenom' => 'Comptable',
        'email' => 'comptable.test@example.com',
        'password' => bcrypt('password'),
        'role' => 3,
        'telephone' => '0123456789',
        'date_naissance' => '1980-01-01',
        'adresse' => 'Adresse test',
        'ville' => 'Abidjan',
        'pays' => 'Côte d\'Ivoire'
    ]);
    echo "   - Comptable créé: {$comptable->prenom} {$comptable->nom}\n";
    $comptables = collect([$comptable]);
}

echo "\n";

// 3. Créer des impôts de test
echo "3. Création d'impôts de test:\n";
$taxCategories = TaxCategory::where('code', 'LIKE', '%TEST%')->get();
$comptable = $comptables->first();

foreach ($taxCategories as $category) {
    $period = now()->format('Y-m');
    $periodStart = now()->startOfMonth();
    $periodEnd = now()->endOfMonth();
    $dueDate = now()->addDays(15);

    $tax = Tax::create([
        'tax_category_id' => $category->id,
        'comptable_id' => $comptable->id,
        'reference' => Tax::generateReference($category->code, $period),
        'period' => $period,
        'period_start' => $periodStart->toDateString(),
        'period_end' => $periodEnd->toDateString(),
        'due_date' => $dueDate->toDateString(),
        'base_amount' => 100000.00,
        'tax_rate' => $category->default_rate,
        'tax_amount' => 0,
        'total_amount' => 0,
        'status' => 'draft',
        'description' => "Test {$category->name} pour {$period}",
        'notes' => 'Impôt de test'
    ]);

    // Calculer la taxe
    $taxAmount = $tax->calculateTax();
    
    echo "   - Impôt créé: {$tax->reference}\n";
    echo "     * Base: " . number_format($tax->base_amount, 2) . " €\n";
    echo "     * Taux: {$tax->tax_rate}" . ($category->type === 'percentage' ? '%' : ' €') . "\n";
    echo "     * Taxe: " . number_format($taxAmount, 2) . " €\n";
    echo "     * Total: " . number_format($tax->total_amount, 2) . " €\n";
}

echo "\n";

// 4. Tester les transitions d'état
echo "4. Test des transitions d'état:\n";
$tax = Tax::where('status', 'draft')->first();

if ($tax) {
    echo "   - Impôt sélectionné: {$tax->reference}\n";
    
    // Calculer
    if ($tax->markAsCalculated()) {
        echo "   ✅ Marqué comme calculé\n";
    }
    
    // Déclarer
    if ($tax->markAsDeclared()) {
        echo "   ✅ Marqué comme déclaré\n";
    }
    
    // Créer un paiement
    $payment = TaxPayment::create([
        'tax_id' => $tax->id,
        'comptable_id' => $comptable->id,
        'payment_reference' => TaxPayment::generateReference($tax->reference),
        'payment_date' => now()->toDateString(),
        'amount_paid' => $tax->total_amount,
        'payment_method' => 'bank_transfer',
        'bank_reference' => 'TEST-' . rand(100000, 999999),
        'notes' => 'Paiement de test',
        'status' => 'validated',
        'validated_at' => now(),
        'validated_by' => $comptable->id
    ]);
    
    echo "   ✅ Paiement créé: {$payment->payment_reference}\n";
    
    // Marquer comme payé
    if ($tax->markAsPaid()) {
        echo "   ✅ Marqué comme payé\n";
    }
}

echo "\n";

// 5. Statistiques
echo "5. Statistiques du système:\n";
echo "   - Catégories d'impôts: " . TaxCategory::count() . "\n";
echo "   - Impôts: " . Tax::count() . "\n";
echo "   - Paiements: " . TaxPayment::count() . "\n";
echo "   - Déclarations: " . TaxDeclaration::count() . "\n";

$stats = Tax::getTaxStats();
echo "   - Montant total des impôts: " . number_format($stats['total_amount'], 2) . " €\n";
echo "   - Montant payé: " . number_format($stats['total_paid'], 2) . " €\n";
echo "   - Montant restant: " . number_format($stats['remaining_amount'], 2) . " €\n";

echo "\n";

// 6. Test des catégories
echo "6. Test des catégories d'impôts:\n";
$categories = TaxCategory::active()->get();
foreach ($categories as $category) {
    echo "   - {$category->name} ({$category->code}): {$category->formatted_rate}\n";
    echo "     * Type: {$category->type_libelle}\n";
    echo "     * Fréquence: {$category->frequency_libelle}\n";
    
    // Test de calcul
    $baseAmount = 10000;
    $calculatedTax = $category->calculateTax($baseAmount);
    echo "     * Test calcul sur {$baseAmount}€: " . number_format($calculatedTax, 2) . " €\n";
}

echo "\n=== Test terminé avec succès ===\n";
