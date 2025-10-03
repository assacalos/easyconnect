import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';

class InvoiceDetail extends StatelessWidget {
  final InvoiceModel invoice;

  const InvoiceDetail({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    final InvoiceController controller = Get.put(InvoiceController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Facture #${invoice.invoiceNumber}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, controller),
            itemBuilder:
                (context) => [
                  if (invoice.status == 'draft' && controller.canSubmitInvoices)
                    const PopupMenuItem(
                      value: 'submit',
                      child: ListTile(
                        leading: Icon(Icons.send),
                        title: Text('Soumettre au patron'),
                      ),
                    ),
                  if (invoice.status == 'pending_approval' &&
                      controller.canApproveInvoices) ...[
                    const PopupMenuItem(
                      value: 'approve',
                      child: ListTile(
                        leading: Icon(Icons.check, color: Colors.green),
                        title: Text('Approuver'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'reject',
                      child: ListTile(
                        leading: Icon(Icons.close, color: Colors.red),
                        title: Text('Rejeter'),
                      ),
                    ),
                  ],
                  if (invoice.status == 'sent')
                    const PopupMenuItem(
                      value: 'send_email',
                      child: ListTile(
                        leading: Icon(Icons.email),
                        title: Text('Renvoyer par email'),
                      ),
                    ),
                  if (invoice.status == 'paid')
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: ListTile(
                        leading: Icon(Icons.payment),
                        title: Text('Marquer comme payée'),
                      ),
                    ),
                ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de la facture
            _buildInvoiceHeader(),
            const SizedBox(height: 20),

            // Informations client
            _buildClientInfo(),
            const SizedBox(height: 20),

            // Articles
            _buildItemsList(),
            const SizedBox(height: 20),

            // Résumé financier
            _buildFinancialSummary(),
            const SizedBox(height: 20),

            // Notes et conditions
            if (invoice.notes != null || invoice.terms != null)
              _buildNotesSection(),

            // Informations de paiement
            if (invoice.paymentInfo != null) _buildPaymentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Facture #${invoice.invoiceNumber}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Commercial: ${invoice.commercialName}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor()),
                  ),
                  child: Text(
                    _getStatusText(),
                    style: TextStyle(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date de facture',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Date d\'échéance',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      '${invoice.dueDate.day}/${invoice.dueDate.month}/${invoice.dueDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Informations client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              invoice.clientName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.clientEmail,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(invoice.clientAddress, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Articles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invoice.items.isEmpty)
              const Center(
                child: Text(
                  'Aucun article',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...invoice.items.map((item) => _buildItemRow(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(InvoiceItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (item.unit != null)
                  Text(
                    'Unité: ${item.unit}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${item.totalPrice.toStringAsFixed(2)} fcfa',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calculate, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Résumé financier',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(
              'Sous-total',
              '${invoice.subtotal.toStringAsFixed(2)} fcfa',
            ),
            _buildSummaryRow(
              'TVA (${invoice.taxRate.toStringAsFixed(1)}%)',
              '${invoice.taxAmount.toStringAsFixed(2)} fcfa',
            ),
            const Divider(),
            _buildSummaryRow(
              'Total',
              '${invoice.totalAmount.toStringAsFixed(2)} fcfa',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Notes et conditions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (invoice.notes != null) ...[
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(invoice.notes!),
              const SizedBox(height: 12),
            ],
            if (invoice.terms != null) ...[
              const Text(
                'Conditions de paiement:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(invoice.terms!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final payment = invoice.paymentInfo!;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.payment, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Informations de paiement',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPaymentRow('Méthode', _getPaymentMethodText(payment.method)),
            _buildPaymentRow(
              'Montant',
              '${payment.amount.toStringAsFixed(2)} fcfa',
            ),
            if (payment.reference != null)
              _buildPaymentRow('Référence', payment.reference!),
            if (payment.paymentDate != null)
              _buildPaymentRow(
                'Date de paiement',
                '${payment.paymentDate!.day}/${payment.paymentDate!.month}/${payment.paymentDate!.year}',
              ),
            if (payment.notes != null)
              _buildPaymentRow('Notes', payment.notes!),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _getStatusText() {
    switch (invoice.status) {
      case 'draft':
        return 'Brouillon';
      case 'sent':
        return 'Envoyée';
      case 'paid':
        return 'Payée';
      case 'overdue':
        return 'En retard';
      case 'cancelled':
        return 'Annulée';
      case 'pending_approval':
        return 'En attente d\'approbation';
      case 'approved':
        return 'Approuvée';
      case 'rejected':
        return 'Rejetée';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor() {
    switch (invoice.status) {
      case 'draft':
        return Colors.grey;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      case 'overdue':
        return Colors.red;
      case 'cancelled':
        return Colors.red;
      case 'pending_approval':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'bank_transfer':
        return 'Virement bancaire';
      case 'check':
        return 'Chèque';
      case 'cash':
        return 'Espèces';
      case 'card':
        return 'Carte bancaire';
      default:
        return method;
    }
  }

  void _handleMenuAction(String action, InvoiceController controller) {
    switch (action) {
      case 'submit':
        controller.submitInvoiceToPatron(invoice.id);
        break;
      case 'approve':
        _showApprovalDialog(controller);
        break;
      case 'reject':
        _showRejectionDialog(controller);
        break;
      case 'send_email':
        _showSendEmailDialog(controller);
        break;
      case 'mark_paid':
        _showMarkPaidDialog(controller);
        break;
    }
  }

  void _showApprovalDialog(InvoiceController controller) {
    final commentsController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir approuver cette facture ?'),
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
              controller.approveInvoice(
                invoice.id,
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

  void _showRejectionDialog(InvoiceController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la facture'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
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
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectInvoice(
                  invoice.id,
                  reasonController.text.trim(),
                );
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

  void _showSendEmailDialog(InvoiceController controller) {
    final emailController = TextEditingController(text: invoice.clientEmail);
    final messageController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Envoyer par email'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message (optionnel)',
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
              // Implémenter l'envoi d'email
              Get.snackbar('Succès', 'Email envoyé');
              Get.back();
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showMarkPaidDialog(InvoiceController controller) {
    // Implémenter le dialogue de marquage comme payée
    Get.snackbar('Info', 'Fonctionnalité à implémenter');
  }
}
