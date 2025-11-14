import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:intl/intl.dart';

class StockValidationPage extends StatefulWidget {
  const StockValidationPage({super.key});

  @override
  State<StockValidationPage> createState() => _StockValidationPageState();
}

class _StockValidationPageState extends State<StockValidationPage>
    with SingleTickerProviderStateMixin {
  final StockController controller = Get.find<StockController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadStocks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadStocks();
    }
  }

  Future<void> _loadStocks() async {
    // Charger tous les stocks, le filtrage se fera côté client
    controller.selectedStatus.value = 'all';
    await controller.loadStocks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du Stock'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadStocks();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
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
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, catégorie...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : _buildStockList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    // Filtrer les stocks selon l'onglet actif
    List<Stock> filteredStocks;
    switch (_tabController.index) {
      case 0: // Tous
        filteredStocks = controller.stocks;
        break;
      case 1: // En attente
        filteredStocks =
            controller.stocks.where((stock) => stock.isPending).toList();
        break;
      case 2: // Validés
        filteredStocks =
            controller.stocks.where((stock) => stock.isValidated).toList();
        break;
      case 3: // Rejetés
        filteredStocks =
            controller.stocks.where((stock) => stock.isRejected).toList();
        break;
      default:
        filteredStocks = controller.stocks;
    }

    // Filtrer les stocks selon la recherche
    if (_searchQuery.isNotEmpty) {
      filteredStocks =
          filteredStocks
              .where(
                (stock) =>
                    stock.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    stock.category.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (filteredStocks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun article trouvé'
                  : 'Aucun article correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredStocks.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final stock = filteredStocks[index];
        return _buildStockCard(context, stock);
      },
    );
  }

  Widget _buildStockCard(BuildContext context, Stock stock) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(stock.status);
    final statusIcon = _getStatusIcon(stock.status);
    final statusText = _getStatusText(stock.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          stock.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Catégorie: ${stock.category}'),
            Text('Quantité: ${stock.quantity}'),
            Text(
              'Date: ${stock.createdAt != null ? formatDate.format(stock.createdAt!) : "N/A"}',
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations générales
                const Text(
                  'Informations générales',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nom: ${stock.name}'),
                      Text('Catégorie: ${stock.category}'),
                      Text('Quantité: ${stock.quantity}'),
                      Text('Prix unitaire: ${stock.unitPrice}'),
                      Text(
                        'Date: ${stock.createdAt != null ? formatDate.format(stock.createdAt!) : "N/A"}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(stock, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Stock stock, Color statusColor) {
    // Vérifier si le stock est en attente (pending ou en_attente)
    if (stock.isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(stock),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(stock),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (stock.isValidated) {
      // Validé - Afficher seulement info
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Article validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (stock.isRejected) {
      // Rejeté - Afficher motif du rejet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Article rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Autres statuts
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Statut: ${stock.status}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(Stock stock) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider cet article ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveStock(stock);
        _loadStocks();
      },
    );
  }

  void _showRejectDialog(Stock stock) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter l\'article',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Motif du rejet',
              hintText: 'Entrez le motif du rejet',
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'Rejeter',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectStock(
          stock,
          commentaire: commentController.text.trim(),
        );
        _loadStocks();
      },
    );
  }
}
