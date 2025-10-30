import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';

class BonCommandeDetailPage extends StatelessWidget {
  final int bonCommandeId;

  BonCommandeDetailPage({super.key, required this.bonCommandeId});

  @override
  Widget build(BuildContext context) {
    final BonCommandeController controller = Get.find<BonCommandeController>();
    final bon = controller.bonCommandes.firstWhereOrNull(
      (b) => b.id == bonCommandeId,
    );
    final formatDate = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');

    if (bon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du bon de commande')),
        body: const Center(child: Text('Bon de commande introuvable')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bon ${bon.reference}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(bon, nf),
            const SizedBox(height: 16),
            _card('Informations', [
              _row(
                Icons.calendar_today,
                'Date de création',
                formatDate.format(bon.dateCreation),
              ),
              if (bon.dateLivraisonPrevue != null)
                _row(
                  Icons.local_shipping,
                  'Livraison prévue',
                  formatDate.format(bon.dateLivraisonPrevue!),
                ),
              _row(Icons.info, 'Statut', bon.statusText),
              if (bon.adresseLivraison != null &&
                  bon.adresseLivraison!.isNotEmpty)
                _row(
                  Icons.place,
                  'Adresse de livraison',
                  bon.adresseLivraison!,
                ),
            ]),
            const SizedBox(height: 16),
            _card('Montants', [
              _row(Icons.summarize, 'Montant HT', nf.format(bon.montantHT)),
              _row(Icons.percent, 'TVA', nf.format(bon.montantTVA)),
              _row(
                Icons.calculate,
                'Montant TTC',
                nf.format(bon.montantTTC),
                bold: true,
              ),
            ]),
            if (bon.status == 3 &&
                bon.commentaireRejet != null &&
                bon.commentaireRejet!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _rejection('Motif du rejet', bon.commentaireRejet!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BonCommande b, NumberFormat nf) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.shopping_cart),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.reference,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      b.statusText,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              nf.format(b.montantTTC),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rejection(String title, String reason) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.report, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reason,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

