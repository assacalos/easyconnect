import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';

class PaymentList extends StatelessWidget {
  const PaymentList({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔄 PaymentList: build() appelé');
    final PaymentController controller = Get.find<PaymentController>();
    print('📦 PaymentList: PaymentController trouvé: true');
    print('📊 PaymentList: Nombre de paiements: ${controller.payments.length}');
    print('⏳ PaymentList: Chargement en cours: ${controller.isLoading.value}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des paiements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadPayments(),
          ),
          IconButton(
            icon: const Icon(Icons.wifi_tethering),
            onPressed: () => controller.testPaymentConnection(),
          ),
        ],
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            // Barre de recherche
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: (value) {
                  controller.searchQuery.value = value;
                  controller.loadPayments();
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un paiement...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            // Statistiques rapides
            _buildQuickStats(controller),

            // Onglets
            Container(
              color: Colors.deepPurple,
              child: const TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorColor: Colors.white,
                tabs: [
                  Tab(text: 'En attente'),
                  Tab(text: 'Validé'),
                  Tab(text: 'Rejeté'),
                ],
              ),
            ),

            // Contenu des onglets
            Expanded(
              child: TabBarView(
                children: [
                  _buildPaymentList(controller, 'pending'),
                  _buildPaymentList(controller, 'approved'),
                  _buildPaymentList(controller, 'rejected'),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/payments/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau Paiement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildQuickStats(PaymentController controller) {
    return Obx(() {
      final pendingCount = controller.getPendingPayments().length;
      final approvedCount = controller.getApprovedPayments().length;
      final rejectedCount = controller.getRejectedPayments().length;

      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'En attente',
                pendingCount.toString(),
                Colors.orange,
                Icons.pending,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Validé',
                approvedCount.toString(),
                Colors.green,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Rejeté',
                rejectedCount.toString(),
                Colors.red,
                Icons.cancel,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentList(PaymentController controller, String status) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      List<PaymentModel> filteredPayments;
      switch (status) {
        case 'pending':
          filteredPayments = controller.getPendingPayments();
          break;
        case 'approved':
          filteredPayments = controller.getApprovedPayments();
          break;
        case 'rejected':
          filteredPayments = controller.getRejectedPayments();
          break;
        default:
          filteredPayments = controller.payments;
      }

      if (filteredPayments.isEmpty) {
        String message;
        switch (status) {
          case 'pending':
            message = 'Aucun paiement en attente';
            break;
          case 'approved':
            message = 'Aucun paiement validé';
            break;
          case 'rejected':
            message = 'Aucun paiement rejeté';
            break;
          default:
            message = 'Aucun paiement trouvé';
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filteredPayments.length,
        itemBuilder: (context, index) {
          final payment = filteredPayments[index];
          return _buildPaymentCard(controller, payment);
        },
      );
    });
  }

  Widget _buildPaymentCard(PaymentController controller, PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec numéro et statut d'approbation
            Row(
              children: [
                Expanded(
                  child: Text(
                    payment.paymentNumber,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildApprovalStatusChip(payment),
              ],
            ),
            const SizedBox(height: 8),

            // Informations client
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    payment.clientName,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Type et méthode de paiement
            Row(
              children: [
                const Icon(Icons.payment, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(controller.getPaymentTypeName(payment.type)),
                const SizedBox(width: 16),
                const Icon(Icons.credit_card, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(controller.getPaymentMethodName(payment.paymentMethod)),
              ],
            ),
            const SizedBox(height: 4),

            // Date et montant
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
                ),
                const Spacer(),
                Text(
                  '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),

            // Actions selon le statut d'approbation
            if (payment.isPending && controller.canApprovePayments) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _showApprovalDialog(controller, payment.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _showRejectionDialog(controller, payment.id),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Bouton PDF pour tous les paiements
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => controller.generatePDF(payment.id),
                    icon: const Icon(Icons.picture_as_pdf, size: 16),
                    label: const Text('Générer PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            if (payment.isApproved) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _showPaymentDialog(controller, payment.id),
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Marquer payé'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (payment.type == 'monthly') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                            () => _showScheduleDialog(controller, payment.id),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: const Text('Planning'),
                      ),
                    ),
                  ],
                ],
              ),
            ],

            if (payment.isRejected) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          () => _showReactivationDialog(controller, payment.id),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Réactiver'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApprovalStatusChip(PaymentModel payment) {
    Color color;
    switch (payment.approvalStatusColor) {
      case 'orange':
        color = Colors.orange;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        payment.approvalStatusText,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

void _showApprovalDialog(PaymentController controller, int paymentId) {
  final commentsController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: const Text('Approuver le paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Êtes-vous sûr de vouloir approuver ce paiement ?'),
          const SizedBox(height: 16),
          TextField(
            controller: commentsController,
            decoration: const InputDecoration(
              labelText: 'Commentaires (optionnel)',
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
            controller.approvePayment(
              paymentId,
              comments:
                  commentsController.text.trim().isEmpty
                      ? null
                      : commentsController.text.trim(),
            );
            Get.back();
          },
          child: const Text('Approuver'),
        ),
      ],
    ),
  );
}

void _showRejectionDialog(PaymentController controller, int paymentId) {
  final reasonController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: const Text('Rejeter le paiement'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Êtes-vous sûr de vouloir rejeter ce paiement ?'),
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
              controller.rejectPayment(
                paymentId,
                reason: reasonController.text.trim(),
              );
              Get.back();
            } else {
              Get.snackbar('Erreur', 'Veuillez saisir une raison');
            }
          },
          child: const Text('Rejeter'),
        ),
      ],
    ),
  );
}

void _showPaymentDialog(PaymentController controller, int paymentId) {
  final referenceController = TextEditingController();
  final notesController = TextEditingController();

  Get.dialog(
    AlertDialog(
      title: const Text('Marquer comme payé'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: referenceController,
            decoration: const InputDecoration(
              labelText: 'Référence de paiement',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optionnel)',
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
            controller.markAsPaid(
              paymentId,
              paymentReference:
                  referenceController.text.trim().isEmpty
                      ? null
                      : referenceController.text.trim(),
              notes:
                  notesController.text.trim().isEmpty
                      ? null
                      : notesController.text.trim(),
            );
            Get.back();
          },
          child: const Text('Confirmer'),
        ),
      ],
    ),
  );
}

void _showReactivationDialog(PaymentController controller, int paymentId) {
  Get.dialog(
    AlertDialog(
      title: const Text('Réactiver le paiement'),
      content: const Text(
        'Êtes-vous sûr de vouloir réactiver ce paiement ? Il sera remis en attente d\'approbation.',
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: () {
            controller.reactivatePayment(paymentId);
            Get.back();
          },
          child: const Text('Réactiver'),
        ),
      ],
    ),
  );
}

void _showScheduleDialog(PaymentController controller, int paymentId) {
  Get.dialog(
    AlertDialog(
      title: const Text('Gestion du planning'),
      content: const Text(
        'Fonctionnalité de gestion du planning à implémenter',
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
      ],
    ),
  );
}
