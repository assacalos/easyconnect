import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/invoice_model.dart';
import '../../services/invoice_service.dart';
import '../../Controllers/auth_controller.dart';

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
    _loadInvoices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices() async {
    print('🔄 _loadInvoices - Début du chargement');
    setState(() => _isLoading = true);

    try {
      final user = _authController.userAuth.value;
      print('👤 Utilisateur: ${user?.id}, Role: ${user?.role}');

      if (user != null) {
        print('📞 Appel du service getAllInvoices (comptable)...');
        // Utiliser directement les données mockées pour tester
        final invoices = _invoiceService.getMockInvoices();
        print('✅ Factures reçues: ${invoices.length}');
        setState(() => _invoices = invoices);
        print('📋 Factures dans la liste: ${_invoices.length}');
      } else {
        print('❌ Utilisateur null');
      }
    } catch (e) {
      print('❌ Erreur dans _loadInvoices: $e');
      Get.snackbar('Erreur', 'Impossible de charger les factures');
    } finally {
      setState(() => _isLoading = false);
      print('🏁 _loadInvoices - Fin du chargement');
    }
  }

  List<InvoiceModel> get _filteredInvoices {
    print('🔍 _filteredInvoices - Début du filtrage');
    print('📊 Onglet actif: ${_tabController.index}');
    print('📋 Factures totales: ${_invoices.length}');

    List<InvoiceModel> filtered = _invoices;

    // Filtrer par statut selon l'onglet actif
    switch (_tabController.index) {
      case 0: // Tous
        print('📝 Onglet: Toutes les factures');
        break;
      case 1: // En attente
        print('📝 Onglet: En attente');
        filtered =
            _invoices
                .where((invoice) => invoice.status == 'en_attente')
                .toList();
        print('⏳ Factures en attente: ${filtered.length}');
        break;
      case 2: // Validées
        print('📝 Onglet: Validées');
        filtered =
            _invoices.where((invoice) => invoice.status == 'valide').toList();
        print('✅ Factures validées: ${filtered.length}');
        break;
      case 3: // Rejetées
        print('📝 Onglet: Rejetées');
        filtered =
            _invoices.where((invoice) => invoice.status == 'rejete').toList();
        print('❌ Factures rejetées: ${filtered.length}');
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      print('🔍 Recherche: "$_searchQuery"');
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
      print('🔍 Résultats de recherche: ${filtered.length}');
    }

    print('📊 Factures filtrées finales: ${filtered.length}');
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
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredInvoices.isEmpty
                    ? const Center(child: Text('Aucune facture trouvée'))
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${invoice.clientName}'),
            Text(
              'Montant: ${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
            ),
            Text('Date: ${_formatDate(invoice.invoiceDate)}'),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getStatusLabel(invoice.status),
                style: TextStyle(
                  color: _getStatusColor(invoice.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${invoice.totalAmount.toStringAsFixed(0)} ${invoice.currency}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
        onTap: () => _showInvoiceDetails(invoice),
      ),
    );
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

  IconData _getStatusIcon(String status) {
    switch (status) {
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

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Validée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
}
