import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/Views/Comptable/stock_form.dart';
import 'package:easyconnect/Views/Comptable/stock_detail.dart';
import 'package:intl/intl.dart';

class StockList extends StatefulWidget {
  const StockList({super.key});

  @override
  State<StockList> createState() => _StockListState();
}

class _StockListState extends State<StockList>
    with SingleTickerProviderStateMixin {
  final StockController controller = Get.put(StockController());
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        // Rebuild quand l'onglet change pour mettre à jour le filtre
        setState(() {});
      }
    });
    controller.loadStocks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStocks,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Approuvés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, SKU ou description...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Liste des stocks
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              // Filtrer directement ici pour que Obx détecte les changements
              List<Stock> filtered = List.from(controller.allStocks);

              // Filtrer par statut selon l'onglet actif
              switch (_tabController.index) {
                case 0: // Tous
                  break;
                case 1: // En attente
                  filtered =
                      filtered
                          .where(
                            (s) =>
                                s.status == 'en_attente' ||
                                s.status == 'pending',
                          )
                          .toList();
                  break;
                case 2: // Validés/Approuvés
                  filtered =
                      filtered
                          .where(
                            (s) =>
                                s.status == 'valide' || s.status == 'approved',
                          )
                          .toList();
                  break;
                case 3: // Rejetés
                  filtered =
                      filtered
                          .where(
                            (s) =>
                                s.status == 'rejete' || s.status == 'rejected',
                          )
                          .toList();
                  break;
              }

              // Filtrer par recherche
              if (_searchQuery.isNotEmpty) {
                filtered =
                    filtered
                        .where(
                          (stock) =>
                              stock.name.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              (stock.description?.toLowerCase() ?? '').contains(
                                _searchQuery.toLowerCase(),
                              ) ||
                              stock.sku.toLowerCase().contains(
                                _searchQuery.toLowerCase(),
                              ),
                        )
                        .toList();
              }

              return filtered.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Aucun produit trouvé'),
                        Text(
                          'Total stocks chargés: ${controller.allStocks.length}',
                        ),
                        Text('Onglet: ${_tabController.index}'),
                      ],
                    ),
                  )
                  : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final stock = filtered[index];
                      return _buildStockCard(stock, formatCurrency);
                    },
                  );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Get.to(() => const StockForm());
          // Recharger les stocks après retour du formulaire
          controller.loadStocks();
        },
        tooltip: 'Nouveau produit',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStockCard(Stock stock, NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(stock.status),
          child: Icon(_getStatusIcon(stock.status), color: Colors.white),
        ),
        title: Text(
          stock.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SKU: ${stock.sku}'),
            Text('Quantité: ${stock.quantity.toStringAsFixed(0)}'),
            Text('Prix unitaire: ${formatCurrency.format(stock.unitPrice)}'),
            if ((stock.status == 'rejete' || stock.status == 'rejected') &&
                stock.commentaire != null &&
                stock.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${stock.commentaire}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton Détail
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => Get.to(() => StockDetail(stock: stock)),
              tooltip: 'Voir détails',
            ),
            // Bouton Modifier (seulement si en attente)
            if (stock.status == 'en_attente' || stock.status == 'pending')
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () async {
                  await Get.to(() => StockForm(stock: stock));
                  // Recharger les stocks après retour du formulaire
                  controller.loadStocks();
                },
                tooltip: 'Modifier',
              ),
            // Menu pour actions supplémentaires
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'approve') {
                  _showApproveDialog(stock);
                } else if (value == 'reject') {
                  _showRejectDialog(stock);
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                if (stock.status == 'en_attente' || stock.status == 'pending') {
                  items.add(
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        leading: Icon(Icons.check, color: Colors.green),
                        title: Text('Valider'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                  items.add(
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        leading: Icon(Icons.close, color: Colors.red),
                        title: Text('Rejeter'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }
                return items;
              },
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(stock.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(stock.status),
                    style: TextStyle(
                      color: _getStatusColor(stock.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency.format(stock.unitPrice * stock.quantity),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => Get.to(() => StockDetail(stock: stock)),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Colors.orange;
      case 'valide':
      case 'approved':
        return Colors.green;
      case 'rejete':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return Icons.pending;
      case 'valide':
      case 'approved':
        return Icons.check_circle;
      case 'rejete':
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'en_attente':
      case 'pending':
        return 'En attente';
      case 'valide':
      case 'approved':
        return 'Validé';
      case 'rejete':
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveDialog(Stock stock) {
    Get.dialog(
      AlertDialog(
        title: const Text('Approuver le produit'),
        content: Text('Approuver le produit "${stock.name}" ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Note: Approbation supprimée selon la nouvelle API (statuts: active/inactive/discontinued)
              Get.back();
              Get.snackbar(
                'Info',
                'Utilisez le statut "active" pour activer un produit',
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Stock stock) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le produit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter le produit "${stock.name}" ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectStock(
                  stock,
                  commentaire: reasonController.text.trim(),
                );
                Get.back();
              } else {
                Get.snackbar('Erreur', 'Veuillez indiquer la raison du rejet');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
