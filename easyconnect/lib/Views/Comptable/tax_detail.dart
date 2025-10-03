import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:intl/intl.dart';

class TaxDetail extends StatelessWidget {
  final Tax tax;

  const TaxDetail({super.key, required this.tax});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tax.name),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed:
                () => Get.toNamed('/taxes/${tax.id}/edit', arguments: tax),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.receipt, 'Nom', tax.name),
              _buildInfoRow(
                Icons.attach_money,
                'Montant',
                '${tax.amount.toStringAsFixed(2)} €',
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Date d\'échéance',
                DateFormat('dd/MM/yyyy').format(tax.dueDate),
              ),
              _buildInfoRow(Icons.flag, 'Statut', tax.statusText),
            ]),

            // Description si disponible
            if (tax.description != null && tax.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Description', [
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  tax.description!,
                ),
              ]),
            ],

            // Motif de rejet si rejeté
            if (tax.isRejected && tax.rejectionReason != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Motif du rejet', [
                _buildInfoRow(Icons.cancel, 'Raison', tax.rejectionReason!),
              ]),
            ],

            // Historique
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getStatusColor().withOpacity(0.1),
              child: Icon(Icons.receipt, size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tax.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(tax.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            tax.statusText,
            style: TextStyle(
              color: _getStatusColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              Icons.add,
              'Créé',
              DateFormat('dd/MM/yyyy à HH:mm').format(tax.createdAt),
              Colors.blue,
            ),
            if (tax.isValidated)
              _buildHistoryItem(
                Icons.check_circle,
                'Validé',
                DateFormat('dd/MM/yyyy à HH:mm').format(tax.updatedAt),
                Colors.green,
              ),
            if (tax.isRejected)
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                DateFormat('dd/MM/yyyy à HH:mm').format(tax.updatedAt),
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    IconData icon,
    String action,
    String date,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Modifier'),
                    onPressed:
                        () => Get.toNamed(
                          '/taxes/${tax.id}/edit',
                          arguments: tax,
                        ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('Supprimer'),
                    onPressed: () => _showDeleteDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (tax.status) {
      case 'pending':
        return Colors.orange;
      case 'validated':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (tax.status) {
      case 'pending':
        return Icons.schedule;
      case 'validated':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showDeleteDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la taxe'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${tax.name} ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              // Logique de suppression
              Get.back();
              Get.back(); // Retour à la liste
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}
