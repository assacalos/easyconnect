import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:intl/intl.dart';

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
    controller.loadTaxes();
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
                return const Center(child: CircularProgressIndicator());
              }
              return _filteredTaxes.isEmpty
                  ? const Center(child: Text('Aucune taxe trouvée'))
                  : ListView.builder(
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(tax.status),
          child: Icon(_getStatusIcon(tax.status), color: Colors.white),
        ),
        title: Text(
          tax.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Montant: ${formatCurrency.format(tax.amount)}'),
            Text('Date d\'échéance: ${_formatDate(tax.dueDateTime)}'),
            if (tax.description != null && tax.description!.isNotEmpty)
              Text('Description: ${tax.description}'),
            if (tax.status == 'rejected' &&
                tax.rejectionReason != null &&
                tax.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${tax.rejectionReason}',
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
              onPressed: () => _showTaxDetails(tax),
              tooltip: 'Voir détails',
            ),
            // Bouton Modifier
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.orange),
              onPressed: () => _showEditDialog(tax),
              tooltip: 'Modifier',
            ),
            // Menu pour actions supplémentaires
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'validate') {
                  _showValidateDialog(tax);
                } else if (value == 'reject') {
                  _showRejectDialog(tax);
                } else if (value == 'mark_paid') {
                  _showMarkPaidDialog(tax);
                } else if (value == 'delete') {
                  _showDeleteDialog(tax);
                }
              },
              itemBuilder: (context) {
                final items = <PopupMenuEntry<String>>[];
                // Afficher les options selon le statut normalisé
                if (tax.isPending) {
                  items.add(
                    const PopupMenuItem(
                      value: 'validate',
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
                if (tax.isValidated && !tax.isPaid) {
                  items.add(
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: ListTile(
                        leading: Icon(Icons.payment, color: Colors.blue),
                        title: Text('Marquer payé'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  );
                }
                items.add(
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete, color: Colors.red),
                      title: Text('Supprimer'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                );
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
                    color: _getStatusColor(tax.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    tax.statusText,
                    style: TextStyle(
                      color: _getStatusColor(tax.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency.format(tax.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showTaxDetails(tax),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTaxDetails(Tax tax) {
    Get.dialog(
      AlertDialog(
        title: Text(tax.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Montant: ${tax.amount.toStringAsFixed(2)} €'),
              Text('Date d\'échéance: ${_formatDate(tax.dueDateTime)}'),
              Text('Statut: ${tax.statusText}'),
              if (tax.description != null && tax.description!.isNotEmpty)
                Text('Description: ${tax.description}'),
              if (tax.rejectionReason != null &&
                  tax.rejectionReason!.isNotEmpty)
                Text('Raison du rejet: ${tax.rejectionReason}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
        ],
      ),
    );
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
