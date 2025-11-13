import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Models/payment_model.dart';
import 'package:easyconnect/services/payment_service.dart';

class PaymentDetail extends StatelessWidget {
  final int paymentId;

  const PaymentDetail({super.key, required this.paymentId});

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du paiement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Builder(
            builder: (context) {
              // Cette partie sera gérée dans le body avec FutureBuilder
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<PaymentModel>(
        future: PaymentService.to.getPaymentById(paymentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          final payment = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(controller, payment),
                const SizedBox(height: 16),
                _buildClientCard(payment),
                const SizedBox(height: 16),
                _buildPaymentCard(controller, payment),
                const SizedBox(height: 16),
                if (payment.status == 'rejected' &&
                    payment.notes != null &&
                    payment.notes!.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motif du rejet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.report, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  payment.notes!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (payment.type == 'monthly' && payment.schedule != null) ...[
                  _buildScheduleCard(controller, payment),
                  const SizedBox(height: 16),
                ],
                _buildStatusCard(controller, payment),
                const SizedBox(height: 16),
                _buildActionsCard(controller, payment),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderCard(PaymentController controller, PaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        payment.paymentNumber,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Créé le ${payment.createdAt.day}/${payment.createdAt.month}/${payment.createdAt.year}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: controller
                        .getPaymentStatusColor(payment.status)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    controller.getPaymentStatusName(payment.status),
                    style: TextStyle(
                      color: controller.getPaymentStatusColor(payment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  controller.paymentType.value == 'one_time'
                      ? Icons.payment
                      : Icons.schedule,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  controller.getPaymentTypeName(payment.type),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '${payment.amount.toStringAsFixed(2)} ${payment.currency}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(PaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informations client',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Nom', payment.clientName),
            _buildInfoRow(Icons.email, 'Email', payment.clientEmail),
            _buildInfoRow(Icons.location_on, 'Adresse', payment.clientAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(PaymentController controller, PaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails du paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Date de paiement',
              '${payment.paymentDate.day}/${payment.paymentDate.month}/${payment.paymentDate.year}',
            ),
            if (payment.dueDate != null)
              _buildInfoRow(
                Icons.schedule,
                'Date d\'échéance',
                '${payment.dueDate!.day}/${payment.dueDate!.month}/${payment.dueDate!.year}',
              ),
            _buildInfoRow(
              Icons.credit_card,
              'Méthode de paiement',
              controller.getPaymentMethodName(payment.paymentMethod),
            ),
            if (payment.description != null)
              _buildInfoRow(
                Icons.description,
                'Description',
                payment.description!,
              ),
            if (payment.reference != null)
              _buildInfoRow(Icons.receipt, 'Référence', payment.reference!),
            if (payment.notes != null)
              _buildInfoRow(Icons.notes, 'Notes', payment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard(
    PaymentController controller,
    PaymentModel payment,
  ) {
    final schedule = payment.schedule!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Planning des paiements',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.schedule,
              'Statut du planning',
              schedule.status,
            ),
            _buildInfoRow(
              Icons.calendar_today,
              'Date de début',
              '${schedule.startDate.day}/${schedule.startDate.month}/${schedule.startDate.year}',
            ),
            _buildInfoRow(
              Icons.event,
              'Date de fin',
              '${schedule.endDate.day}/${schedule.endDate.month}/${schedule.endDate.year}',
            ),
            _buildInfoRow(
              Icons.repeat,
              'Fréquence',
              '${schedule.frequency} jours',
            ),
            _buildInfoRow(
              Icons.payment,
              'Échéances payées',
              '${schedule.paidInstallments}/${schedule.totalInstallments}',
            ),
            _buildInfoRow(
              Icons.euro,
              'Montant par échéance',
              '${schedule.installmentAmount.toStringAsFixed(2)} €',
            ),
            if (schedule.nextPaymentDate != null)
              _buildInfoRow(
                Icons.next_plan,
                'Prochain paiement',
                '${schedule.nextPaymentDate!.day}/${schedule.nextPaymentDate!.month}/${schedule.nextPaymentDate!.year}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(PaymentController controller, PaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique du statut',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatusItem('Créé', payment.createdAt, 'Brouillon'),
            if (payment.submittedAt != null)
              _buildStatusItem(
                'Soumis',
                payment.submittedAt!,
                'Soumis au patron',
              ),
            if (payment.approvedAt != null)
              _buildStatusItem(
                'Approuvé',
                payment.approvedAt!,
                'Approuvé par le patron',
              ),
            if (payment.paidAt != null)
              _buildStatusItem('Payé', payment.paidAt!, 'Paiement effectué'),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(PaymentController controller, PaymentModel payment) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (payment.status == 'draft' && controller.canSubmitPayments) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => controller.submitPaymentToPatron(payment.id),
                  icon: const Icon(Icons.send),
                  label: const Text('Soumettre au patron'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (payment.status == 'submitted' &&
                controller.canApprovePayments) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed:
                          () => _showApprovalDialog(controller, payment.id),
                      icon: const Icon(Icons.check),
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
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (payment.status == 'approved') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(controller, payment.id),
                  icon: const Icon(Icons.payment),
                  label: const Text('Marquer comme payé'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (payment.type == 'monthly') ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showScheduleDialog(controller, payment.id),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Gérer le planning'),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Bouton PDF
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.generatePDF(payment.id),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Générer PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Bouton Modifier (seulement si draft ou pending)
            if (payment.status == 'draft' || payment.status == 'pending')
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed:
                      () =>
                          Get.toNamed('/payments/edit', arguments: payment.id),
                  icon: const Icon(Icons.edit),
                  label: const Text('Modifier'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(value, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String action, DateTime date, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(status, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
}
