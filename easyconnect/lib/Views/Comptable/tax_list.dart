import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class TaxList extends StatefulWidget {
  const TaxList({super.key});

  @override
  State<TaxList> createState() => _TaxListState();
}

class _TaxListState extends State<TaxList> with SingleTickerProviderStateMixin {
  final TaxController controller = Get.find<TaxController>();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _updateFilter();
        });
      }
    });
    // Charger les données après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadTaxes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateFilter() {
    String status;
    switch (_tabController.index) {
      case 0: // Tous
        status = 'all';
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
      default:
        status = 'all';
    }
    controller.filterByStatus(status);
  }

  List<Tax> get _filteredTaxes {
    List<Tax> filtered = List<Tax>.from(controller.allTaxes);

    // Filtrer par statut selon l'onglet actif (normalisation vers les 4 statuts)
    switch (_tabController.index) {
      case 0: // Tous
        // Ne pas filtrer, garder toutes les taxes
        break;
      case 1: // En attente
        filtered =
            filtered.where((t) {
              final statusLower = t.status.toLowerCase();
              return t.isPending ||
                  statusLower == 'en_attente' ||
                  statusLower == 'pending' ||
                  statusLower == 'draft' ||
                  statusLower == 'declared';
            }).toList();
        break;
      case 2: // Validés
        filtered =
            filtered.where((t) {
              final statusLower = t.status.toLowerCase();
              return t.isValidated ||
                  statusLower == 'valide' ||
                  statusLower == 'validated';
            }).toList();
        break;
      case 3: // Rejetés
        filtered =
            filtered.where((t) {
              final statusLower = t.status.toLowerCase();
              return t.isRejected ||
                  statusLower == 'rejete' ||
                  statusLower == 'rejected';
            }).toList();
        break;
      case 4: // Payés
        filtered =
            filtered.where((t) {
              final statusLower = t.status.toLowerCase();
              return t.isPaid || statusLower == 'paye' || statusLower == 'paid';
            }).toList();
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (tax) =>
                    tax.name.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    (tax.category?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (tax.description?.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxes et Impôts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadTaxes,
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
              decoration: InputDecoration(
                hintText: 'Rechercher par nom ou description...',
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

          // Liste des taxes
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const SkeletonSearchResults(itemCount: 6);
              }
              return _filteredTaxes.isEmpty
                  ? const Center(child: Text('Aucune taxe trouvée'))
                  : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTaxes.length,
                    itemBuilder: (context, index) {
                      final tax = _filteredTaxes[index];
                      return _buildTaxCard(tax, formatCurrency);
                    },
                  );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/taxes/new'),
        tooltip: 'Nouvelle taxe',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTaxCard(Tax tax, NumberFormat formatCurrency) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => Get.toNamed('/taxes/${tax.id}'),
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
                      tax.name,
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
                      color: _getStatusColor(tax.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(tax.status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      tax.statusText,
                      style: TextStyle(
                        color: _getStatusColor(tax.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency.format(tax.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date d'échéance
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: ${_formatDate(tax.dueDateTime)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              // Description si disponible
              if (tax.description != null && tax.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tax.description!,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],

              // Raison du rejet si rejeté
              if (tax.isRejected &&
                  tax.rejectionReason != null &&
                  tax.rejectionReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${tax.rejectionReason}',
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
                    onPressed: () => Get.toNamed('/taxes/${tax.id}'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () => _showEditDialog(tax),
                  ),
                  /*  if (tax.isPending) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.green,
                      ),
                      onPressed: () => _showValidateDialog(tax),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _showRejectDialog(tax),
                    ),
                  ], */
                  if (tax.isValidated && !tax.isPaid) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Payé'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                      onPressed: () => _showMarkPaidDialog(tax),
                    ),
                  ],
                  const SizedBox(width: 8),
                  /*  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () => _showDeleteDialog(tax),
                  ), */
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showEditDialog(Tax tax) {
    Get.toNamed('/taxes/${tax.id}/edit', arguments: tax);
  }

  void _showValidateDialog(Tax tax) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider la taxe'),
        content: Text('Valider la taxe "${tax.name}" ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.validateTax(tax);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Tax tax) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la taxe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejeter la taxe "${tax.name}" ?'),
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
                controller.rejectTax(tax, reasonController.text.trim());
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

  void _showMarkPaidDialog(Tax tax) {
    Get.dialog(
      AlertDialog(
        title: const Text('Marquer comme payé'),
        content: Text('Marquer la taxe "${tax.name}" comme payée ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.markTaxAsPaid(tax);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Tax tax) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la taxe'),
        content: Text('Supprimer la taxe "${tax.name}" ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.deleteTax(tax);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
