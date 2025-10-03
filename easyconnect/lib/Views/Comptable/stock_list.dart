import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Views/Comptable/stock_form.dart';
import 'package:easyconnect/Views/Comptable/stock_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class StockList extends StatelessWidget {
  const StockList({super.key});

  @override
  Widget build(BuildContext context) {
    final StockController controller = Get.put(StockController());

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion de Stock'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadStocks(),
            ),
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: () {
                print('🐛 DEBUG STOCK: État du contrôleur');
                print('📊 allStocks.length: ${controller.allStocks.length}');
                print('📊 stocks.length: ${controller.stocks.length}');
                print('📊 selectedStatus: ${controller.selectedStatus.value}');
                print('📊 searchQuery: "${controller.searchQuery.value}"');
                print('📊 isLoading: ${controller.isLoading.value}');
                controller.loadStocks();
              },
            ),
            IconButton(
              icon: const Icon(Icons.network_check),
              onPressed: () async {
                print('🧪 Test de connectivité API...');
                try {
                  final isConnected = await controller.testApiConnection();
                  Get.snackbar(
                    'Test de connectivité',
                    isConnected ? 'API accessible ✅' : 'API inaccessible ❌',
                    backgroundColor: isConnected ? Colors.green : Colors.red,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Erreur de test',
                    'Erreur: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Tous'),
              Tab(text: 'En attente'),
              Tab(text: 'Approuvés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Barre de recherche et filtres
                _buildSearchAndFilters(controller),

                // Statistiques rapides
                _buildQuickStats(controller),

                // Liste des stocks avec onglets
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildStockList(controller, 'all'),
                      _buildStockList(controller, 'pending'),
                      _buildStockList(controller, 'approved'),
                      _buildStockList(controller, 'rejected'),
                    ],
                  ),
                ),
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            if (controller.canManageStocks)
              UniformAddButton(
                onPressed: () => Get.to(() => const StockForm()),
                label: 'Nouveau Produit',
                icon: Icons.inventory,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(StockController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.searchStocks(value),
          ),

          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('Toutes'),
                      ),
                      ...controller.stockCategories
                          .map<DropdownMenuItem<String>>((category) {
                            return DropdownMenuItem<String>(
                              value: category['value'] as String,
                              child: Text(category['label'] as String),
                            );
                          })
                          .toList(),
                    ],
                    onChanged: (value) => controller.filterByCategory(value!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(StockController controller) {
    return Obx(() {
      if (controller.stockStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.stockStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats.totalProducts}',
                Icons.inventory,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${controller.stocks.where((s) => s.isPending).length}',
                Icons.pending,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Approuvés',
                '${controller.stocks.where((s) => s.isApproved).length}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Rejetés',
                '${controller.stocks.where((s) => s.isRejected).length}',
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Valeur totale',
                '${NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa').format(stats.totalValue)}',
                Icons.euro,
                Colors.green,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStockList(StockController controller, String status) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Utiliser le filtrage côté client comme les autres pages
      List<Stock> stocksToShow;
      if (status == 'all') {
        stocksToShow = controller.stocks;
      } else {
        stocksToShow =
            controller.stocks.where((stock) {
              switch (status) {
                case 'pending':
                  return stock.isPending;
                case 'approved':
                  return stock.isApproved;
                case 'rejected':
                  return stock.isRejected;
                default:
                  return true;
              }
            }).toList();
      }

      if (stocksToShow.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                status == 'all'
                    ? 'Aucun produit trouvé'
                    : status == 'pending'
                    ? 'Aucun produit en attente'
                    : status == 'approved'
                    ? 'Aucun produit approuvé'
                    : 'Aucun produit rejeté',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter un produit',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: stocksToShow.length,
        itemBuilder: (context, index) {
          final stock = stocksToShow[index];
          return _buildStockCard(stock, controller);
        },
      );
    });
  }

  Widget _buildStockCard(Stock stock, StockController controller) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => StockDetail(stock: stock)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stock.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${stock.sku}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      _buildStatusChip(stock),
                      const SizedBox(height: 4),
                      _buildApprovalStatusChip(stock),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Informations du stock
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      Icons.inventory,
                      'Quantité',
                      stock.formattedQuantity,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.euro,
                      'Prix unitaire',
                      stock.formattedUnitPrice,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoItem(
                      Icons.account_balance_wallet,
                      'Valeur totale',
                      stock.formattedTotalValue,
                      Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Catégorie et emplacement
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    stock.category,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  if (stock.location != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      stock.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),

              // Description
              if (stock.description.isNotEmpty) ...[
                Text(
                  stock.description,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Actions d'approbation pour les produits en attente
                  if (stock.isPending && controller.canManageStocks) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed:
                          () =>
                              _showApprovalDialog(stock, controller, 'approve'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed:
                          () =>
                              _showApprovalDialog(stock, controller, 'reject'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Actions de gestion pour les produits approuvés
                  if (stock.isApproved && controller.canManageStocks) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Entrée'),
                      onPressed:
                          () => _showMovementDialog(stock, controller, 'in'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.remove, size: 16),
                      label: const Text('Sortie'),
                      onPressed:
                          () => _showMovementDialog(stock, controller, 'out'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => Get.to(() => StockForm(stock: stock)),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Actions pour les produits rejetés
                  if (stock.isRejected && controller.canManageStocks) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Réinitialiser'),
                      onPressed:
                          () => _showApprovalDialog(stock, controller, 'reset'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (controller.canViewStocks) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      onPressed: () => Get.to(() => StockDetail(stock: stock)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusChip(Stock stock) {
    Color color;
    switch (stock.stockStatusColor) {
      case 'red':
        color = Colors.red;
        break;
      case 'orange':
        color = Colors.orange;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        stock.stockStatusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildApprovalStatusChip(Stock stock) {
    Color color;
    switch (stock.approvalStatusColor) {
      case 'orange':
        color = Colors.orange;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        stock.approvalStatusText,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showMovementDialog(
    Stock stock,
    StockController controller,
    String type,
  ) {
    final quantityController = TextEditingController();
    final reasonController = TextEditingController();
    final referenceController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: Text('${type == 'in' ? 'Entrée' : 'Sortie'} de stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: InputDecoration(
                labelText: 'Quantité *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.help_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (quantityController.text.isNotEmpty &&
                  reasonController.text.isNotEmpty) {
                controller.selectedMovementType.value = type;
                controller.movementQuantityController.text =
                    quantityController.text;
                controller.movementReasonController.text =
                    reasonController.text;
                controller.movementReferenceController.text =
                    referenceController.text;
                controller.movementNotesController.text = notesController.text;
                controller.addStockMovement(stock);
                Get.back();
              }
            },
            child: Text('${type == 'in' ? 'Ajouter' : 'Retirer'}'),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(
    Stock stock,
    StockController controller,
    String action,
  ) {
    String title;
    String message;
    String confirmText;
    Color confirmColor;

    switch (action) {
      case 'approve':
        title = 'Approuver le produit';
        message = 'Êtes-vous sûr de vouloir approuver ce produit ?';
        confirmText = 'Approuver';
        confirmColor = Colors.green;
        break;
      case 'reject':
        title = 'Rejeter le produit';
        message = 'Êtes-vous sûr de vouloir rejeter ce produit ?';
        confirmText = 'Rejeter';
        confirmColor = Colors.red;
        break;
      case 'reset':
        title = 'Réinitialiser le statut';
        message = 'Êtes-vous sûr de vouloir remettre ce produit en attente ?';
        confirmText = 'Réinitialiser';
        confirmColor = Colors.blue;
        break;
      default:
        return;
    }

    Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              switch (action) {
                case 'approve':
                  controller.approveStock(stock);
                  break;
                case 'reject':
                  controller.rejectStock(stock);
                  break;
                case 'reset':
                  controller.resetStockStatus(stock);
                  break;
              }
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            child: Text(
              confirmText,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
