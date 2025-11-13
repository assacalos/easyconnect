import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';

class PaymentList extends StatefulWidget {
  const PaymentList({super.key});

  @override
  State<PaymentList> createState() => _PaymentListState();
}

class _PaymentListState extends State<PaymentList>
    with SingleTickerProviderStateMixin {
  final PaymentController controller = Get.find<PaymentController>();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        controller.loadPayments();
      }
    });
    controller.loadPayments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<PaymentModel> get _filteredPayments {
    List<PaymentModel> filtered = controller.payments;

    // Filtrer par statut selon l'onglet actif
    switch (_tabController.index) {
      case 0: // Tous
        break;
      case 1: // En attente
        filtered = filtered.where((p) => p.isPending).toList();
        break;
      case 2: // Validés
        filtered = filtered.where((p) => p.isApproved).toList();
        break;
      case 3: // Rejetés
        filtered = filtered.where((p) => p.isRejected).toList();
        break;
    }

    // Filtrer par recherche
    if (_searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (payment) =>
                    payment.paymentNumber.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    payment.clientName.toLowerCase().contains(
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
        title: const Text('Paiements'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadPayments,
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
      body: Obx(() {
        return Column(
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

            // Liste des paiements
            Expanded(
              child:
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPayments.isEmpty
                      ? const Center(child: Text('Aucun paiement trouvé'))
                      : ListView.builder(
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          return _buildPaymentCard(payment);
                        },
                      ),
            ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed('/payments/new'),
        tooltip: 'Nouveau paiement',
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(payment),
          child: Icon(_getStatusIcon(payment), color: Colors.white),
        ),
        title: Text(
          payment.paymentNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${payment.clientName}'),
            Text(
              'Montant: ${payment.amount.toStringAsFixed(0)} ${payment.currency}',
            ),
            Text('Date: ${_formatDate(payment.paymentDate)}'),
            if (payment.isRejected &&
                (payment.notes != null && payment.notes!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${payment.notes}',
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
            // Bouton Modifier
            if (payment.status == 'draft' || payment.status == 'pending')
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.orange),
                onPressed: () => _editPayment(payment),
                tooltip: 'Modifier',
              ),
            // Bouton Détail
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () => _showPaymentDetail(payment),
              tooltip: 'Voir détails',
            ),
            // Bouton PDF
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.red),
              onPressed: () => controller.generatePDF(payment.id),
              tooltip: 'Générer PDF',
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
                    color: _getStatusColor(payment).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusLabel(payment),
                    style: TextStyle(
                      color: _getStatusColor(payment),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showPaymentDetail(payment),
      ),
    );
  }

  Color _getStatusColor(PaymentModel payment) {
    if (payment.isPending) return Colors.orange;
    if (payment.isApproved) return Colors.green;
    if (payment.isRejected) return Colors.red;
    return Colors.grey;
  }

  IconData _getStatusIcon(PaymentModel payment) {
    if (payment.isPending) return Icons.pending;
    if (payment.isApproved) return Icons.check_circle;
    if (payment.isRejected) return Icons.cancel;
    return Icons.help;
  }

  String _getStatusLabel(PaymentModel payment) {
    if (payment.isPending) return 'En attente';
    if (payment.isApproved) return 'Validé';
    if (payment.isRejected) return 'Rejeté';
    return 'Inconnu';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPaymentDetail(PaymentModel payment) {
    Get.toNamed('/payments/detail', arguments: payment.id);
  }

  void _editPayment(PaymentModel payment) {
    Get.toNamed('/payments/edit', arguments: payment.id);
  }
}
