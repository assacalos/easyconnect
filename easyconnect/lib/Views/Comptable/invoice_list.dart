import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Views/Comptable/invoice_form.dart';
import 'package:easyconnect/Views/Comptable/invoice_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class InvoiceList extends StatelessWidget {
  const InvoiceList({super.key});

  @override
  Widget build(BuildContext context) {
    final InvoiceController controller = Get.put(InvoiceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des factures'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(controller),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            if (controller.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (controller.invoices.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucune facture trouvée',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Barre de recherche
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged:
                        (value) => controller.filterInvoices(search: value),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher une facture...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),

                // Liste des factures
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = controller.invoices[index];
                      return _buildInvoiceCard(invoice, controller);
                    },
                  ),
                ),
              ],
            );
          }),
          // Bouton d'ajout uniforme en bas à droite
          UniformAddButton(
            onPressed: () => Get.to(() => const InvoiceForm()),
            label: 'Nouvelle Facture',
            icon: Icons.receipt,
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(InvoiceModel invoice, InvoiceController controller) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => Get.to(() => InvoiceDetail(invoice: invoice)),
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
                      'Facture #${invoice.invoiceNumber}',
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
                          .getInvoiceStatusColor(invoice.status)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      controller.getInvoiceStatusText(invoice.status),
                      style: TextStyle(
                        color: controller.getInvoiceStatusColor(invoice.status),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
                      invoice.clientName,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
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
                    '${invoice.invoiceDate.day}/${invoice.invoiceDate.month}/${invoice.invoiceDate.year}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${invoice.totalAmount.toStringAsFixed(2)} fcfa',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

              // Actions selon le statut
              if (invoice.status == 'draft' &&
                  controller.canSubmitInvoices) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => controller.submitInvoiceToPatron(invoice.id),
                        icon: const Icon(Icons.send, size: 16),
                        label: const Text('Soumettre'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (invoice.status == 'pending_approval' &&
                  controller.canApproveInvoices) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _showApprovalDialog(controller, invoice.id),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approuver'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            () => _showRejectionDialog(controller, invoice.id),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(InvoiceController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Filtrer les factures'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: controller.selectedStatus.value,
              decoration: const InputDecoration(labelText: 'Statut'),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Tous')),
                DropdownMenuItem(value: 'draft', child: Text('Brouillon')),
                DropdownMenuItem(value: 'sent', child: Text('Envoyée')),
                DropdownMenuItem(value: 'paid', child: Text('Payée')),
                DropdownMenuItem(value: 'overdue', child: Text('En retard')),
                DropdownMenuItem(
                  value: 'pending_approval',
                  child: Text('En attente'),
                ),
              ],
              onChanged:
                  (value) => controller.selectedStatus.value = value ?? 'all',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: Get.context!,
                        initialDate:
                            controller.startDate.value ?? DateTime.now(),
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
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
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.filterInvoices(
                status: controller.selectedStatus.value,
                start: controller.startDate.value,
                end: controller.endDate.value,
              );
              Get.back();
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _showApprovalDialog(InvoiceController controller, int invoiceId) {
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
                invoiceId,
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

  void _showRejectionDialog(InvoiceController controller, int invoiceId) {
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
                  invoiceId,
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
}
