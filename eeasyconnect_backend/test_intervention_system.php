<?php

require_once 'vendor/autoload.php';

use App\Models\Intervention;
use App\Models\InterventionType;
use App\Models\Equipment;
use App\Models\InterventionReport;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système d'Interventions ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Interventions: " . Intervention::count() . "\n";
    echo "   - Types d'interventions: " . InterventionType::count() . "\n";
    echo "   - Équipements: " . Equipment::count() . "\n";
    echo "   - Rapports d'interventions: " . InterventionReport::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer une intervention de test
    echo "\n2. Test de création d'intervention:\n";
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

    $intervention = Intervention::create([
        'title' => 'Test d\'intervention',
        'description' => 'Description de test pour l\'intervention',
        'type' => 'external',
        'status' => 'pending',
        'priority' => 'medium',
        'scheduled_date' => now()->addDays(1),
        'location' => 'Adresse de test',
        'client_name' => 'Client Test',
        'client_phone' => '0123456789',
        'client_email' => 'client@test.com',
        'equipment' => 'Équipement de test',
        'problem_description' => 'Problème de test',
        'estimated_duration' => 2.5,
        'cost' => 50000,
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Intervention créée: {$intervention->title}\n";
    echo "   - Type: {$intervention->type_libelle}\n";
    echo "   - Statut: {$intervention->status_libelle}\n";
    echo "   - Priorité: {$intervention->priority_libelle}\n";
    echo "   - Peut être approuvée: " . ($intervention->canBeApproved() ? 'Oui' : 'Non') . "\n";

    // 3. Test des transitions d'état
    echo "\n3. Test des transitions d'état:\n";
    
    // Approuver
    if ($intervention->approve($user->id, 'Approbation de test')) {
        echo "   ✅ Intervention approuvée\n";
    }
    
    // Démarrer
    if ($intervention->start()) {
        echo "   ✅ Intervention démarrée\n";
    }
    
    // Terminer
    if ($intervention->complete('Intervention terminée avec succès', 3.0, 75000)) {
        echo "   ✅ Intervention terminée\n";
    }

    // 4. Test des statistiques
    echo "\n4. Test des statistiques:\n";
    $stats = Intervention::getInterventionStats();
    echo "   - Total interventions: {$stats['total_interventions']}\n";
    echo "   - En attente: {$stats['pending_interventions']}\n";
    echo "   - Approuvées: {$stats['approved_interventions']}\n";
    echo "   - En cours: {$stats['in_progress_interventions']}\n";
    echo "   - Terminées: {$stats['completed_interventions']}\n";
    echo "   - Rejetées: {$stats['rejected_interventions']}\n";
    echo "   - Externes: {$stats['external_interventions']}\n";
    echo "   - Sur place: {$stats['on_site_interventions']}\n";
    echo "   - Durée moyenne: " . number_format($stats['average_duration'], 2) . "h\n";
    echo "   - Coût total: " . number_format($stats['total_cost'], 2) . " €\n";

    // 5. Test des types d'interventions
    echo "\n5. Test des types d'interventions:\n";
    $types = InterventionType::getActiveTypes();
    echo "   - Types actifs: " . $types->count() . "\n";
    foreach ($types as $type) {
        echo "   - {$type->name} ({$type->code}): {$type->formatted_color}\n";
    }

    // 6. Test des équipements
    echo "\n6. Test des équipements:\n";
    $equipment = Equipment::getActiveEquipment();
    echo "   - Équipements actifs: " . $equipment->count() . "\n";
    foreach ($equipment->take(5) as $eq) {
        echo "   - {$eq->name} ({$eq->brand} {$eq->model}): {$eq->status_libelle}\n";
    }

    // 7. Test des interventions en retard
    echo "\n7. Test des interventions en retard:\n";
    $overdue = Intervention::getOverdueInterventions();
    echo "   - Interventions en retard: " . $overdue->count() . "\n";

    // 8. Test des interventions dues bientôt
    echo "\n8. Test des interventions dues bientôt:\n";
    $dueSoon = Intervention::getDueSoonInterventions();
    echo "   - Interventions dues bientôt: " . $dueSoon->count() . "\n";

    // 9. Test des filtres
    echo "\n9. Test des filtres:\n";
    $externalInterventions = Intervention::external()->count();
    $onSiteInterventions = Intervention::onSite()->count();
    $highPriorityInterventions = Intervention::byPriority('high')->count();
    $urgentInterventions = Intervention::byPriority('urgent')->count();
    
    echo "   - Interventions externes: {$externalInterventions}\n";
    echo "   - Interventions sur place: {$onSiteInterventions}\n";
    echo "   - Priorité élevée: {$highPriorityInterventions}\n";
    echo "   - Priorité urgente: {$urgentInterventions}\n";

    // 10. Test des accesseurs
    echo "\n10. Test des accesseurs:\n";
    $intervention = Intervention::first();
    if ($intervention) {
        echo "   - Créateur: {$intervention->creator_name}\n";
        echo "   - Approbateur: {$intervention->approver_name}\n";
        echo "   - Coût formaté: {$intervention->formatted_cost}\n";
        echo "   - Durée estimée: {$intervention->formatted_estimated_duration}\n";
        echo "   - Durée réelle: {$intervention->formatted_actual_duration}\n";
        echo "   - En retard: " . ($intervention->is_overdue ? 'Oui' : 'Non') . "\n";
        echo "   - Due bientôt: " . ($intervention->is_due_soon ? 'Oui' : 'Non') . "\n";
    }

    echo "\n✅ Test du système d'interventions terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}
