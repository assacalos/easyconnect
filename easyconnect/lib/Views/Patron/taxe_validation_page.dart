import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class TaxeValidationPage extends StatefulWidget {
  const TaxeValidationPage({super.key});

  @override
  State<TaxeValidationPage> createState() => _TaxeValidationPageState();
}

class _TaxeValidationPageState extends State<TaxeValidationPage>
    with SingleTickerProviderStateMixin {
  final TaxController controller = Get.find<TaxController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadTaxes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadTaxes();
    }
  }

  Future<void> _loadTaxes() async {
    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 'en_attente';
        break;
      case 2: // Validés
        status = 'valide';
        break;
      case 3: // Rejetés
        status = 'rejete';
        break;
      case 4: // Payés
        status = 'paid';
        break;
    }

    controller.selectedStatus.value = status ?? 'all';
    await controller.loadTaxes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Taxes'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadTaxes();
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
            Tab(text: 'Payés', icon: Icon(Icons.payment)),
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
                hintText: 'Rechercher par nom...',
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
                      ? const SkeletonSearchResults(itemCount: 6)
                      : _buildTaxList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaxList() {
    // Filtrer les taxes selon la recherche
    final filteredTaxes =
        _searchQuery.isEmpty
            ? controller.taxes
            : controller.taxes
                .where(
                  (tax) => tax.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ),
                )
                .toList();

    if (filteredTaxes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucune taxe trouvée'
                  : 'Aucune taxe correspondant à "$_searchQuery"',
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
      itemCount: filteredTaxes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final tax = filteredTaxes[index];
        return _buildTaxCard(context, tax);
      },
    );
  }

  Widget _buildTaxCard(BuildContext context, Tax tax) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );
    final statusColor = _getStatusColor(tax.status);
    final statusIcon = _getStatusIcon(tax.status);
    final statusText = _getStatusText(tax.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          tax.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Montant: ${formatCurrency.format(tax.amount)}'),
            Text('Date d\'échéance: ${formatDate.format(tax.dueDateTime)}'),
            Text(
              'Date création: ${tax.createdAt != null ? formatDate.format(tax.createdAt!) : "N/A"}',
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
                      Text('Nom: ${tax.name}'),
                      Text('Montant: ${formatCurrency.format(tax.amount)}'),
                      Text(
                        'Date d\'échéance: ${formatDate.format(tax.dueDateTime)}',
                      ),
                      Text(
                        'Date création: ${tax.createdAt != null ? formatDate.format(tax.createdAt!) : "N/A"}',
                      ),
                      if (tax.description != null)
                        Text('Description: ${tax.description}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(tax, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Tax tax, Color statusColor) {
    if (tax.isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(tax),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(tax),
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
    } else if (tax.isValidated) {
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
              'Taxe validée',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (tax.isRejected) {
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
              'Taxe rejetée',
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
              'Statut: ${tax.status}',
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
    final statusLower = status.toLowerCase();
    if (statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'declared' ||
        statusLower == 'calculated') {
      return Colors.orange;
    }
    if (statusLower == 'valide' || statusLower == 'validated') {
      return Colors.green;
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return Colors.red;
    }
    if (statusLower == 'paid' || statusLower == 'paye') {
      return Colors.blue;
    }
    return Colors.grey;
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'declared' ||
        statusLower == 'calculated') {
      return Icons.pending;
    }
    if (statusLower == 'valide' || statusLower == 'validated') {
      return Icons.check_circle;
    }
    if (statusLower == 'rejete' || statusLower == 'rejected') {
      return Icons.cancel;
    }
    if (statusLower == 'paid' || statusLower == 'paye') {
      return Icons.payment;
    }
    return Icons.help;
  }

  String _getStatusText(String status) {
    return Tax(status: status, baseAmount: 0).statusText;
  }

  void _showApproveConfirmation(Tax tax) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider cette taxe ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.validateTax(tax);
        _loadTaxes();
      },
    );
  }

  void _showRejectDialog(Tax tax) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter la taxe',
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
        controller.rejectTax(tax, commentController.text);
        _loadTaxes();
      },
    );
  }
}
