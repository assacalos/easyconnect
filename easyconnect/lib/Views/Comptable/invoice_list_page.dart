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
      elevation: 2,
      child: InkWell(
        onTap: () => _showInvoiceDetail(invoice),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec numéro et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      invoice.invoiceNumber,
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
                      color: _getStatusColor(invoice.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(invoice.status).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(invoice.status),
                      style: TextStyle(
                        color: _getStatusColor(invoice.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Client
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      invoice.clientName,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Date
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(invoice.invoiceDate),
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Montant
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // Raison du rejet si rejeté
              if (invoice.status == 'rejete' &&
                  (invoice.notes != null && invoice.notes!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${invoice.notes}',
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
                  if (invoice.status == 'en_attente')
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => _editInvoice(invoice),
                    ),
                  if (invoice.status == 'en_attente') const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => _showInvoiceDetail(invoice),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('PDF'),
                    onPressed: () => _generatePDF(invoice),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  void _generatePDF(InvoiceModel invoice) async {
    try {
      final controller = Get.find<InvoiceController>();
      await controller.generatePDF(invoice.id);
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de générer le PDF');
    }
  }
}
