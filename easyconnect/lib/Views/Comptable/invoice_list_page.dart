import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../Controllers/auth_controller.dart';
import '../../Controllers/invoice_controller.dart';
import 'invoice_detail.dart';
import '../../Views/Components/skeleton_loaders.dart';

class InvoiceListPage extends StatefulWidget {
  const InvoiceListPage({super.key});

  @override
  State<InvoiceListPage> createState() => _InvoiceListPageState();
}

class _InvoiceListPageState extends State<InvoiceListPage>
    with SingleTickerProviderStateMixin {
  final InvoiceService _invoiceService = InvoiceService();
  final AuthController _authController = Get.find<AuthController>();

  late TabController _tabController;
  List<InvoiceModel> _invoices = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          // Forcer la mise à jour de l'interface quand l'onglet change
        });
      }
    });
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);

    try {
      final user = _authController.userAuth.value;

      if (user != null) {
        // Utiliser les vraies données de l'API
        final invoices = await _invoiceService.getAllInvoices();
        setState(() => _invoices = invoices);
      }
    } catch (e) {
      // Ne pas afficher d'erreur si des données sont disponibles
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (_invoices.isEmpty) {
          Get.snackbar('Erreur', 'Impossible de charger les factures: $e');
        }
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    List<InvoiceModel> filtered = _invoices;

    // Filtrer par statut selon l'onglet actif
    // Normaliser les statuts pour la comparaison (tolowercase)
    switch (_tabController.index) {
      case 0: // Tous
        break;
      case 1: // En attente
        filtered =
            _invoices.where((invoice) {
              final status = invoice.status.toLowerCase().trim();
              return status == 'en_attente' ||
                  status == 'pending' ||
                  status == 'draft';
            }).toList();
        break;
      case 2: // Validées
        filtered =
            _invoices.where((invoice) {
              final status = invoice.status.toLowerCase().trim();
              return status == 'valide' ||
                  status == 'validated' ||
                  status == 'valid';
            }).toList();
        break;
      case 3: // Rejetées
        filtered =
            _invoices.where((invoice) {
              final status = invoice.status.toLowerCase().trim();
              return status == 'rejete' ||
                  status == 'rejected' ||
                  status == 'cancelled';
            }).toList();
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
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
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Factures'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInvoices,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Toutes', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validées', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetées', icon: Icon(Icons.cancel)),
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
                hintText: 'Rechercher par numéro ou client...',
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

          // Liste des factures
          Expanded(
            child:
                _isLoading
                    ? const SkeletonSearchResults(itemCount: 6)
                    : _filteredInvoices.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune facture trouvée',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          if (_invoices.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Total: ${_invoices.length} facture(s)',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredInvoices.length,
                      itemBuilder: (context, index) {
                        final invoice = _filteredInvoices[index];
                        return _buildInvoiceCard(invoice);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/invoices/new'),
        tooltip: 'Nouvelle facture',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(invoice.status),
          child: Icon(_getStatusIcon(invoice.status), color: Colors.white),
        ),
        title: Text(
          invoice.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        isThreeLine: true,
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                'Client: ${invoice.clientName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                'Montant: ${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                'Date: ${_formatDate(invoice.invoiceDate)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (invoice.status == 'rejete' &&
                (invoice.notes != null && invoice.notes!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Raison: ${invoice.notes}',
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Bouton Détail
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                onPressed: () => _showInvoiceDetail(invoice),
                tooltip: 'Voir détails',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 4),
              // Bouton Modifier (seulement si en_attente)
              if (invoice.status == 'en_attente')
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.orange, size: 20),
                  onPressed: () => _editInvoice(invoice),
                  tooltip: 'Modifier',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              if (invoice.status == 'en_attente') const SizedBox(width: 4),
              // Bouton PDF
              IconButton(
                icon: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: () => _generatePDF(invoice),
                tooltip: 'Générer PDF',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              // Statut et montant dans une colonne compacte
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusLabel(invoice.status),
                      style: TextStyle(
                        color: _getStatusColor(invoice.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        onTap: () => _showInvoiceDetail(invoice),
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'valide':
        return 'Validée';
      case 'rejete':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showInvoiceDetail(InvoiceModel invoice) {
    Get.to(() => InvoiceDetail(invoice: invoice));
  }

  void _editInvoice(InvoiceModel invoice) {
    final controller = Get.find<InvoiceController>();
    controller.loadInvoiceForEdit(invoice.id);
    Get.toNamed('/invoices/edit', arguments: invoice.id);
  }

  void _showInvoiceDetails(InvoiceModel invoice) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Facture ${invoice.invoiceNumber}'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Client: ${invoice.clientName}'),
                  Text('Email: ${invoice.clientEmail}'),
                  Text('Adresse: ${invoice.clientAddress}'),
                  const SizedBox(height: 8),
                  Text(
                    'Montant HT: ${invoice.subtotal.toStringAsFixed(0)} ${invoice.currency}',
                  ),
                  Text(
                    'TVA (${invoice.taxRate}%): ${invoice.taxAmount.toStringAsFixed(0)} ${invoice.currency}',
                  ),
                  Text(
                    'Total TTC: ${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                  ),
                  const SizedBox(height: 8),
                  Text('Date facture: ${_formatDate(invoice.invoiceDate)}'),
                  Text('Date échéance: ${_formatDate(invoice.dueDate)}'),
                  if (invoice.notes != null) ...[
                    const SizedBox(height: 8),
                    Text('Notes: ${invoice.notes}'),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
              if (invoice.status == 'en_attente') ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _approveInvoice(invoice);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Valider'),
                ),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _rejectInvoice(invoice);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text('Rejeter'),
                ),
              ],
            ],
          ),
    );
  }

  void _approveInvoice(InvoiceModel invoice) async {
    try {
      await _invoiceService.approveInvoice(
        invoiceId: invoice.id,
        comments: 'Facture approuvée',
      );
      Get.snackbar('Succès', 'Facture approuvée');
      _loadInvoices();
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'approuver la facture');
    }
  }

  void _rejectInvoice(InvoiceModel invoice) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Rejeter la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Facture ${invoice.invoiceNumber}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        await _invoiceService.rejectInvoice(
          invoiceId: invoice.id,
          reason: reasonController.text.trim(),
        );
        Get.snackbar('Succès', 'Facture rejetée');
        _loadInvoices();
      } catch (e) {
        Get.snackbar('Erreur', 'Impossible de rejeter la facture');
      }
    }
  }

  void _generatePDF(InvoiceModel invoice) async {
    try {
      final controller = Get.find<InvoiceController>();
      await controller.generatePDF(invoice.id);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de générer le PDF');
    }
  }
}
