import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';

class PaymentList extends StatelessWidget {
  const PaymentList({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des paiements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(controller),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/payments/new'),
          ),
        ],
      ),
      body: Column(
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

          // Liste des paiements
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.payments.isEmpty) {
                return const Center(
                  child: Text('Aucun paiement trouvé'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: controller.payments.length,
                itemBuilder: (context, index) {
                  final payment = controller.payments[index];
                  return _buildPaymentCard(controller, payment);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(PaymentController controller, PaymentModel payment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                      fontSize: 16,
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
                    color: controller
                        .getPaymentStatusColor(payment.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    controller.getPaymentStatusName(payment.status),
                    style: TextStyle(
                      color: controller.getPaymentStatusColor(payment.status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
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
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Colors.grey,
                ),
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

            // Actions selon le statut
            if (payment.status == 'draft' && controller.canSubmitPayments) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.submitPaymentToPatron(payment.id),
                      icon: const Icon(Icons.send, size: 16),
                      label: const Text('Soumettre'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Get.toNamed('/payments/edit', arguments: payment.id),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                    ),
                  ),
                ],
              ),
            ],

            if (payment.status == 'submitted' && controller.canApprovePayments) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showApprovalDialog(controller, payment.id),
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
                      onPressed: () => _showRejectionDialog(controller, payment.id),
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

            if (payment.status == 'approved') ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showPaymentDialog(controller, payment.id),
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
                        onPressed: () => _showScheduleDialog(controller, payment.id),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: const Text('Planning'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(PaymentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtrer les paiements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Filtre par statut
            DropdownButtonFormField<String>(
              value: controller.selectedStatus.value,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous')),
                DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                DropdownMenuItem(value: 'submitted', child: Text('Soumis')),
                DropdownMenuItem(value: 'approved', child: Text('Approuvé')),
                DropdownMenuItem(value: 'rejected', child: Text('Rejeté')),
                DropdownMenuItem(value: 'paid', child: Text('Payé')),
                DropdownMenuItem(value: 'overdue', child: Text('En retard')),
              ],
              onChanged: (value) => controller.selectedStatus.value = value ?? 'all',
            ),
            const SizedBox(height: 16),

            // Filtre par type
            DropdownButtonFormField<String>(
              value: controller.selectedType.value,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous')),
                DropdownMenuItem(value: 'one_time', child: Text('Ponctuel')),
                DropdownMenuItem(value: 'monthly', child: Text('Mensuel')),
              ],
              onChanged: (value) => controller.selectedType.value = value ?? 'all',
            ),
            const SizedBox(height: 16),

            // Filtre par date
            Row(
              children: [
                Expanded(
                  child: Obx(() => TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.startDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        controller.startDate.value = date;
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      controller.startDate.value != null
                          ? '${controller.startDate.value!.day}/${controller.startDate.value!.month}'
                          : 'Date début',
                    ),
                  )),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate: controller.endDate.value ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        controller.endDate.value = date;
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      controller.endDate.value != null
                          ? '${controller.endDate.value!.day}/${controller.endDate.value!.month}'
                          : 'Date fin',
                    ),
                  )),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.loadPayments();
              Get.back();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
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
                comments: commentsController.text.trim().isEmpty
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
                paymentReference: referenceController.text.trim().isEmpty
                    ? null
                    : referenceController.text.trim(),
                notes: notesController.text.trim().isEmpty
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

  void _showScheduleDialog(PaymentController controller, int paymentId) {
    Get.dialog(
      AlertDialog(
        title: const Text('Gestion du planning'),
        content: const Text('Fonctionnalité de gestion du planning à implémenter'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
