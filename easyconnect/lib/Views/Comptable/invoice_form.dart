import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Models/invoice_model.dart';
import 'package:easyconnect/Views/Components/client_selection_dialog.dart';

class InvoiceForm extends StatelessWidget {
  const InvoiceForm({super.key});

  @override
  Widget build(BuildContext context) {
    final InvoiceController controller = Get.put(InvoiceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une facture'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Informations client
            _buildClientSection(controller),
            const SizedBox(height: 20),

            // Articles
            _buildItemsSection(controller),
            const SizedBox(height: 20),

            // Paramètres de facturation
            _buildBillingSection(controller),
            const SizedBox(height: 20),

            // Notes et conditions
            _buildNotesSection(controller),
            const SizedBox(height: 20),

            // Résumé
            _buildSummarySection(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildClientSection(InvoiceController controller) {
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
                Expanded(
                  child: Row(
                    children: [
                      const Text(
                        'Informations client',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green),
                          ),
                          child: const Text(
                            'Validés uniquement',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _showClientSelectionDialog(controller),
                  icon: const Icon(Icons.search, size: 16),
                  label: const Text('Sélectionner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final selectedClient = controller.selectedClient.value;
              if (selectedClient != null) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedClient.nomEntreprise?.isNotEmpty == true
                          ? selectedClient.nomEntreprise!
                          : '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                              .trim()
                              .isNotEmpty
                          ? '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                              .trim()
                          : 'Client #${selectedClient.id}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (selectedClient.nomEntreprise?.isNotEmpty == true &&
                        '${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Contact: ${selectedClient.nom ?? ''} ${selectedClient.prenom ?? ''}'
                            .trim(),
                      ),
                      const SizedBox(height: 4),
                    ] else
                      const SizedBox(height: 8),
                    if (selectedClient.email != null) ...[
                      Text('Email: ${selectedClient.email}'),
                      const SizedBox(height: 4),
                    ],
                    if (selectedClient.contact != null) ...[
                      Text('Contact: ${selectedClient.contact}'),
                      const SizedBox(height: 4),
                    ],
                    if (selectedClient.adresse != null) ...[
                      Text('Adresse: ${selectedClient.adresse}'),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      'Statut: ${selectedClient.statusText}',
                      style: TextStyle(
                        color: selectedClient.statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: controller.clearSelectedClient,
                      child: const Text('Changer de client'),
                    ),
                  ],
                );
              }
              return const Text(
                'Aucun client sélectionné',
                style: TextStyle(color: Colors.grey),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection(InvoiceController controller) {
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
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _showAddItemDialog(controller),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              if (controller.invoiceItems.isEmpty) {
                return const Center(
                  child: Text(
                    'Aucun article ajouté',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children:
                    controller.invoiceItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return _buildItemCard(controller, index, item);
                    }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    InvoiceController controller,
    int index,
    InvoiceItem item,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                  Text(
                    '${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
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
            IconButton(
              onPressed: () => controller.removeInvoiceItem(index),
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingSection(InvoiceController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Paramètres de facturation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Date de facture'),
                      Obx(
                        () => TextButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: Get.context!,
                              initialDate: controller.invoiceDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                            );
                            if (date != null) {
                              controller.invoiceDate.value = date;
                            }
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(
                            '${controller.invoiceDate.value.day}/${controller.invoiceDate.value.month}/${controller.invoiceDate.value.year}',
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
                              initialDate: controller.dueDate.value,
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
                            '${controller.dueDate.value.day}/${controller.dueDate.value.month}/${controller.dueDate.value.year}',
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
                const Text('Taux de TVA :'),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(
                    () => Slider(
                      value: controller.taxRate.value,
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${controller.taxRate.value.toInt()}%',
                      onChanged: (value) => controller.taxRate.value = value,
                    ),
                  ),
                ),
                Obx(() => Text('${controller.taxRate.value.toInt()}%')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(InvoiceController controller) {
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
            const SizedBox(height: 16),
            TextField(
              controller: controller.notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.termsController,
              decoration: const InputDecoration(
                labelText: 'Conditions de paiement',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(InvoiceController controller) {
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
                  'Résumé',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(
              () => Column(
                children: [
                  _buildSummaryRow(
                    'Sous-total',
                    '${controller.subtotal.toStringAsFixed(2)} fcfa',
                  ),
                  _buildSummaryRow(
                    'TVA (${controller.taxRate.value.toInt()}%)',
                    '${controller.taxAmount.toStringAsFixed(2)} fcfa',
                  ),
                  const Divider(),
                  _buildSummaryRow(
                    'Total',
                    '${controller.totalAmount.toStringAsFixed(2)} fcfa',
                    isTotal: true,
                  ),
                ],
              ),
            ),

            // Bouton Enregistrer
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed:
                      controller.isCreating.value
                          ? null
                          : () async {
                            final success = await controller.createInvoice();
                            if (success) {
                              await Future.delayed(
                                const Duration(milliseconds: 500),
                              );
                              Get.offNamed('/invoices');
                            }
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
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
                            'Enregistrer la facture',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ),
            ),
            const SizedBox(height: 16),
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

  void _showClientSelectionDialog(InvoiceController controller) {
    // Charger les clients validés si pas encore fait
    if (controller.availableClients.isEmpty) {
      controller.loadValidatedClients();
    }

    showDialog(
      context: Get.context!,
      builder:
          (context) => ClientSelectionDialog(
            onClientSelected: (client) {
              controller.selectClientForInvoice(client);
              // Ne pas appeler Get.back() ici car le dialog le fait déjà
            },
          ),
    );
  }

  void _showAddItemDialog(InvoiceController controller) {
    final descriptionController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final unitPriceController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Ajouter un article'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantité',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: unitPriceController,
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (fcfa)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (descriptionController.text.isNotEmpty &&
                  quantityController.text.isNotEmpty &&
                  unitPriceController.text.isNotEmpty) {
                controller.addInvoiceItem(
                  description: descriptionController.text,
                  quantity: int.tryParse(quantityController.text) ?? 1,
                  unitPrice: double.tryParse(unitPriceController.text) ?? 0.0,
                );
                Get.back();
              } else {
                Get.snackbar(
                  'Erreur',
                  'Veuillez remplir tous les champs obligatoires',
                );
              }
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}
