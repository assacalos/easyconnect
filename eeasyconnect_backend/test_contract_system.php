<?php

require_once 'vendor/autoload.php';

use App\Models\Contract;
use App\Models\ContractClause;
use App\Models\ContractAttachment;
use App\Models\ContractTemplate;
use App\Models\ContractAmendment;
use App\Models\Employee;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Gestion des Contrats ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Contrats: " . Contract::count() . "\n";
    echo "   - Clauses: " . ContractClause::count() . "\n";
    echo "   - Pièces jointes: " . ContractAttachment::count() . "\n";
    echo "   - Modèles: " . ContractTemplate::count() . "\n";
    echo "   - Amendements: " . ContractAmendment::count() . "\n";
    echo "   - Employés: " . Employee::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer un contrat de test
    echo "\n2. Test de création de contrat:\n";
    $employee = Employee::first();
    $user = User::first();
    
    if (!$employee || !$user) {
        echo "   - Employé ou utilisateur non trouvé, création d'un employé de test...\n";
        $employee = Employee::create([
            'first_name' => 'Test',
            'last_name' => 'Employee',
            'email' => 'test.employee@example.com',
            'phone' => '0123456789',
            'address' => 'Test Address',
            'birth_date' => '1990-01-01',
            'gender' => 'M',
            'marital_status' => 'single',
            'nationality' => 'Ivoirienne',
            'id_number' => '1234567890',
            'social_security_number' => '0987654321',
            'position' => 'Développeur',
            'department' => 'IT',
            'hire_date' => now(),
            'contract_start_date' => now(),
            'contract_end_date' => now()->addYear(),
            'contract_type' => 'permanent',
            'salary' => 300000,
            'currency' => 'FCFA',
            'work_schedule' => 'full_time',
            'status' => 'active',
            'created_by' => $user->id
        ]);
        echo "   - Employé de test créé: {$employee->first_name} {$employee->last_name}\n";
    } else {
        echo "   - Employé existant trouvé: {$employee->first_name} {$employee->last_name}\n";
    }

    $contractNumber = 'CTR-' . date('Y') . '-' . str_pad(Contract::count() + 1, 6, '0', STR_PAD_LEFT) . '-TEST';
    
    $contract = Contract::create([
        'contract_number' => $contractNumber,
        'employee_id' => $employee->id,
        'employee_name' => $employee->first_name . ' ' . $employee->last_name,
        'employee_email' => $employee->email,
        'contract_type' => 'permanent',
        'position' => 'Développeur',
        'department' => 'IT',
        'job_title' => 'Développeur Full Stack',
        'job_description' => 'Développement d\'applications web et mobiles, maintenance du code, collaboration avec l\'équipe.',
        'gross_salary' => 400000,
        'net_salary' => 320000,
        'salary_currency' => 'FCFA',
        'payment_frequency' => 'monthly',
        'start_date' => now(),
        'end_date' => null,
        'duration_months' => null,
        'work_location' => 'Abidjan',
        'work_schedule' => 'full_time',
        'weekly_hours' => 40,
        'probation_period' => '3_months',
        'status' => 'active',
        'notes' => 'Contrat de test pour validation',
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Contrat créé: {$contract->contract_number}\n";
    echo "   - Employé: {$contract->employee_name}\n";
    echo "   - Type: {$contract->contract_type_libelle}\n";
    echo "   - Poste: {$contract->job_title}\n";
    echo "   - Département: {$contract->department}\n";
    echo "   - Salaire brut: {$contract->formatted_gross_salary}\n";
    echo "   - Salaire net: {$contract->formatted_net_salary}\n";
    echo "   - Fréquence: {$contract->payment_frequency_libelle}\n";
    echo "   - Date de début: {$contract->start_date->format('Y-m-d')}\n";
    echo "   - Lieu de travail: {$contract->work_location}\n";
    echo "   - Horaire: {$contract->work_schedule_libelle}\n";
    echo "   - Heures/semaine: {$contract->weekly_hours}\n";
    echo "   - Période d'essai: {$contract->probation_period_libelle}\n";
    echo "   - Statut: {$contract->status_libelle}\n";
    echo "   - Créateur: {$contract->creator_name}\n";

    // 3. Test des clauses
    echo "\n3. Test des clauses:\n";
    $clause = ContractClause::create([
        'contract_id' => $contract->id,
        'title' => 'Durée du contrat',
        'content' => 'Le présent contrat est conclu pour une durée indéterminée.',
        'type' => 'standard',
        'is_mandatory' => true,
        'order' => 1
    ]);
    echo "   ✅ Clause créée: {$clause->title}\n";
    echo "   - Type: {$clause->type_libelle}\n";
    echo "   - Obligatoire: " . ($clause->is_mandatory ? 'Oui' : 'Non') . "\n";
    echo "   - Ordre: {$clause->order}\n";

    // 4. Test des pièces jointes
    echo "\n4. Test des pièces jointes:\n";
    $attachment = ContractAttachment::create([
        'contract_id' => $contract->id,
        'file_name' => 'Contrat_Test.pdf',
        'file_path' => '/contracts/contrat_test.pdf',
        'file_type' => 'pdf',
        'file_size' => 1024000,
        'attachment_type' => 'contract',
        'description' => 'Contrat principal signé',
        'uploaded_at' => now(),
        'uploaded_by' => $user->id
    ]);
    echo "   ✅ Pièce jointe créée: {$attachment->file_name}\n";
    echo "   - Type: {$attachment->attachment_type_libelle}\n";
    echo "   - Taille: {$attachment->formatted_file_size}\n";
    echo "   - Extension: {$attachment->file_extension}\n";
    echo "   - Est PDF: " . ($attachment->is_pdf ? 'Oui' : 'Non') . "\n";
    echo "   - Uploadé par: {$attachment->uploader_name}\n";

    // 5. Test des amendements
    echo "\n5. Test des amendements:\n";
    $amendment = ContractAmendment::create([
        'contract_id' => $contract->id,
        'amendment_type' => 'salary',
        'reason' => 'Augmentation de salaire',
        'description' => 'Modification de la rémunération selon les nouvelles modalités.',
        'changes' => ['gross_salary' => 450000, 'net_salary' => 360000],
        'effective_date' => now()->addMonth(),
        'status' => 'pending',
        'created_by' => $user->id
    ]);
    echo "   ✅ Amendement créé\n";
    echo "   - Type: {$amendment->amendment_type_libelle}\n";
    echo "   - Raison: {$amendment->reason}\n";
    echo "   - Description: {$amendment->description}\n";
    echo "   - Changements: " . json_encode($amendment->changes) . "\n";
    echo "   - Date d'effet: {$amendment->effective_date->format('Y-m-d')}\n";
    echo "   - Statut: {$amendment->status_libelle}\n";
    echo "   - Créateur: {$amendment->creator_name}\n";

    // 6. Test des modèles
    echo "\n6. Test des modèles:\n";
    $template = ContractTemplate::create([
        'name' => 'Modèle CDI IT',
        'description' => 'Modèle de contrat CDI pour le département IT',
        'contract_type' => 'permanent',
        'department' => 'IT',
        'content' => 'Contenu du modèle de contrat CDI pour IT...',
        'is_active' => true,
        'created_by' => $user->id
    ]);
    echo "   ✅ Modèle créé: {$template->name}\n";
    echo "   - Type: {$template->contract_type_libelle}\n";
    echo "   - Département: {$template->department}\n";
    echo "   - Actif: " . ($template->is_active ? 'Oui' : 'Non') . "\n";
    echo "   - Créateur: {$template->creator_name}\n";

    // 7. Test des statistiques
    echo "\n7. Test des statistiques:\n";
    $stats = Contract::getContractStats();
    echo "   - Total contrats: {$stats['total_contracts']}\n";
    echo "   - Brouillons: {$stats['draft_contracts']}\n";
    echo "   - En attente: {$stats['pending_contracts']}\n";
    echo "   - Actifs: {$stats['active_contracts']}\n";
    echo "   - Expirés: {$stats['expired_contracts']}\n";
    echo "   - Résiliés: {$stats['terminated_contracts']}\n";
    echo "   - Expirant bientôt: {$stats['contracts_expiring_soon']}\n";
    echo "   - Salaire moyen: " . number_format($stats['average_salary'], 0, ',', ' ') . " FCFA\n";

    // 8. Test des filtres
    echo "\n8. Test des filtres:\n";
    $draftContracts = Contract::draft()->count();
    $pendingContracts = Contract::pending()->count();
    $activeContracts = Contract::active()->count();
    $expiredContracts = Contract::expiredContracts()->count();
    $terminatedContracts = Contract::terminated()->count();
    $cancelledContracts = Contract::cancelled()->count();
    $permanentContracts = Contract::byType('permanent')->count();
    $itContracts = Contract::byDepartment('IT')->count();
    $expiringSoonContracts = Contract::expiringSoon()->count();
    
    echo "   - Contrats brouillons: {$draftContracts}\n";
    echo "   - Contrats en attente: {$pendingContracts}\n";
    echo "   - Contrats actifs: {$activeContracts}\n";
    echo "   - Contrats expirés: {$expiredContracts}\n";
    echo "   - Contrats résiliés: {$terminatedContracts}\n";
    echo "   - Contrats annulés: {$cancelledContracts}\n";
    echo "   - Contrats CDI: {$permanentContracts}\n";
    echo "   - Contrats IT: {$itContracts}\n";
    echo "   - Contrats expirant bientôt: {$expiringSoonContracts}\n";

    // 9. Test des actions sur le contrat
    echo "\n9. Test des actions sur le contrat:\n";
    echo "   - Peut éditer: " . ($contract->can_edit ? 'Oui' : 'Non') . "\n";
    echo "   - Peut soumettre: " . ($contract->can_submit ? 'Oui' : 'Non') . "\n";
    echo "   - Peut approuver: " . ($contract->can_approve ? 'Oui' : 'Non') . "\n";
    echo "   - Peut rejeter: " . ($contract->can_reject ? 'Oui' : 'Non') . "\n";
    echo "   - Peut résilier: " . ($contract->can_terminate ? 'Oui' : 'Non') . "\n";
    echo "   - Peut annuler: " . ($contract->can_cancel ? 'Oui' : 'Non') . "\n";
    echo "   - Expirant bientôt: " . ($contract->is_expiring_soon ? 'Oui' : 'Non') . "\n";
    echo "   - Expiré: " . ($contract->has_expired ? 'Oui' : 'Non') . "\n";

    // 10. Test des accesseurs
    echo "\n10. Test des accesseurs:\n";
    echo "   - Statut: {$contract->status_libelle}\n";
    echo "   - Type: {$contract->contract_type_libelle}\n";
    echo "   - Fréquence: {$contract->payment_frequency_libelle}\n";
    echo "   - Horaire: {$contract->work_schedule_libelle}\n";
    echo "   - Période d'essai: {$contract->probation_period_libelle}\n";
    echo "   - Salaire brut formaté: {$contract->formatted_gross_salary}\n";
    echo "   - Salaire net formaté: {$contract->formatted_net_salary}\n";
    echo "   - Durée en mois: " . ($contract->duration_in_months ?? 'N/A') . "\n";
    echo "   - Jours restants: " . ($contract->remaining_days ?? 'N/A') . "\n";

    // 11. Test des amendements
    echo "\n11. Test des amendements:\n";
    $amendmentStats = ContractAmendment::getAmendmentStats($contract->id);
    echo "   - Total amendements: {$amendmentStats['total_amendments']}\n";
    echo "   - En attente: {$amendmentStats['pending_amendments']}\n";
    echo "   - Approuvés: {$amendmentStats['approved_amendments']}\n";
    echo "   - Rejetés: {$amendmentStats['rejected_amendments']}\n";

    // 12. Test des pièces jointes
    echo "\n12. Test des pièces jointes:\n";
    $attachmentStats = ContractAttachment::getAttachmentStats($contract->id);
    echo "   - Total pièces jointes: {$attachmentStats['total_attachments']}\n";
    echo "   - Taille totale: " . number_format($attachmentStats['total_size'], 0, ',', ' ') . " bytes\n";
    echo "   - Taille moyenne: " . number_format($attachmentStats['average_size'], 0, ',', ' ') . " bytes\n";

    echo "\n✅ Test du système de contrats terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
