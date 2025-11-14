import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:intl/intl.dart';

class FactureValidationPage extends StatefulWidget {
  const FactureValidationPage({super.key});

  @override
  State<FactureValidationPage> createState() => _FactureValidationPageState();
}

class _FactureValidationPageState extends State<FactureValidationPage>
    with SingleTickerProviderStateMixin {
  late final InvoiceController controller;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Vérifier et initialiser le contrôleur
    if (!Get.isRegistered<InvoiceController>()) {
      Get.put(InvoiceController(), permanent: true);
    }
    controller = Get.find<InvoiceController>();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadInvoices();
    }
  }

  Future<void> _loadInvoices() async {
    print(
      '🔵 [FACTURE_VALIDATION] _loadInvoices() appelé - Onglet: ${_tabController.index}',
    );

    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        print('🔵 [FACTURE_VALIDATION] Onglet "Tous" sélectionné');
        break;
      case 1: // En attente - inclure tous les statuts en attente
        // Ne pas filtrer par status ici, on chargera tout et filtrera côté client
        status = null;
        print(
          '🔵 [FACTURE_VALIDATION] Onglet "En attente" sélectionné - Chargement de toutes les factures',
        );
        break;
      case 2: // Validés
        status = 'valide';
        print(
          '🔵 [FACTURE_VALIDATION] Onglet "Validés" sélectionné - Filtre: $status',
        );
        break;
      case 3: // Rejetés
        status = 'rejete';
        print(
          '🔵 [FACTURE_VALIDATION] Onglet "Rejetés" sélectionné - Filtre: $status',
        );
        break;
    }

    print(
      '🔵 [FACTURE_VALIDATION] Avant filterInvoices - Status: ${status ?? "all"}',
    );
    controller.filterInvoices(status: status ?? 'all');

    // Si on est sur l'onglet "En attente", recharger toutes les factures
    // et filtrer côté client pour inclure tous les statuts en attente
    if (_tabController.index == 1) {
      print(
        '🔵 [FACTURE_VALIDATION] Rechargement de toutes les factures pour l\'onglet "En attente"',
      );
      await controller.loadInvoices();
    }

    print(
      '🔵 [FACTURE_VALIDATION] Après chargement - Nombre de factures dans controller: ${controller.invoices.length}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Factures'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadInvoices();
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
                hintText: 'Rechercher par numéro, client...',
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
                      : _buildInvoiceList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceList() {
    // Utiliser Obx pour rendre réactif l'accès à controller.invoices
    return Obx(() {
      print(
        '🟢 [FACTURE_VALIDATION] _buildInvoiceList() - Onglet: ${_tabController.index}',
      );
      print(
        '🟢 [FACTURE_VALIDATION] Nombre total de factures dans controller: ${controller.invoices.length}',
      );
      print('🟢 [FACTURE_VALIDATION] isLoading: ${controller.isLoading.value}');

      // Afficher tous les statuts pour debug
      if (controller.invoices.isNotEmpty) {
        final allStatuses =
            controller.invoices.map((inv) => inv.status).toSet();
        print('🟢 [FACTURE_VALIDATION] Statuts trouvés: $allStatuses');
        for (var invoice in controller.invoices) {
          print(
            '🟢 [FACTURE_VALIDATION] Facture: ${invoice.invoiceNumber} - Status: ${invoice.status}',
          );
        }
      } else {
        print(
          '🟢 [FACTURE_VALIDATION] ⚠️ Aucune facture dans controller.invoices',
        );
      }

      // Filtrer selon l'onglet actif et la recherche
      List<InvoiceModel> filteredInvoices = controller.invoices;
      print(
        '🟢 [FACTURE_VALIDATION] Avant filtrage: ${filteredInvoices.length} factures',
      );

      // Filtrer par statut selon l'onglet actif
      if (_tabController.index == 1) {
        // Onglet "En attente" - inclure tous les statuts en attente
        final statusLower = (String status) => status.toLowerCase().trim();
        final beforeCount = filteredInvoices.length;
        filteredInvoices =
            filteredInvoices.where((invoice) {
              final status = statusLower(invoice.status);
              final isPending =
                  status == 'draft' ||
                  status == 'en_attente' ||
                  status == 'pending' ||
                  status == 'en attente';
              if (isPending) {
                print(
                  '🟢 [FACTURE_VALIDATION] ✅ Facture en attente trouvée: ${invoice.invoiceNumber} - Status: ${invoice.status}',
                );
              }
              return isPending;
            }).toList();
        print(
          '🟢 [FACTURE_VALIDATION] Après filtrage "En attente": ${filteredInvoices.length} sur $beforeCount',
        );
      } else if (_tabController.index == 2) {
        // Onglet "Validés"
        final beforeCount = filteredInvoices.length;
        filteredInvoices =
            filteredInvoices.where((invoice) {
              final status = invoice.status.toLowerCase().trim();
              return status == 'valide' ||
                  status == 'validated' ||
                  status == 'approved';
            }).toList();
        print(
          '🟢 [FACTURE_VALIDATION] Après filtrage "Validés": ${filteredInvoices.length} sur $beforeCount',
        );
      } else if (_tabController.index == 3) {
        // Onglet "Rejetés"
        final beforeCount = filteredInvoices.length;
        filteredInvoices =
            filteredInvoices.where((invoice) {
              final status = invoice.status.toLowerCase().trim();
              return status == 'rejete' || status == 'rejected';
            }).toList();
        print(
          '🟢 [FACTURE_VALIDATION] Après filtrage "Rejetés": ${filteredInvoices.length} sur $beforeCount',
        );
      }
      // Onglet 0 (Tous) - pas de filtre supplémentaire

      // Filtrer selon la recherche
      if (_searchQuery.isNotEmpty) {
        final beforeCount = filteredInvoices.length;
        filteredInvoices =
            filteredInvoices
                .where(
                  (invoice) =>
                      invoice.invoiceNumber.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      invoice.clientName.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();
        print(
          '🟢 [FACTURE_VALIDATION] Après filtrage recherche: ${filteredInvoices.length} sur $beforeCount',
        );
      }

      print(
        '🟢 [FACTURE_VALIDATION] ✅ Factures finales à afficher: ${filteredInvoices.length}',
      );

      if (filteredInvoices.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isEmpty
                    ? 'Aucune facture trouvée'
                    : 'Aucune facture correspondant à "$_searchQuery"',
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
        itemCount: filteredInvoices.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final invoice = filteredInvoices[index];
          return _buildInvoiceCard(context, invoice);
        },
      );
    });
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );
    final statusColor = _getStatusColor(invoice.status);
    final statusIcon = _getStatusIcon(invoice.status);
    final statusText = _getStatusText(invoice.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Client: ${invoice.clientName}'),
            Text('Date: ${formatDate.format(invoice.invoiceDate)}'),
            Text('Montant: ${formatCurrency.format(invoice.totalAmount)}'),
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
                      Text('Numéro: ${invoice.invoiceNumber}'),
                      Text('Client: ${invoice.clientName}'),
                      Text('Email: ${invoice.clientEmail}'),
                      Text('Adresse: ${invoice.clientAddress}'),
                      Text('Commercial: ${invoice.commercialName}'),
                      Text(
                        'Date facture: ${formatDate.format(invoice.invoiceDate)}',
                      ),
                      Text(
                        'Date échéance: ${formatDate.format(invoice.dueDate)}',
                      ),
                      if (invoice.notes != null)
                        Text('Notes: ${invoice.notes}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Détails des articles
                const Text(
                  'Détails des articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...invoice.items.map((item) => _buildItemDetails(item)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total:'),
                          Text(formatCurrency.format(invoice.subtotal)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TVA (${invoice.taxRate}%):'),
                          Text(formatCurrency.format(invoice.taxAmount)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formatCurrency.format(invoice.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(invoice, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails(InvoiceItem item) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Expanded(child: Text('${item.quantity}')),
          Expanded(child: Text(formatCurrency.format(item.unitPrice))),
          Expanded(
            child: Text(
              formatCurrency.format(item.quantity * item.unitPrice),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(InvoiceModel invoice, Color statusColor) {
    // Vérifier si la facture est en attente (gérer toutes les variantes)
    final statusLower = invoice.status.toLowerCase().trim();
    final isPending =
        statusLower == 'en_attente' ||
        statusLower == 'pending' ||
        statusLower == 'draft' ||
        statusLower == 'en attente';
    final isValidated =
        statusLower == 'valide' ||
        statusLower == 'validated' ||
        statusLower == 'approved';
    final isRejected = statusLower == 'rejete' || statusLower == 'rejected';

    if (isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(invoice),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(invoice),
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
    }

    if (isValidated) {
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
              'Facture validée',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (isRejected) {
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
              'Facture rejetée',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

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
            'Statut: ${invoice.status}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'valide':
        return Colors.green;
      case 'rejete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.pending;
      case 'valide':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validé';
      case 'rejete':
        return 'Rejeté';
      default:
        return status;
    }
  }

  void _showApproveConfirmation(InvoiceModel invoice) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider cette facture ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveInvoice(invoice.id);
        _loadInvoices();
      },
    );
  }

  void _showRejectDialog(InvoiceModel invoice) {
    final reasonController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter la facture',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: reasonController,
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
        if (reasonController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectInvoice(invoice.id, reasonController.text);
        _loadInvoices();
      },
    );
  }
}
