import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/payment_service.dart';

class PaymentForm extends StatefulWidget {
  final int? paymentId;

  const PaymentForm({super.key, this.paymentId});

  @override
  State<PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends State<PaymentForm> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.paymentId != null) {
      _loadPaymentForEdit();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadPaymentForEdit() async {
    try {
      final payment = await PaymentService.to.getPaymentById(widget.paymentId!);
      final controller = Get.find<PaymentController>();

      // Remplir les champs avec les données du paiement
      controller.selectedClientId.value = payment.clientId;
      controller.selectedClientName.value = payment.clientName;
      controller.selectedClientEmail.value = payment.clientEmail;
      controller.selectedClientAddress.value = payment.clientAddress;
      controller.paymentType.value = payment.type;
      controller.paymentDate.value = payment.paymentDate;
      controller.dueDate.value = payment.dueDate;
      controller.amount.value = payment.amount;
      controller.paymentMethod.value = payment.paymentMethod;
      controller.descriptionController.text = payment.description ?? '';
      controller.notesController.text = payment.notes ?? '';
      controller.referenceController.text = payment.reference ?? '';

      if (payment.schedule != null) {
        controller.scheduleStartDate.value = payment.schedule!.startDate;
        controller.scheduleEndDate.value = payment.schedule!.endDate;
        controller.frequency.value = payment.schedule!.frequency;
        controller.totalInstallments.value =
            payment.schedule!.totalInstallments;
        controller.installmentAmount.value =
            payment.schedule!.installmentAmount;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger le paiement: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final PaymentController controller = Get.put(PaymentController());

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Modifier un paiement'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.paymentId != null
              ? 'Modifier un paiement'
              : 'Créer un paiement',
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
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
            const SizedBox(height: 20),

            // Bouton d'enregistrement
            _buildSaveButton(controller),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(PaymentController controller) {
    return Obx(
      () => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
                controller.isCreating.value ? null : controller.createPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child:
                controller.isCreating.value
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Créer le paiement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
          ),
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
                ElevatedButton.icon(
                  onPressed: () => _showClientSelectionDialog(controller),
                  icon: const Icon(Icons.person_search),
                  label: const Text('Sélectionner un client'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final hasSelectedClient = controller.selectedClientId.value > 0;
              return Column(
                children: [
                  if (hasSelectedClient)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Client sélectionné: ${controller.selectedClientName.value}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              controller.selectedClientId.value = 0;
                              controller.clientNameController.clear();
                              controller.clientEmailController.clear();
                              controller.clientAddressController.clear();
                              controller.selectedClientName.value = '';
                              controller.selectedClientEmail.value = '';
                              controller.selectedClientAddress.value = '';
                            },
                            child: const Text('Réinitialiser'),
                          ),
                        ],
                      ),
                    ),
                  if (hasSelectedClient) const SizedBox(height: 16),
                  TextField(
                    controller: controller.clientNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom du client *',
                      border: const OutlineInputBorder(),
                      enabled: !hasSelectedClient,
                      filled: hasSelectedClient,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged:
                        (value) => controller.selectedClientName.value = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.clientEmailController,
                    decoration: InputDecoration(
                      labelText: 'Email du client *',
                      border: const OutlineInputBorder(),
                      enabled: !hasSelectedClient,
                      filled: hasSelectedClient,
                      fillColor: Colors.grey[200],
                    ),
                    onChanged:
                        (value) => controller.selectedClientEmail.value = value,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller.clientAddressController,
                    decoration: InputDecoration(
                      labelText: 'Adresse du client *',
                      border: const OutlineInputBorder(),
                      enabled: !hasSelectedClient,
                      filled: hasSelectedClient,
                      fillColor: Colors.grey[200],
                    ),
                    maxLines: 2,
                    onChanged:
                        (value) =>
                            controller.selectedClientAddress.value = value,
                  ),
                ],
              );
            }),
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
    showDialog(
      context: Get.context!,
      builder:
          (context) => ClientSelectionDialog(
            onClientSelected: (Client client) {
              // Construire le nom complet
              final displayName =
                  '${client.nom ?? ''} ${client.prenom ?? ''}'.trim();
              final clientName =
                  displayName.isEmpty
                      ? (client.nomEntreprise ?? 'Client #${client.id}')
                      : displayName;

              // Construire l'adresse complète
              final addressParts = <String>[];
              if (client.adresse != null && client.adresse!.isNotEmpty) {
                addressParts.add(client.adresse!);
              }
              final clientAddress =
                  addressParts.isEmpty
                      ? 'Non spécifiée'
                      : addressParts.join(', ');

              // Appeler la méthode du contrôleur pour définir le client sélectionné
              controller.selectClient(
                clientId: client.id ?? 0,
                clientName: clientName,
                clientEmail: client.email ?? '',
                clientAddress: clientAddress,
              );

              Get.snackbar(
                'Client sélectionné',
                'Les informations du client ont été remplies automatiquement',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: Colors.green,
                colorText: Colors.white,
                duration: const Duration(seconds: 2),
              );
            },
          ),
    );
  }
}
