import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';

class PaymentForm extends StatelessWidget {
  const PaymentForm({super.key});

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un paiement'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          Obx(
            () => TextButton(
              onPressed:
                  controller.isCreating.value ? null : controller.createPayment,
              child:
                  controller.isCreating.value
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text(
                        'Créer',
                        style: TextStyle(color: Colors.white),
                      ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type de paiement
            _buildPaymentTypeSection(controller),
            const SizedBox(height: 20),

            // Informations client
            _buildClientSection(controller),
            const SizedBox(height: 20),

            // Détails du paiement
            _buildPaymentDetailsSection(controller),
            const SizedBox(height: 20),

            // Section planning (pour paiements mensuels)
            Obx(() {
              if (controller.paymentType.value == 'monthly') {
                return Column(
                  children: [
                    _buildScheduleSection(controller),
                    const SizedBox(height: 20),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),

            // Notes et références
            _buildNotesSection(controller),
            const SizedBox(height: 20),

            // Résumé
            _buildSummarySection(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentTypeSection(PaymentController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Type de paiement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Ponctuel'),
                      subtitle: const Text('Paiement unique'),
                      value: 'one_time',
                      groupValue: controller.paymentType.value,
                      onChanged:
                          (value) => controller.paymentType.value = value!,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Mensuel'),
                      subtitle: const Text('Paiements récurrents'),
                      value: 'monthly',
                      groupValue: controller.paymentType.value,
                      onChanged:
                          (value) => controller.paymentType.value = value!,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(PaymentController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Informations client',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () => _showClientSelectionDialog(controller),
                  icon: const Icon(Icons.search),
                  label: const Text('Sélectionner'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.clientNameController,
              decoration: const InputDecoration(
                labelText: 'Nom du client *',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => controller.selectedClientName.value = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.clientEmailController,
              decoration: const InputDecoration(
                labelText: 'Email du client *',
                border: OutlineInputBorder(),
              ),
              onChanged:
                  (value) => controller.selectedClientEmail.value = value,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.clientAddressController,
              decoration: const InputDecoration(
                labelText: 'Adresse du client *',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged:
                  (value) => controller.selectedClientAddress.value = value,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsSection(PaymentController controller) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de paiement'),
                      Obx(
                        () => TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: Get.context!,
                              initialDate: controller.paymentDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              controller.paymentDate.value = date;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${controller.paymentDate.value.day}/${controller.paymentDate.value.month}/${controller.paymentDate.value.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date d\'échéance'),
                      Obx(
                        () => TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: Get.context!,
                              initialDate:
                                  controller.dueDate.value ?? DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              controller.dueDate.value = date;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            controller.dueDate.value != null
                                ? '${controller.dueDate.value!.day}/${controller.dueDate.value!.month}/${controller.dueDate.value!.year}'
                                : 'Sélectionner',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged:
                        (value) =>
                            controller.amount.value =
                                double.tryParse(value) ?? 0.0,
                    decoration: const InputDecoration(
                      labelText: 'Montant *',
                      border: OutlineInputBorder(),
                      prefixText: 'fcfa ',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: controller.paymentMethod.value,
                    decoration: const InputDecoration(
                      labelText: 'Méthode de paiement',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'bank_transfer',
                        child: Text('Virement bancaire'),
                      ),
                      DropdownMenuItem(value: 'check', child: Text('Chèque')),
                      DropdownMenuItem(value: 'cash', child: Text('Espèces')),
                      DropdownMenuItem(
                        value: 'card',
                        child: Text('Carte bancaire'),
                      ),
                      DropdownMenuItem(
                        value: 'direct_debit',
                        child: Text('Prélèvement'),
                      ),
                    ],
                    onChanged:
                        (value) => controller.paymentMethod.value = value!,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleSection(PaymentController controller) {
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de début'),
                      Obx(
                        () => TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: Get.context!,
                              initialDate: controller.scheduleStartDate.value,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              controller.scheduleStartDate.value = date;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${controller.scheduleStartDate.value.day}/${controller.scheduleStartDate.value.month}/${controller.scheduleStartDate.value.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de fin'),
                      Obx(
                        () => TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: Get.context!,
                              initialDate: controller.scheduleEndDate.value,
                              firstDate: controller.scheduleStartDate.value,
                              lastDate: DateTime.now().add(
                                const Duration(days: 365 * 5),
                              ),
                            );
                            if (date != null) {
                              controller.scheduleEndDate.value = date;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${controller.scheduleEndDate.value.day}/${controller.scheduleEndDate.value.month}/${controller.scheduleEndDate.value.year}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      controller.frequency.value = int.tryParse(value) ?? 30;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Fréquence (jours)',
                      border: OutlineInputBorder(),
                      suffixText: 'jours',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      controller.totalInstallments.value =
                          int.tryParse(value) ?? 12;
                    },
                    decoration: const InputDecoration(
                      labelText: 'Nombre d\'échéances',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => Text(
                'Montant par échéance: ${controller.installmentAmount.value.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(PaymentController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes et références',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller.referenceController,
              decoration: const InputDecoration(
                labelText: 'Référence',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(PaymentController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildSummaryRow(
                    'Type',
                    controller.getPaymentTypeName(controller.paymentType.value),
                  ),
                  _buildSummaryRow(
                    'Montant',
                    '${controller.amount.value.toStringAsFixed(2)} €',
                  ),
                  _buildSummaryRow(
                    'Méthode',
                    controller.getPaymentMethodName(
                      controller.paymentMethod.value,
                    ),
                  ),
                  if (controller.paymentType.value == 'monthly') ...[
                    _buildSummaryRow(
                      'Échéances',
                      '${controller.totalInstallments.value}',
                    ),
                    _buildSummaryRow(
                      'Fréquence',
                      '${controller.frequency.value} jours',
                    ),
                    _buildSummaryRow(
                      'Montant par échéance',
                      '${controller.installmentAmount.value.toStringAsFixed(2)} fcfa',
                    ),
                  ],
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    '${controller.amount.value.toStringAsFixed(2)} fcfa',
                    isTotal: true,
                  ),
                ],
              ),
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
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showClientSelectionDialog(PaymentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Sélectionner un client'),
        content: const Text(
          'Fonctionnalité de sélection de client à implémenter',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
        ],
      ),
    );
  }
}
