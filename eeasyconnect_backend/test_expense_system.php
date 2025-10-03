<?php

require_once 'vendor/autoload.php';

use App\Models\ExpenseCategory;
use App\Models\Expense;
use App\Models\ExpenseApproval;
use App\Models\ExpenseBudget;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du système de dépenses ===\n\n";

// 1. Créer des catégories de dépenses de test
echo "1. Création des catégories de dépenses:\n";

$categories = [
    [
        'name' => 'Transport Test',
        'code' => 'TRANS_TEST',
        'description' => 'Transport pour test',
        'approval_limit' => 50000.00,
        'requires_approval' => true,
        'approval_workflow' => ['manager', 'director']
    ],
    [
        'name' => 'Fournitures Test',
        'code' => 'FOURN_TEST',
        'description' => 'Fournitures pour test',
        'approval_limit' => 25000.00,
        'requires_approval' => true,
        'approval_workflow' => ['manager']
    ]
];

foreach ($categories as $categoryData) {
    $category = ExpenseCategory::firstOrCreate(
        ['code' => $categoryData['code']], 
        $categoryData
    );
    echo "   - Catégorie créée: {$category->name} ({$category->code})\n";
}

echo "\n";

// 2. Vérifier les utilisateurs
echo "2. Vérification des utilisateurs:\n";
$employees = User::where('role', 4)->get();
$managers = User::where('role', 2)->get();
$admins = User::where('role', 1)->get();

echo "   - Employés: " . $employees->count() . "\n";
echo "   - Managers: " . $managers->count() . "\n";
echo "   - Admins: " . $admins->count() . "\n";

if ($employees->isEmpty()) {
    echo "   ⚠️ Aucun employé trouvé. Création d'un employé de test...\n";
    $employee = User::create([
        'nom' => 'Test',
        'prenom' => 'Employé',
        'email' => 'employe.test@example.com',
        'password' => bcrypt('password'),
        'role' => 4,
        'telephone' => '0123456789',
        'date_naissance' => '1985-01-01',
        'adresse' => 'Adresse test',
        'ville' => 'Abidjan',
        'pays' => 'Côte d\'Ivoire'
    ]);
    echo "   - Employé créé: {$employee->prenom} {$employee->nom}\n";
    $employees = collect([$employee]);
}

if ($managers->isEmpty()) {
    echo "   ⚠️ Aucun manager trouvé. Création d'un manager de test...\n";
    $manager = User::create([
        'nom' => 'Test',
        'prenom' => 'Manager',
        'email' => 'manager.test@example.com',
        'password' => bcrypt('password'),
        'role' => 2,
        'telephone' => '0123456789',
        'date_naissance' => '1980-01-01',
        'adresse' => 'Adresse test',
        'ville' => 'Abidjan',
        'pays' => 'Côte d\'Ivoire'
    ]);
    echo "   - Manager créé: {$manager->prenom} {$manager->nom}\n";
    $managers = collect([$manager]);
}

echo "\n";

// 3. Créer des dépenses de test
echo "3. Création de dépenses de test:\n";
$expenseCategories = ExpenseCategory::where('code', 'LIKE', '%TEST%')->get();
$employee = $employees->first();
$manager = $managers->first();

foreach ($expenseCategories as $category) {
    $expense = Expense::create([
        'expense_category_id' => $category->id,
        'employee_id' => $employee->id,
        'expense_number' => Expense::generateExpenseNumber(),
        'expense_date' => now()->format('Y-m-d'),
        'submission_date' => now()->format('Y-m-d'),
        'amount' => 25000.00,
        'currency' => 'EUR',
        'description' => "Test {$category->name}",
        'justification' => 'Justification de test',
        'status' => 'draft'
    ]);
    
    echo "   - Dépense créée: {$expense->expense_number}\n";
    echo "     * Montant: " . number_format($expense->amount, 2) . " €\n";
    echo "     * Catégorie: {$expense->category_name}\n";
    echo "     * Employé: {$expense->employee_name}\n";
    echo "     * Statut: {$expense->status_libelle}\n";
}

echo "\n";

// 4. Tester les transitions d'état
echo "4. Test des transitions d'état:\n";
$expense = Expense::where('status', 'draft')->first();

if ($expense) {
    echo "   - Dépense sélectionnée: {$expense->expense_number}\n";
    
    // Soumettre
    if ($expense->submit()) {
        echo "   ✅ Soumise pour approbation\n";
    }
    
    // Créer une approbation
    $approval = ExpenseApproval::create([
        'expense_id' => $expense->id,
        'approver_id' => $manager->id,
        'approval_level' => 'manager',
        'approval_order' => 1,
        'status' => 'pending',
        'is_required' => true
    ]);
    
    echo "   ✅ Approbation créée: {$approval->approval_level}\n";
    
    // Approuver
    if ($approval->approve('Approbation de test')) {
        echo "   ✅ Approbation accordée\n";
    }
    
    // Approuver la dépense
    if ($expense->approve($manager->id, 'Dépense approuvée')) {
        echo "   ✅ Dépense approuvée\n";
    }
}

echo "\n";

// 5. Statistiques
echo "5. Statistiques du système:\n";
echo "   - Catégories de dépenses: " . ExpenseCategory::count() . "\n";
echo "   - Dépenses: " . Expense::count() . "\n";
echo "   - Approbations: " . ExpenseApproval::count() . "\n";
echo "   - Budgets: " . ExpenseBudget::count() . "\n";

$stats = Expense::getExpenseStats();
echo "   - Montant total des dépenses: " . number_format($stats['total_amount'], 2) . " €\n";
echo "   - Dépenses approuvées: " . $stats['approved_expenses'] . "\n";
echo "   - Dépenses payées: " . $stats['paid_expenses'] . "\n";

echo "\n";

// 6. Test des catégories
echo "6. Test des catégories de dépenses:\n";
$categories = ExpenseCategory::active()->get();
foreach ($categories as $category) {
    echo "   - {$category->name} ({$category->code}): {$category->formatted_approval_limit}\n";
    echo "     * Nécessite approbation: " . ($category->requires_approval ? 'Oui' : 'Non') . "\n";
    echo "     * Workflow: " . implode(' → ', $category->approval_workflow_steps) . "\n";
    
    // Test de calcul d'approbation
    $testAmount = 30000;
    $needsApproval = $category->needsApproval($testAmount);
    echo "     * Test approbation sur {$testAmount}€: " . ($needsApproval ? 'Nécessite approbation' : 'Approbation automatique') . "\n";
}

echo "\n=== Test terminé avec succès ===\n";
