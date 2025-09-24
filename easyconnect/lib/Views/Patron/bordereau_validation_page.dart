import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:intl/intl.dart';

class BordereauValidationPage extends GetView<BordereauController> {
  const BordereauValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Charger les bordereaux en attente
    controller.loadBordereaux(status: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des bordereaux'),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _buildBordereauList(),
      ),
    );
  }

  Widget _buildBordereauList() {
    if (controller.bordereaux.isEmpty) {
      return const Center(
        child: Text('Aucun bordereau en attente de validation'),
      );
    }

    return ListView.builder(
      itemCount: controller.bordereaux.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bordereau = controller.bordereaux[index];
        return _buildBordereauCard(bordereau);
      },
    );
  }

  Widget _buildBordereauCard(Bordereau bordereau) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        title: Text(
          bordereau.reference,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bordereau.dateCreation)}'),
            Text('Montant: ${formatCurrency.format(bordereau.montantTTC)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Détails des articles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...bordereau.items.map((item) => _buildItemDetails(item)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total HT:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bordereau.montantHT)),
                  ],
                ),
                if (bordereau.remiseGlobale != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remise (${bordereau.remiseGlobale}%):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '- ${formatCurrency.format(bordereau.montantHT * (bordereau.remiseGlobale! / 100))}',
                      ),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (${bordereau.tva}%):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bordereau.montantTVA)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total TTC:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatCurrency.format(bordereau.montantTTC),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showApproveConfirmation(bordereau),
                      icon: const Icon(Icons.check),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(bordereau),
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemDetails(BordereauItem item) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.designation,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (item.description != null)
                  Text(
                    item.description!,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Text('${item.quantite} ${item.unite}'),
          ),
          Expanded(
            child: Text(formatCurrency.format(item.prixUnitaire)),
          ),
          Expanded(
            child: Text(
              formatCurrency.format(item.montantTotal),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(Bordereau bordereau) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce bordereau ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveBordereau(bordereau.id!);
      },
    );
  }

  void _showRejectDialog(Bordereau bordereau) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le bordereau',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: commentController,
            decoration: const InputDecoration(
              labelText: 'Motif du rejet',
              hintText: 'Entrez le motif du rejet',
            ),
            maxLines: 3,
          ),
        ],
      ),
      textConfirm: 'Rejeter',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectBordereau(bordereau.id!, commentController.text);
      },
    );
  }
}
