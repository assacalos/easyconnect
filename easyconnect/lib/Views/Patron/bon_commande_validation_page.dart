import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:intl/intl.dart';

class BonCommandeValidationPage extends GetView<BonCommandeController> {
  const BonCommandeValidationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Charger les bons de commande en attente
    controller.loadBonCommandes(status: 1);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des bons de commande'),
      ),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : _buildBonCommandeList(),
      ),
    );
  }

  Widget _buildBonCommandeList() {
    if (controller.bonCommandes.isEmpty) {
      return const Center(
        child: Text('Aucun bon de commande en attente de validation'),
      );
    }

    return ListView.builder(
      itemCount: controller.bonCommandes.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final bonCommande = controller.bonCommandes[index];
        return _buildBonCommandeCard(bonCommande);
      },
    );
  }

  Widget _buildBonCommandeCard(BonCommande bonCommande) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        title: Text(
          bonCommande.reference,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bonCommande.dateCreation)}'),
            if (bonCommande.dateLivraisonPrevue != null)
              Text(
                'Livraison prévue: ${formatDate.format(bonCommande.dateLivraisonPrevue!)}',
              ),
            Text('Montant: ${formatCurrency.format(bonCommande.montantTTC)}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (bonCommande.adresseLivraison != null) ...[
                  const Text(
                    'Adresse de livraison',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(bonCommande.adresseLivraison!),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'Détails des articles',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...bonCommande.items.map((item) => _buildItemDetails(item)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total HT:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bonCommande.montantHT)),
                  ],
                ),
                if (bonCommande.remiseGlobale != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Remise (${bonCommande.remiseGlobale}%):',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '- ${formatCurrency.format(bonCommande.montantHT * (bonCommande.remiseGlobale! / 100))}',
                      ),
                    ],
                  ),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TVA (${bonCommande.tva}%):',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(formatCurrency.format(bonCommande.montantTVA)),
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
                      formatCurrency.format(bonCommande.montantTTC),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _showApproveConfirmation(bonCommande),
                      icon: const Icon(Icons.check),
                      label: const Text('Valider'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showRejectDialog(bonCommande),
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

  Widget _buildItemDetails(BonCommandeItem item) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy');

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
                if (item.dateLivraison != null)
                  Text(
                    'Livraison: ${formatDate.format(item.dateLivraison!)}',
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

  void _showApproveConfirmation(BonCommande bonCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce bon de commande ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveBonCommande(bonCommande.id!);
      },
    );
  }

  void _showRejectDialog(BonCommande bonCommande) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le bon de commande',
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
        controller.rejectBonCommande(bonCommande.id!, commentController.text);
      },
    );
  }
}
