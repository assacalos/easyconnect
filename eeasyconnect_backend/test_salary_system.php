<?php

require_once 'vendor/autoload.php';

use App\Models\SalaryComponent;
use App\Models\Salary;
use App\Models\SalaryItem;
use App\Models\Payroll;
use App\Models\PayrollSetting;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Salaires ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Composants de salaire: " . SalaryComponent::count() . "\n";
    echo "   - Salaires: " . Salary::count() . "\n";
    echo "   - Éléments de salaire: " . SalaryItem::count() . "\n";
    echo "   - Bulletins de paie: " . Payroll::count() . "\n";
    echo "   - Paramètres: " . PayrollSetting::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer un composant de test
    echo "\n2. Test de création de composant:\n";
    $component = SalaryComponent::firstOrCreate(
        ['code' => 'TEST_COMP'], 
        [
            'name' => 'Composant Test',
            'description' => 'Composant de test pour validation',
            'type' => 'allowance',
            'calculation_type' => 'percentage',
            'default_value' => 15,
            'is_taxable' => true,
            'is_social_security' => true,
            'is_mandatory' => false,
            'is_active' => true
        ]
    );
    echo "   ✅ Composant créé: {$component->name}\n";

    // 3. Test des méthodes du composant
    echo "\n3. Test des méthodes du composant:\n";
    $baseAmount = 100000;
    $calculatedAmount = $component->calculateAmount($baseAmount);
    echo "   - Calcul sur {$baseAmount}€: {$calculatedAmount}€\n";
    echo "   - Type: {$component->type_libelle}\n";
    echo "   - Calcul: {$component->calculation_type_libelle}\n";
    echo "   - Valeur par défaut: {$component->formatted_default_value}\n";

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

    // 5. Créer un salaire de test
    echo "\n5. Test de création de salaire:\n";
    $salary = Salary::create([
        'employee_id' => $user->id,
        'hr_id' => $user->id,
        'salary_number' => Salary::generateSalaryNumber(),
        'period' => '2025-01',
        'period_start' => '2025-01-01',
        'period_end' => '2025-01-31',
        'payment_date' => '2025-02-05',
        'base_salary' => 150000,
        'gross_salary' => 0,
        'net_salary' => 0,
        'status' => 'draft'
    ]);
    
    echo "   ✅ Salaire créé: {$salary->salary_number}\n";
    echo "   - Salaire de base: {$salary->formatted_base_salary}\n";
    echo "   - Statut: {$salary->status_libelle}\n";
    echo "   - Peut être calculé: " . ($salary->canBeCalculated() ? 'Oui' : 'Non') . "\n";

    // 6. Test du calcul de salaire
    echo "\n6. Test du calcul de salaire:\n";
    if ($salary->calculateSalary()) {
        echo "   ✅ Salaire calculé avec succès\n";
        echo "   - Salaire brut: {$salary->formatted_gross_salary}\n";
        echo "   - Salaire net: {$salary->formatted_net_salary}\n";
        echo "   - Indemnités: {$salary->formatted_total_allowances}\n";
        echo "   - Déductions: {$salary->formatted_total_deductions}\n";
        echo "   - Impôts: {$salary->formatted_total_taxes}\n";
        echo "   - Charges sociales: {$salary->formatted_total_social_security}\n";
    } else {
        echo "   ❌ Erreur lors du calcul du salaire\n";
    }

    // 7. Test des éléments de salaire
    echo "\n7. Test des éléments de salaire:\n";
    $items = $salary->salaryItems;
    echo "   - Nombre d'éléments: " . $items->count() . "\n";
    foreach ($items as $item) {
        echo "   - {$item->name}: {$item->formatted_amount} ({$item->type_libelle})\n";
    }

    // 8. Test des paramètres de paie
    echo "\n8. Test des paramètres de paie:\n";
    $taxRate = PayrollSetting::getTaxRate();
    $socialSecurityRate = PayrollSetting::getSocialSecurityRate();
    $minimumWage = PayrollSetting::getMinimumWage();
    echo "   - Taux d'impôt: {$taxRate}%\n";
    echo "   - Taux charges sociales: {$socialSecurityRate}%\n";
    echo "   - Salaire minimum: " . number_format($minimumWage, 2, ',', ' ') . " €\n";

    // 9. Statistiques
    echo "\n9. Statistiques du système:\n";
    $stats = Salary::getSalaryStats();
    echo "   - Total salaires: {$stats['total_salaries']}\n";
    echo "   - Salaires brouillons: {$stats['draft_salaries']}\n";
    echo "   - Salaires calculés: {$stats['calculated_salaries']}\n";
    echo "   - Salaires approuvés: {$stats['approved_salaries']}\n";
    echo "   - Salaires payés: {$stats['paid_salaries']}\n";
    echo "   - Total salaires bruts: " . number_format($stats['total_gross_salary'], 2, ',', ' ') . " €\n";
    echo "   - Total salaires nets: " . number_format($stats['total_net_salary'], 2, ',', ' ') . " €\n";

    // 10. Test des composants actifs
    echo "\n10. Test des composants actifs:\n";
    $activeComponents = SalaryComponent::getActiveComponents();
    echo "   - Composants actifs: " . $activeComponents->count() . "\n";
    foreach ($activeComponents as $comp) {
        echo "   - {$comp->name} ({$comp->code}): {$comp->formatted_default_value}\n";
    }

    echo "\n✅ Test du système de salaires terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
