<?php

require_once 'vendor/autoload.php';

use App\Models\Employee;
use App\Models\EmployeeDocument;
use App\Models\EmployeeLeave;
use App\Models\EmployeePerformance;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Gestion des Employés ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Employés: " . Employee::count() . "\n";
    echo "   - Documents: " . EmployeeDocument::count() . "\n";
    echo "   - Congés: " . EmployeeLeave::count() . "\n";
    echo "   - Performances: " . EmployeePerformance::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer un employé de test
    echo "\n2. Test de création d'employé:\n";
    $user = User::first();
    if (!$user) {
        $user = User::create([
            'nom' => 'Test',
            'prenom' => 'User',
            'email' => 'test@example.com',
            'password' => bcrypt('password'),
            'role' => 5,
            'telephone' => '0123456789',
            'date_naissance' => '1990-01-01',
            'adresse' => 'Test Address',
            'ville' => 'Test City',
            'pays' => 'Test Country'
        ]);
        echo "   - Utilisateur de test créé: {$user->email}\n";
    } else {
        echo "   - Utilisateur existant trouvé: {$user->email}\n";
    }

    $employee = Employee::create([
        'first_name' => 'Test',
        'last_name' => 'Employee',
        'email' => 'test.employee@example.com',
        'phone' => '0123456789',
        'address' => 'Test Address',
        'birth_date' => '1990-01-01',
        'gender' => 'male',
        'marital_status' => 'single',
        'nationality' => 'Ivoirienne',
        'id_number' => 'ID123456789',
        'social_security_number' => 'SS123456789',
        'position' => 'Développeur',
        'department' => 'IT',
        'manager' => 'Manager Test',
        'hire_date' => '2020-01-01',
        'contract_start_date' => '2020-01-01',
        'contract_end_date' => '2025-12-31',
        'contract_type' => 'permanent',
        'salary' => 150000,
        'currency' => 'FCFA',
        'work_schedule' => '8h-17h',
        'status' => 'active',
        'notes' => 'Notes de test',
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Employé créé: {$employee->full_name}\n";
    echo "   - Email: {$employee->email}\n";
    echo "   - Poste: {$employee->position}\n";
    echo "   - Département: {$employee->department}\n";
    echo "   - Statut: {$employee->status_libelle}\n";
    echo "   - Genre: {$employee->gender_libelle}\n";
    echo "   - Statut matrimonial: {$employee->marital_status_libelle}\n";
    echo "   - Type de contrat: {$employee->contract_type_libelle}\n";
    echo "   - Salaire: {$employee->formatted_salary}\n";
    echo "   - Âge: {$employee->age} ans\n";
    echo "   - Initiales: {$employee->initials}\n";

    // 3. Test des documents
    echo "\n3. Test des documents:\n";
    $document = EmployeeDocument::create([
        'employee_id' => $employee->id,
        'name' => 'Contrat de travail',
        'type' => 'contract',
        'description' => 'Contrat de travail principal',
        'file_path' => '/documents/contract.pdf',
        'file_size' => 1024000,
        'expiry_date' => '2025-12-31',
        'is_required' => true,
        'created_by' => $user->id
    ]);
    echo "   ✅ Document créé: {$document->name}\n";
    echo "   - Type: {$document->type_libelle}\n";
    echo "   - Taille: {$document->formatted_file_size}\n";
    echo "   - Requis: " . ($document->is_required ? 'Oui' : 'Non') . "\n";
    echo "   - Expire: " . ($document->is_expiring ? 'Bientôt' : 'Non') . "\n";

    // 4. Test des congés
    echo "\n4. Test des congés:\n";
    $leave = EmployeeLeave::create([
        'employee_id' => $employee->id,
        'type' => 'annual',
        'start_date' => '2024-12-01',
        'end_date' => '2024-12-15',
        'total_days' => 15,
        'reason' => 'Congé annuel',
        'status' => 'approved',
        'approved_by' => $user->id,
        'approved_at' => now(),
        'created_by' => $user->id
    ]);
    echo "   ✅ Congé créé: {$leave->type_libelle}\n";
    echo "   - Période: {$leave->start_date->format('Y-m-d')} au {$leave->end_date->format('Y-m-d')}\n";
    echo "   - Durée: {$leave->total_days} jours\n";
    echo "   - Statut: {$leave->status_libelle}\n";
    echo "   - Approuvé par: {$leave->approver_name}\n";

    // 5. Test des performances
    echo "\n5. Test des performances:\n";
    $performance = EmployeePerformance::create([
        'employee_id' => $employee->id,
        'period' => '2024-Q4',
        'rating' => 4.5,
        'comments' => 'Excellent travail',
        'goals' => 'Objectifs atteints',
        'achievements' => 'Réalisations importantes',
        'areas_for_improvement' => 'Domaines d\'amélioration',
        'status' => 'approved',
        'reviewed_by' => $user->id,
        'reviewed_at' => now(),
        'created_by' => $user->id
    ]);
    echo "   ✅ Performance créée: {$performance->period}\n";
    echo "   - Note: {$performance->formatted_rating}/5\n";
    echo "   - Évaluation: {$performance->rating_text}\n";
    echo "   - Statut: {$performance->status_libelle}\n";
    echo "   - Évalué par: {$performance->reviewer_name}\n";

    // 6. Test des statistiques
    echo "\n6. Test des statistiques:\n";
    $stats = Employee::getEmployeeStats();
    echo "   - Total employés: {$stats['total_employees']}\n";
    echo "   - Actifs: {$stats['active_employees']}\n";
    echo "   - Inactifs: {$stats['inactive_employees']}\n";
    echo "   - En congé: {$stats['on_leave_employees']}\n";
    echo "   - Terminés: {$stats['terminated_employees']}\n";
    echo "   - Nouveaux embauchés ce mois: {$stats['new_hires_this_month']}\n";
    echo "   - Départs ce mois: {$stats['departures_this_month']}\n";
    echo "   - Salaire moyen: " . number_format($stats['average_salary'], 2) . " FCFA\n";
    echo "   - Contrats expirant: {$stats['expiring_contracts']}\n";
    echo "   - Contrats expirés: {$stats['expired_contracts']}\n";

    // 7. Test des filtres
    echo "\n7. Test des filtres:\n";
    $activeEmployees = Employee::active()->count();
    $itEmployees = Employee::byDepartment('IT')->count();
    $maleEmployees = Employee::byGender('male')->count();
    $permanentEmployees = Employee::byContractType('permanent')->count();
    $contractExpiring = Employee::contractExpiring()->count();
    $contractExpired = Employee::contractExpired()->count();
    
    echo "   - Employés actifs: {$activeEmployees}\n";
    echo "   - Employés IT: {$itEmployees}\n";
    echo "   - Employés masculins: {$maleEmployees}\n";
    echo "   - Employés permanents: {$permanentEmployees}\n";
    echo "   - Contrats expirant: {$contractExpiring}\n";
    echo "   - Contrats expirés: {$contractExpired}\n";

    // 8. Test des documents
    echo "\n8. Test des documents:\n";
    $documentStats = EmployeeDocument::getDocumentStats();
    echo "   - Total documents: {$documentStats['total_documents']}\n";
    echo "   - Documents requis: {$documentStats['required_documents']}\n";
    echo "   - Documents optionnels: {$documentStats['optional_documents']}\n";
    echo "   - Documents expirant: {$documentStats['expiring_documents']}\n";
    echo "   - Documents expirés: {$documentStats['expired_documents']}\n";

    // 9. Test des congés
    echo "\n9. Test des congés:\n";
    $leaveStats = EmployeeLeave::getLeaveStats();
    echo "   - Total congés: {$leaveStats['total_leaves']}\n";
    echo "   - En attente: {$leaveStats['pending_leaves']}\n";
    echo "   - Approuvés: {$leaveStats['approved_leaves']}\n";
    echo "   - Rejetés: {$leaveStats['rejected_leaves']}\n";
    echo "   - Congés annuels: {$leaveStats['annual_leaves']}\n";
    echo "   - Congés maladie: {$leaveStats['sick_leaves']}\n";
    echo "   - Congés maternité: {$leaveStats['maternity_leaves']}\n";
    echo "   - Congés paternité: {$leaveStats['paternity_leaves']}\n";
    echo "   - Congés personnels: {$leaveStats['personal_leaves']}\n";
    echo "   - Congés sans solde: {$leaveStats['unpaid_leaves']}\n";
    echo "   - Congés actuels: {$leaveStats['current_leaves']}\n";
    echo "   - Congés à venir: {$leaveStats['upcoming_leaves']}\n";
    echo "   - Total jours: {$leaveStats['total_days']}\n";
    echo "   - Moyenne jours: " . number_format($leaveStats['average_days'], 1) . "\n";

    // 10. Test des performances
    echo "\n10. Test des performances:\n";
    $performanceStats = EmployeePerformance::getPerformanceStats();
    echo "   - Total performances: {$performanceStats['total_performances']}\n";
    echo "   - Brouillons: {$performanceStats['draft_performances']}\n";
    echo "   - Soumises: {$performanceStats['submitted_performances']}\n";
    echo "   - Évaluées: {$performanceStats['reviewed_performances']}\n";
    echo "   - Approuvées: {$performanceStats['approved_performances']}\n";
    echo "   - Excellentes: {$performanceStats['excellent_performances']}\n";
    echo "   - Bonnes: {$performanceStats['good_performances']}\n";
    echo "   - Moyennes: {$performanceStats['average_performances']}\n";
    echo "   - Faibles: {$performanceStats['poor_performances']}\n";
    echo "   - Nécessitent amélioration: {$performanceStats['needs_improvement']}\n";
    echo "   - Note moyenne: " . number_format($performanceStats['average_rating'], 1) . "/5\n";
    echo "   - Note la plus haute: " . number_format($performanceStats['highest_rating'], 1) . "/5\n";
    echo "   - Note la plus basse: " . number_format($performanceStats['lowest_rating'], 1) . "/5\n";

    // 11. Test des accesseurs
    echo "\n11. Test des accesseurs:\n";
    $employee = Employee::first();
    if ($employee) {
        echo "   - Créateur: {$employee->creator_name}\n";
        echo "   - Modificateur: {$employee->updater_name}\n";
        echo "   - Contrat expirant: " . ($employee->is_contract_expiring ? 'Oui' : 'Non') . "\n";
        echo "   - Contrat expiré: " . ($employee->is_contract_expired ? 'Oui' : 'Non') . "\n";
        echo "   - Actif: " . ($employee->is_active ? 'Oui' : 'Non') . "\n";
        echo "   - Inactif: " . ($employee->is_inactive ? 'Oui' : 'Non') . "\n";
        echo "   - Terminé: " . ($employee->is_terminated ? 'Oui' : 'Non') . "\n";
        echo "   - En congé: " . ($employee->is_on_leave ? 'Oui' : 'Non') . "\n";
    }

    echo "\n✅ Test du système d'employés terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
