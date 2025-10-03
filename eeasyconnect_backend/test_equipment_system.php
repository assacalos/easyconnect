<?php

require_once 'vendor/autoload.php';

use App\Models\EquipmentNew;
use App\Models\EquipmentCategory;
use App\Models\EquipmentMaintenance;
use App\Models\EquipmentAssignment;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Gestion des Équipements ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Équipements: " . EquipmentNew::count() . "\n";
    echo "   - Catégories: " . EquipmentCategory::count() . "\n";
    echo "   - Maintenances: " . EquipmentMaintenance::count() . "\n";
    echo "   - Assignations: " . EquipmentAssignment::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer un équipement de test
    echo "\n2. Test de création d'équipement:\n";
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

    $equipment = EquipmentNew::create([
        'name' => 'Test d\'équipement',
        'description' => 'Description de test pour l\'équipement',
        'category' => 'Ordinateurs',
        'status' => 'active',
        'condition' => 'good',
        'serial_number' => 'TEST123456',
        'model' => 'Test Model',
        'brand' => 'Test Brand',
        'location' => 'Bureau test',
        'department' => 'IT',
        'purchase_date' => now()->subMonths(6),
        'warranty_expiry' => now()->addMonths(18),
        'purchase_price' => 150000,
        'current_value' => 120000,
        'supplier' => 'Test Supplier',
        'notes' => 'Notes de test',
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Équipement créé: {$equipment->name}\n";
    echo "   - Catégorie: {$equipment->category}\n";
    echo "   - Statut: {$equipment->status_libelle}\n";
    echo "   - Condition: {$equipment->condition_libelle}\n";
    echo "   - Prix d'achat: {$equipment->formatted_purchase_price}\n";
    echo "   - Valeur actuelle: {$equipment->formatted_current_value}\n";
    echo "   - Âge: {$equipment->age_in_years} ans\n";
    echo "   - Dépréciation: " . number_format($equipment->depreciation_rate, 2) . "%\n";

    // 3. Test des assignations
    echo "\n3. Test des assignations:\n";
    $technician = User::where('role', 5)->first();
    if ($technician) {
        $equipment->assignTo($technician->id, $user->id, 'Assignation de test');
        echo "   ✅ Équipement assigné à: {$technician->prenom} {$technician->nom}\n";
        
        // Retourner l'équipement
        $equipment->returnFrom($user->id, 'Retour de test');
        echo "   ✅ Équipement retourné\n";
    }

    // 4. Test des maintenances
    echo "\n4. Test des maintenances:\n";
    $maintenance = $equipment->scheduleMaintenance(
        'preventive',
        'Maintenance préventive de test',
        now()->addDays(7),
        $technician ? $technician->prenom . ' ' . $technician->nom : null,
        $user->id
    );
    echo "   ✅ Maintenance programmée: {$maintenance->description}\n";
    echo "   - Type: {$maintenance->type_libelle}\n";
    echo "   - Statut: {$maintenance->status_libelle}\n";
    echo "   - Date programmée: {$maintenance->scheduled_date->format('Y-m-d H:i:s')}\n";

    // 5. Test des statistiques
    echo "\n5. Test des statistiques:\n";
    $stats = EquipmentNew::getEquipmentStats();
    echo "   - Total équipements: {$stats['total_equipment']}\n";
    echo "   - Actifs: {$stats['active_equipment']}\n";
    echo "   - En maintenance: {$stats['maintenance_equipment']}\n";
    echo "   - Hors service: {$stats['broken_equipment']}\n";
    echo "   - Retirés: {$stats['retired_equipment']}\n";
    echo "   - Condition excellente: {$stats['excellent_condition']}\n";
    echo "   - Condition bonne: {$stats['good_condition']}\n";
    echo "   - Condition correcte: {$stats['fair_condition']}\n";
    echo "   - Condition mauvaise: {$stats['poor_condition']}\n";
    echo "   - Condition critique: {$stats['critical_condition']}\n";
    echo "   - Nécessitent maintenance: {$stats['needs_maintenance']}\n";
    echo "   - Garantie expirée: {$stats['warranty_expired']}\n";
    echo "   - Garantie expire bientôt: {$stats['warranty_expiring_soon']}\n";
    echo "   - Valeur totale: " . number_format($stats['total_value'], 2) . " €\n";
    echo "   - Âge moyen: " . number_format($stats['average_age'], 1) . " ans\n";

    // 6. Test des catégories
    echo "\n6. Test des catégories:\n";
    $categories = EquipmentCategory::getActiveCategories();
    echo "   - Catégories actives: " . $categories->count() . "\n";
    foreach ($categories as $category) {
        echo "   - {$category->name}: {$category->formatted_color}\n";
    }

    // 7. Test des filtres
    echo "\n7. Test des filtres:\n";
    $activeEquipment = EquipmentNew::active()->count();
    $maintenanceEquipment = EquipmentNew::inMaintenance()->count();
    $brokenEquipment = EquipmentNew::broken()->count();
    $excellentCondition = EquipmentNew::byCondition('excellent')->count();
    $goodCondition = EquipmentNew::byCondition('good')->count();
    $needsMaintenance = EquipmentNew::needsMaintenance()->count();
    $warrantyExpired = EquipmentNew::warrantyExpired()->count();
    
    echo "   - Équipements actifs: {$activeEquipment}\n";
    echo "   - En maintenance: {$maintenanceEquipment}\n";
    echo "   - Hors service: {$brokenEquipment}\n";
    echo "   - Condition excellente: {$excellentCondition}\n";
    echo "   - Condition bonne: {$goodCondition}\n";
    echo "   - Nécessitent maintenance: {$needsMaintenance}\n";
    echo "   - Garantie expirée: {$warrantyExpired}\n";

    // 8. Test des maintenances
    echo "\n8. Test des maintenances:\n";
    $maintenanceStats = EquipmentMaintenance::getMaintenanceStats();
    echo "   - Total maintenances: {$maintenanceStats['total_maintenance']}\n";
    echo "   - Programmées: {$maintenanceStats['scheduled_maintenance']}\n";
    echo "   - En cours: {$maintenanceStats['in_progress_maintenance']}\n";
    echo "   - Terminées: {$maintenanceStats['completed_maintenance']}\n";
    echo "   - Annulées: {$maintenanceStats['cancelled_maintenance']}\n";
    echo "   - Préventives: {$maintenanceStats['preventive_maintenance']}\n";
    echo "   - Correctives: {$maintenanceStats['corrective_maintenance']}\n";
    echo "   - Urgentes: {$maintenanceStats['emergency_maintenance']}\n";
    echo "   - En retard: {$maintenanceStats['overdue_maintenance']}\n";
    echo "   - Coût total: " . number_format($maintenanceStats['total_cost'], 2) . " €\n";
    echo "   - Coût moyen: " . number_format($maintenanceStats['average_cost'], 2) . " €\n";

    // 9. Test des assignations
    echo "\n9. Test des assignations:\n";
    $assignmentStats = EquipmentAssignment::getAssignmentStats();
    echo "   - Total assignations: {$assignmentStats['total_assignments']}\n";
    echo "   - Actives: {$assignmentStats['active_assignments']}\n";
    echo "   - Retournées: {$assignmentStats['returned_assignments']}\n";
    echo "   - Perdues: {$assignmentStats['lost_assignments']}\n";
    echo "   - Endommagées: {$assignmentStats['damaged_assignments']}\n";
    echo "   - Durée moyenne: " . number_format($assignmentStats['average_duration'], 1) . " jours\n";

    // 10. Test des accesseurs
    echo "\n10. Test des accesseurs:\n";
    $equipment = EquipmentNew::first();
    if ($equipment) {
        echo "   - Créateur: {$equipment->creator_name}\n";
        echo "   - Modificateur: {$equipment->updater_name}\n";
        echo "   - Garantie expirée: " . ($equipment->is_warranty_expired ? 'Oui' : 'Non') . "\n";
        echo "   - Garantie expire bientôt: " . ($equipment->is_warranty_expiring_soon ? 'Oui' : 'Non') . "\n";
        echo "   - Nécessite maintenance: " . ($equipment->needs_maintenance ? 'Oui' : 'Non') . "\n";
        echo "   - Âge: {$equipment->age_in_years} ans\n";
        echo "   - Dépréciation: " . number_format($equipment->depreciation_rate, 2) . "%\n";
    }

    echo "\n✅ Test du système d'équipements terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
