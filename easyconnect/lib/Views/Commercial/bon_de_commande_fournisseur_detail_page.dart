import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';

class BonDeCommandeFournisseurDetailPage extends StatelessWidget {
  final int bonDeCommandeId;

  BonDeCommandeFournisseurDetailPage({
    super.key,
    required this.bonDeCommandeId,
  });

  @override
  Widget build(BuildContext context) {
    final BonDeCommandeFournisseurController controller =
        Get.find<BonDeCommandeFournisseurController>();
    final bon = controller.bonDeCommandes.firstWhereOrNull(
      (b) => b.id == bonDeCommandeId,
    );
    final formatDate = DateFormat('dd/MM/yyyy');
    final nf = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');

    if (bon == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Détails du bon de commande')),
        body: const Center(child: Text('Bon de commande introuvable')),
      );
    }

    Color statusColor;
    switch (bon.statut.toLowerCase()) {
      case 'en_attente':
        statusColor = Colors.orange;
        break;
      case 'valide':
        statusColor = Colors.green;
        break;
      case 'rejete':
        statusColor = Colors.red;
        break;
      case 'livre':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Scaffold(
      appBar: AppBar(title: Text('Bon ${bon.numeroCommande}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(bon, nf, statusColor),
            const SizedBox(height: 16),
            _card('Informations', [
              _row(
                Icons.calendar_today,
                'Date de commande',
                formatDate.format(bon.dateCommande),
              ),
              _row(Icons.info, 'Statut', bon.statusText),
              if (bon.description != null && bon.description!.isNotEmpty)
                _row(Icons.description, 'Description', bon.description!),
              if (bon.conditionsPaiement != null &&
                  bon.conditionsPaiement!.isNotEmpty)
                _row(
                  Icons.payment,
                  'Conditions de paiement',
                  bon.conditionsPaiement!,
                ),
              if (bon.delaiLivraison != null)
                _row(
                  Icons.schedule,
                  'Délai de livraison',
                  '${bon.delaiLivraison} jours',
                ),
            ]),
            const SizedBox(height: 16),
            _card('Articles', [
              if (bon.items.isEmpty)
                const Text('Aucun article')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bon.items.length,
                  itemBuilder: (context, index) {
                    return _buildItemRow(bon.items[index], nf);
                  },
                ),
            ]),
            const SizedBox(height: 16),
            _card('Montants', [
              _row(
                Icons.calculate,
                'Montant total',
                nf.format(bon.montantTotalCalcule),
                bold: true,
              ),
            ]),
            if (bon.statut == 'rejete' &&
                bon.commentaire != null &&
                bon.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _rejection('Motif du rejet', bon.commentaire!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _header(BonDeCommande b, NumberFormat nf, Color statusColor) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(_getStatusIcon(b.statut), color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    b.numeroCommande,
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
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      b.statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              nf.format(b.montantTotalCalcule),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String statut) {
    switch (statut.toLowerCase()) {
      case 'en_attente':
        return Icons.pending;
      case 'valide':
        return Icons.check_circle;
      case 'rejete':
        return Icons.cancel;
      case 'livre':
        return Icons.local_shipping;
      default:
        return Icons.help;
    }
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

  Widget _buildItemRow(BonDeCommandeItem item, NumberFormat nf) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.designation,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  nf.format(item.montantTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            if (item.ref != null && item.ref!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Réf: ${item.ref}',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Qté: ${item.quantite}'),
                const SizedBox(width: 16),
                Text('Prix unitaire: ${nf.format(item.prixUnitaire)}'),
              ],
            ),
            if (item.description != null && item.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                item.description!,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ],
          ],
        ),
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
