import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class StockValidationPage extends StatefulWidget {
  const StockValidationPage({Key? key}) : super(key: key);

  @override
  State<StockValidationPage> createState() => _StockValidationPageState();
}

class _StockValidationPageState extends State<StockValidationPage> {
  final StockService _stockService = StockService();
  List<Stock> _stockList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadStocks();
  }

  Future<void> _loadStocks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 StockValidationPage._loadStocks - Début');
      print('📊 Paramètres: status=$_selectedStatus');

      final stocks = await _stockService.getStocks(status: _selectedStatus);

      print(
        '📊 StockValidationPage._loadStocks - ${stocks.length} stocks chargés',
      );
      for (final stock in stocks) {
        print('📋 Stock: ${stock.id} - Status: ${stock.status}');
      }

      setState(() {
        _stockList = stocks;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ StockValidationPage._loadStocks - Erreur: $e');
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement du stock: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateStock(Stock stock) async {
    try {
      final success = await _stockService.approveStock(stock.id!);
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Stock validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadStocks();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la validation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectStock(Stock stock, String comment) async {
    try {
      final success = await _stockService.rejectStock(stock.id!, comment);
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Stock rejeté avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadStocks();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showValidationDialog(Stock stock) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produit: ${stock.name ?? ''}'),
            const SizedBox(height: 8),
            Text('Quantité: ${stock.quantity}'),
            const SizedBox(height: 8),
            Text('Prix unitaire: ${stock.unitPrice.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Valeur totale: ${stock.totalValue.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${stock.user?.name ?? ''}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce stock ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateStock(stock);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Stock stock) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Produit: ${stock.name ?? ''}'),
            const SizedBox(height: 8),
            Text('Quantité: ${stock.quantity}'),
            const SizedBox(height: 8),
            Text('Valeur totale: ${stock.totalValue.toStringAsFixed(2)} FCFA'),
            const SizedBox(height: 8),
            Text('Soumis par: ${stock.user?.name ?? ''}'),
            const SizedBox(height: 16),
            const Text('Motif du rejet (obligatoire):'),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Saisissez le motif du rejet...',
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
              if (commentController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Veuillez saisir un motif de rejet',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              _rejectStock(stock, commentController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  List<Stock> get _filteredStocks {
    if (_searchQuery.isEmpty) {
      return _stockList;
    }
    return _stockList
        .where(
          (stock) =>
              stock.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              stock.category.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              stock.quantity.toString().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du Stock'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStocks),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: const InputDecoration(
                    hintText:
                        'Rechercher par produit, catégorie ou quantité...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtres de statut
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('En attente'),
                        selected: _selectedStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                          _loadStocks();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validés'),
                        selected: _selectedStatus == 'approved',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                          _loadStocks();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetés'),
                        selected: _selectedStatus == 'rejected',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'rejected';
                          });
                          _loadStocks();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste du stock
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredStocks.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun stock trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredStocks.length,
                      itemBuilder: (context, index) {
                        final stock = _filteredStocks[index];
                        return _buildStockCard(stock);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(Stock stock) {
    final statusColor = _getStatusColor(stock.status);
    final statusText = _getStatusText(stock.status ?? '');
    final statusIcon = _getStatusIcon(stock.status ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stock.name ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Catégorie: ${stock.category}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Quantité: ${stock.quantity}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Prix unitaire: ${stock.unitPrice.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Valeur totale: ${stock.totalValue.toStringAsFixed(2)} FCFA',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${stock.user?.name ?? ''}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stock.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (stock.description != null && stock.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Description: ${stock.description}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (stock.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(stock),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(stock),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Rejeter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (stock.status == 'rejected' &&
                stock.comments != null &&
                stock.comments?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motif du rejet:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock.comments ?? '',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
