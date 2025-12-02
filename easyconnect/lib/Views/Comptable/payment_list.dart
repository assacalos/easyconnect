import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class PaymentList extends StatefulWidget {
  final int? clientId;

  const PaymentList({super.key, this.clientId});

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
                      ? const SkeletonSearchResults(itemCount: 6)
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
      floatingActionButton: RoleBasedWidget(
        allowedRoles: [Roles.ADMIN, Roles.COMPTABLE, Roles.PATRON],
        child: FloatingActionButton(
          onPressed: () => Get.toNamed('/payments/new'),
          tooltip: 'Nouveau paiement',
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _showPaymentDetail(payment),
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
                      payment.paymentNumber,
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
                      color: _getStatusColor(payment).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(payment).withOpacity(0.5),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(payment),
                      style: TextStyle(
                        color: _getStatusColor(payment),
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
                      payment.clientName,
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
                    _formatDate(payment.paymentDate),
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
                    '${payment.amount.toStringAsFixed(0)} ${payment.currency}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),

              // Raison du rejet si rejeté
              if (payment.isRejected &&
                  (payment.notes != null && payment.notes!.isNotEmpty)) ...[
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.report, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${payment.notes}',
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
                  if (payment.status == 'draft' || payment.status == 'pending')
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => _editPayment(payment),
                    ),
                  TextButton.icon(
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Détails'),
                    onPressed: () => _showPaymentDetail(payment),
                  ),
                  // Bouton PDF seulement pour les paiements validés
                  if (payment.isApproved) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('PDF'),
                      onPressed: () => controller.generatePDF(payment.id),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(PaymentModel payment) {
    if (payment.isPending) return Colors.orange;
    if (payment.isApproved) return Colors.green;
    if (payment.isRejected) return Colors.red;
    return Colors.grey;
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
