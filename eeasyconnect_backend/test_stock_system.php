<?php

require_once 'vendor/autoload.php';

use App\Models\Stock;
use App\Models\StockCategory;
use App\Models\StockMovement;
use App\Models\StockAlert;
use App\Models\StockOrder;
use App\Models\StockOrderItem;
use App\Models\User;

// Bootstrap Laravel
$app = require_once 'bootstrap/app.php';
$app->make('Illuminate\Contracts\Console\Kernel')->bootstrap();

echo "=== Test du Système de Gestion des Stocks ===\n\n";

try {
    // 1. Vérifier les tables
    echo "1. Vérification des tables:\n";
    echo "   - Stocks: " . Stock::count() . "\n";
    echo "   - Catégories: " . StockCategory::count() . "\n";
    echo "   - Mouvements: " . StockMovement::count() . "\n";
    echo "   - Alertes: " . StockAlert::count() . "\n";
    echo "   - Commandes: " . StockOrder::count() . "\n";
    echo "   - Items de commande: " . StockOrderItem::count() . "\n";
    echo "   - Utilisateurs: " . User::count() . "\n";

    // 2. Créer un stock de test
    echo "\n2. Test de création de stock:\n";
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

    $stock = Stock::create([
        'name' => 'Test de stock',
        'description' => 'Description de test pour le stock',
        'category' => 'Pièces détachées',
        'sku' => 'TEST123456',
        'barcode' => '1234567890123',
        'brand' => 'Test Brand',
        'model' => 'Test Model',
        'unit' => 'pièce',
        'current_quantity' => 100,
        'minimum_quantity' => 20,
        'maximum_quantity' => 500,
        'reorder_point' => 30,
        'unit_cost' => 150,
        'selling_price' => 200,
        'supplier' => 'Test Supplier',
        'location' => 'Entrepôt test',
        'status' => 'active',
        'notes' => 'Notes de test',
        'created_by' => $user->id
    ]);
    
    echo "   ✅ Stock créé: {$stock->name}\n";
    echo "   - Catégorie: {$stock->category}\n";
    echo "   - SKU: {$stock->sku}\n";
    echo "   - Statut: {$stock->status_libelle}\n";
    echo "   - Quantité actuelle: {$stock->formatted_current_quantity}\n";
    echo "   - Quantité minimum: {$stock->formatted_minimum_quantity}\n";
    echo "   - Point de réapprovisionnement: {$stock->formatted_reorder_point}\n";
    echo "   - Coût unitaire: {$stock->formatted_unit_cost}\n";
    echo "   - Prix de vente: {$stock->formatted_selling_price}\n";
    echo "   - Valeur du stock: {$stock->formatted_stock_value}\n";

    // 3. Test des mouvements de stock
    echo "\n3. Test des mouvements de stock:\n";
    
    // Ajouter du stock
    $movement1 = $stock->addStock(50, 160, 'purchase', 'CMD-001', 'Achat de test', $user->id);
    echo "   ✅ Stock ajouté: {$movement1->formatted_quantity} pièces\n";
    echo "   - Type: {$movement1->type_libelle}\n";
    echo "   - Raison: {$movement1->reason_libelle}\n";
    echo "   - Coût total: {$movement1->formatted_total_cost}\n";
    
    // Retirer du stock
    $movement2 = $stock->removeStock(30, 'sale', 'VTE-001', 'Vente de test', $user->id);
    echo "   ✅ Stock retiré: {$movement2->formatted_quantity} pièces\n";
    echo "   - Type: {$movement2->type_libelle}\n";
    echo "   - Raison: {$movement2->reason_libelle}\n";
    
    // Ajuster le stock
    $movement3 = $stock->adjustStock(80, 'adjustment', 'Ajustement de test', $user->id);
    echo "   ✅ Stock ajusté: {$movement3->formatted_quantity} pièces\n";
    echo "   - Type: {$movement3->type_libelle}\n";
    echo "   - Raison: {$movement3->reason_libelle}\n";
    
    // Transférer du stock
    $movement4 = $stock->transferStock(10, 'Bureau', 'Transfert de test', $user->id);
    echo "   ✅ Stock transféré: {$movement4->formatted_quantity} pièces\n";
    echo "   - Type: {$movement4->type_libelle}\n";
    echo "   - De: {$movement4->location_from} vers: {$movement4->location_to}\n";

    // 4. Test des alertes
    echo "\n4. Test des alertes:\n";
    $stock->checkAlerts();
    $alerts = $stock->alerts;
    echo "   - Alertes actives: " . $alerts->where('status', 'active')->count() . "\n";
    foreach ($alerts as $alert) {
        echo "   - {$alert->type_libelle}: {$alert->message} (Priorité: {$alert->priority_libelle})\n";
    }

    // 5. Test des statistiques
    echo "\n5. Test des statistiques:\n";
    $stats = Stock::getStockStats();
    echo "   - Total stocks: {$stats['total_stocks']}\n";
    echo "   - Actifs: {$stats['active_stocks']}\n";
    echo "   - Inactifs: {$stats['inactive_stocks']}\n";
    echo "   - Discontinués: {$stats['discontinued_stocks']}\n";
    echo "   - Stock faible: {$stats['low_stock']}\n";
    echo "   - Stock épuisé: {$stats['out_of_stock']}\n";
    echo "   - Surstock: {$stats['overstock']}\n";
    echo "   - Nécessitent réapprovisionnement: {$stats['needs_reorder']}\n";
    echo "   - Valeur totale: " . number_format($stats['total_value'], 2) . " €\n";
    echo "   - Valeur moyenne: " . number_format($stats['average_value'], 2) . " €\n";

    // 6. Test des catégories
    echo "\n6. Test des catégories:\n";
    $categories = StockCategory::getActiveCategories();
    echo "   - Catégories actives: " . $categories->count() . "\n";
    foreach ($categories as $category) {
        echo "   - {$category->name}: {$category->formatted_color}\n";
    }

    // 7. Test des filtres
    echo "\n7. Test des filtres:\n";
    $activeStocks = Stock::active()->count();
    $lowStockItems = Stock::lowStock()->count();
    $outOfStockItems = Stock::outOfStock()->count();
    $overstockItems = Stock::overstock()->count();
    $needsReorderItems = Stock::needsReorder()->count();
    
    echo "   - Stocks actifs: {$activeStocks}\n";
    echo "   - Stock faible: {$lowStockItems}\n";
    echo "   - Stock épuisé: {$outOfStockItems}\n";
    echo "   - Surstock: {$overstockItems}\n";
    echo "   - Nécessitent réapprovisionnement: {$needsReorderItems}\n";

    // 8. Test des mouvements
    echo "\n8. Test des mouvements:\n";
    $movementStats = StockMovement::getMovementStats();
    echo "   - Total mouvements: {$movementStats['total_movements']}\n";
    echo "   - Entrées: {$movementStats['in_movements']}\n";
    echo "   - Sorties: {$movementStats['out_movements']}\n";
    echo "   - Transferts: {$movementStats['transfer_movements']}\n";
    echo "   - Ajustements: {$movementStats['adjustment_movements']}\n";
    echo "   - Retours: {$movementStats['return_movements']}\n";
    echo "   - Achats: {$movementStats['purchase_movements']}\n";
    echo "   - Ventes: {$movementStats['sale_movements']}\n";
    echo "   - Quantité totale entrée: {$movementStats['total_quantity_in']}\n";
    echo "   - Quantité totale sortie: {$movementStats['total_quantity_out']}\n";
    echo "   - Coût total entrée: " . number_format($movementStats['total_cost_in'], 2) . " €\n";
    echo "   - Coût total sortie: " . number_format($movementStats['total_cost_out'], 2) . " €\n";

    // 9. Test des alertes
    echo "\n9. Test des alertes:\n";
    $alertStats = StockAlert::getAlertStats();
    echo "   - Total alertes: {$alertStats['total_alerts']}\n";
    echo "   - Alertes actives: {$alertStats['active_alerts']}\n";
    echo "   - Alertes acquittées: {$alertStats['acknowledged_alerts']}\n";
    echo "   - Alertes résolues: {$alertStats['resolved_alerts']}\n";
    echo "   - Alertes rejetées: {$alertStats['dismissed_alerts']}\n";
    echo "   - Stock faible: {$alertStats['low_stock_alerts']}\n";
    echo "   - Stock épuisé: {$alertStats['out_of_stock_alerts']}\n";
    echo "   - Surstock: {$alertStats['overstock_alerts']}\n";
    echo "   - Expiration: {$alertStats['expiry_alerts']}\n";
    echo "   - Réapprovisionnement: {$alertStats['reorder_alerts']}\n";
    echo "   - Urgentes: {$alertStats['urgent_alerts']}\n";
    echo "   - Élevées: {$alertStats['high_alerts']}\n";
    echo "   - Moyennes: {$alertStats['medium_alerts']}\n";
    echo "   - Faibles: {$alertStats['low_alerts']}\n";

    // 10. Test des commandes
    echo "\n10. Test des commandes:\n";
    $orderStats = StockOrder::getOrderStats();
    echo "   - Total commandes: {$orderStats['total_orders']}\n";
    echo "   - Brouillons: {$orderStats['draft_orders']}\n";
    echo "   - Envoyées: {$orderStats['sent_orders']}\n";
    echo "   - Confirmées: {$orderStats['confirmed_orders']}\n";
    echo "   - Reçues: {$orderStats['received_orders']}\n";
    echo "   - Annulées: {$orderStats['cancelled_orders']}\n";
    echo "   - En retard: {$orderStats['overdue_orders']}\n";
    echo "   - Montant total: " . number_format($orderStats['total_amount'], 2) . " €\n";
    echo "   - Montant moyen: " . number_format($orderStats['average_amount'], 2) . " €\n";

    // 11. Test des accesseurs
    echo "\n11. Test des accesseurs:\n";
    $stock = Stock::first();
    if ($stock) {
        echo "   - Créateur: {$stock->creator_name}\n";
        echo "   - Modificateur: {$stock->updater_name}\n";
        echo "   - Stock faible: " . ($stock->is_low_stock ? 'Oui' : 'Non') . "\n";
        echo "   - Stock épuisé: " . ($stock->is_out_of_stock ? 'Oui' : 'Non') . "\n";
        echo "   - Surstock: " . ($stock->is_overstock ? 'Oui' : 'Non') . "\n";
        echo "   - Nécessite réapprovisionnement: " . ($stock->needs_reorder ? 'Oui' : 'Non') . "\n";
        echo "   - Valeur du stock: {$stock->formatted_stock_value}\n";
    }

    echo "\n✅ Test du système de stocks terminé avec succès!\n";

} catch (\Exception $e) {
    echo "\n❌ Erreur lors du test: " . $e->getMessage() . "\n";
    echo "   Fichier: " . $e->getFile() . ":" . $e->getLine() . "\n";
}

