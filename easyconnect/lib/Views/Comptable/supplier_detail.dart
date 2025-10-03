import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Views/Comptable/supplier_form.dart';
import 'package:intl/intl.dart';

class SupplierDetail extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetail({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    final SupplierController controller = Get.put(SupplierController());
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(supplier.nom),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (controller.canCreateSuppliers)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => SupplierForm(supplier: supplier)),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareSupplier(),
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
              _buildInfoRow(Icons.business, 'Nom', supplier.nom),
              _buildInfoRow(Icons.email, 'Email', supplier.email),
              _buildInfoRow(Icons.phone, 'Téléphone', supplier.telephone),
              _buildInfoRow(
                Icons.person,
                'Contact principal',
                supplier.contactPrincipal,
              ),
            ]),

            const SizedBox(height: 16),

            // Adresse
            _buildInfoCard('Adresse', [
              _buildInfoRow(Icons.location_on, 'Adresse', supplier.adresse),
              _buildInfoRow(Icons.location_city, 'Ville', supplier.ville),
              _buildInfoRow(Icons.public, 'Pays', supplier.pays),
            ]),

            // Description si disponible
            if (supplier.description != null &&
                supplier.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Description', [
                _buildInfoRow(
                  Icons.description,
                  'Description',
                  supplier.description!,
                ),
              ]),
            ],

            // Commentaires si disponibles
            if (supplier.commentaires != null &&
                supplier.commentaires!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaires', [
                _buildInfoRow(
                  Icons.comment,
                  'Commentaires',
                  supplier.commentaires!,
                ),
              ]),
            ],

            // Note d'évaluation si disponible
            if (supplier.noteEvaluation != null) ...[
              const SizedBox(height: 16),
              _buildRatingCard(),
            ],

            // Historique des actions
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(controller),
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
              child: Icon(Icons.business, size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.nom,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(supplier.createdAt)}',
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
            supplier.statusText,
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

  Widget _buildRatingCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Évaluation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 24),
                const SizedBox(width: 8),
                Text(
                  '${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: LinearProgressIndicator(
                    value: supplier.noteEvaluation! / 5,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.amber[600]!,
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
              DateFormat('dd/MM/yyyy à HH:mm').format(supplier.createdAt),
              Colors.blue,
            ),
            if (supplier.statut == 'submitted')
              _buildHistoryItem(
                Icons.send,
                'Soumis au patron',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.createdAt),
                Colors.orange,
              ),
            if (supplier.statut == 'approved')
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.createdAt),
                Colors.green,
              ),
            if (supplier.statut == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejeté',
                DateFormat('dd/MM/yyyy à HH:mm').format(supplier.createdAt),
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

  Widget _buildActionButtons(SupplierController controller) {
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
                if (controller.canCreateSuppliers) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: const Text('Soumettre'),
                      onPressed: () => _showSubmitDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (supplier.isPending && controller.canApproveSuppliers) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (supplier.isApproved) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.star),
                      label: const Text('Évaluer'),
                      onPressed: () => _showRatingDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (supplier.statusColor) {
      case 'orange':
        return Colors.orange;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (supplier.statut) {
      case 'edit':
        return Icons.edit;
      case 'schedule':
        return Icons.schedule;
      case 'check_circle':
        return Icons.check_circle;
      case 'cancel':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _shareSupplier() {
    // Implémentation du partage
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showSubmitDialog(SupplierController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Soumettre le fournisseur'),
        content: const Text(
          'Êtes-vous sûr de vouloir soumettre ce fournisseur au patron pour approbation ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.submitSupplier(supplier);
              Get.back();
            },
            child: const Text('Soumettre'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(SupplierController controller) {
    final commentsController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver le fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Commentaires d\'approbation (optionnel) :'),
            const SizedBox(height: 8),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                hintText: 'Ajouter des commentaires...',
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
              controller.approveSupplier(
                supplier,
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

  void _showRejectDialog(SupplierController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le fournisseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Motif du rejet (obligatoire) :'),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Expliquez la raison du rejet...',
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
                controller.rejectSupplier(
                  supplier,
                  reasonController.text.trim(),
                );
                Get.back();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(SupplierController controller) {
    final commentsController = TextEditingController();
    double rating = supplier.noteEvaluation ?? 0.0;

    Get.dialog(
      AlertDialog(
        title: const Text('Évaluer le fournisseur'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Note (1-5 étoiles) :'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 32,
                      ),
                      onPressed: () {
                        setState(() {
                          rating = index + 1.0;
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 16),
                const Text('Commentaires (optionnel) :'),
                const SizedBox(height: 8),
                TextField(
                  controller: commentsController,
                  decoration: const InputDecoration(
                    hintText: 'Ajouter des commentaires...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.rateSupplier(
                supplier,
                rating,
                comments:
                    commentsController.text.trim().isEmpty
                        ? null
                        : commentsController.text.trim(),
              );
              Get.back();
            },
            child: const Text('Évaluer'),
          ),
        ],
      ),
    );
  }
}
