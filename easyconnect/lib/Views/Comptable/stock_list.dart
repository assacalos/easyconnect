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
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                    child: Text(
                      stock.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(stock.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(stock.status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(stock.status),
                      style: TextStyle(
                        color: _getStatusColor(stock.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // SKU
              Row(
                children: [
                  Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'SKU: ${stock.sku}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Quantité
              Row(
                children: [
                  Icon(Icons.inventory, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Quantité: ${stock.quantity.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Prix unitaire
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Prix unitaire: ${formatCurrency.format(stock.unitPrice)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Valeur totale
              Row(
                children: [
                  Icon(Icons.calculate, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    'Total: ${formatCurrency.format(stock.unitPrice * stock.quantity)}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // Raison du rejet si rejeté
              if ((stock.status == 'rejete' || stock.status == 'rejected') &&
                  stock.commentaire != null &&
                  stock.commentaire!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${stock.commentaire}',
                        style: TextStyle(color: Colors.red[700], fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => Get.to(() => StockDetail(stock: stock)),
                  ),
                  if (stock.status == 'en_attente' ||
                      stock.status == 'pending') ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () async {
                        await Get.to(() => StockForm(stock: stock));
                        controller.loadStocks();
                      },
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
}
