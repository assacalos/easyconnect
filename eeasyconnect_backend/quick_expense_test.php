<?php

require_once 'vendor/autoload.php';

use App\Models\ExpenseCategory;
use App\Models\Expense;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test Rapide du Système de Dépenses ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Catégories de dépenses: " . ExpenseCategory::count() . "\n";
    echo "   - Dépenses: " . Expense::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer une catégorie de test
    echo "\n2. Test de création de catégorie:\n";
    $category = ExpenseCategory::firstOrCreate(
        ['code' => 'TEST_QUICK'], 
        [
            'name' => 'Test Rapide',
            'description' => 'Catégorie de test rapide',
            'approval_limit' => 10000.00,
            'requires_approval' => true,
            'approval_workflow' => ['manager']
        ]
    );
    echo "   ✅ Catégorie créée: {$category->name}\n";

    // 3. Test des méthodes de la catégorie
    echo "\n3. Test des méthodes:\n";
    $needsApproval = $category->needsApproval(15000);
    echo "   - Besoin d'approbation pour 15000€: " . ($needsApproval ? 'Oui' : 'Non') . "\n";
    
    $requiredApprovers = $category->getRequiredApprovers(15000);
    echo "   - Approbateurs requis: " . implode(', ', $requiredApprovers) . "\n";

    // 4. Créer un utilisateur de test si nécessaire
    $user = User::first();
    if (!$user) {
        $user = User::create([
            'nom' => 'Test',
            'prenom' => 'User',
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
            'role' => 4,
            'telephone' => '0123456789',
            'date_naissance' => '1990-01-01',
            'adresse' => 'Test Address',
            'ville' => 'Test City',
            'pays' => 'Test Country'
        ]);
        echo "\n4. Utilisateur de test créé: {$user->email}\n";
    } else {
        echo "\n4. Utilisateur existant trouvé: {$user->email}\n";
    }

    // 5. Créer une dépense de test
    echo "\n5. Test de création de dépense:\n";
    $expense = Expense::create([
        'expense_category_id' => $category->id,
        'employee_id' => $user->id,
        'expense_number' => Expense::generateExpenseNumber(),
        'expense_date' => now()->format('Y-m-d'),
        'submission_date' => now()->format('Y-m-d'),
        'amount' => 5000.00,
        'currency' => 'EUR',
        'description' => 'Test de dépense rapide',
        'justification' => 'Justification de test',
        'status' => 'draft'
    ]);
    
    echo "   ✅ Dépense créée: {$expense->expense_number}\n";
    echo "   - Montant: {$expense->formatted_amount}\n";
    echo "   - Statut: {$expense->status_libelle}\n";
    echo "   - Peut être éditée: " . ($expense->canBeEdited() ? 'Oui' : 'Non') . "\n";

    // 6. Statistiques rapides
    echo "\n6. Statistiques:\n";
    $stats = Expense::getExpenseStats();
    echo "   - Total dépenses: {$stats['total_expenses']}\n";
    echo "   - Montant total: " . number_format($stats['total_amount'], 2) . " €\n";
    echo "   - Dépenses approuvées: {$stats['approved_expenses']}\n";

    echo "\n✅ Test rapide terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
