import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class BordereauListPage extends StatelessWidget {
  BordereauListPage({super.key});
  final BordereauController controller = Get.put(BordereauController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bordereaux'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Obx(
        () =>
            controller.isLoading.value
                ? const Center(child: CircularProgressIndicator())
                : _buildBordereauList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/bordereaux/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau bordereau'),
      ),
    );
  }

  Widget _buildBordereauList() {
    if (controller.bordereaux.isEmpty) {
      return const Center(child: Text('Aucun bordereau trouvé'));
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

    Color statusColor;
    IconData statusIcon;

    switch (bordereau.status) {
      case 0: // Brouillon
        statusColor = Colors.grey;
        statusIcon = Icons.edit;
        break;
      case 1: // En attente
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 2: // Validé
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 3: // Rejeté
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
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
            Text(
              'Status: ${bordereau.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: _buildActionButton(bordereau),
        onTap: () => Get.toNamed('/bordereaux/${bordereau.id}'),
      ),
    );
  }

  Widget _buildActionButton(Bordereau bordereau) {
    final userRole = Get.put(BordereauController()).userId;

    if (userRole == Roles.COMMERCIAL && bordereau.status == 0) {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(value: 'submit', child: Text('Soumettre')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'edit':
              Get.toNamed('/bordereaux/${bordereau.id}/edit');
              break;
            case 'submit':
              _showSubmitConfirmation(bordereau);
              break;
            case 'delete':
              _showDeleteConfirmation(bordereau);
              break;
          }
        },
      );
    }

    if (userRole == Roles.PATRON && bordereau.status == 1) {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'approve', child: Text('Valider')),
              const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(bordereau);
              break;
            case 'reject':
              _showRejectDialog(bordereau);
              break;
          }
        },
      );
    }

    // Si aucune action n'est disponible, retourner un widget vide
    return const SizedBox.shrink();
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filtrer par statut'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('Tous'),
                  onTap: () {
                    Get.back();
                    controller.loadBordereaux();
                  },
                ),
                ListTile(
                  title: const Text('Brouillons'),
                  onTap: () {
                    Get.back();
                    controller.loadBordereaux(status: 0);
                  },
                ),
                ListTile(
                  title: const Text('En attente'),
                  onTap: () {
                    Get.back();
                    controller.loadBordereaux(status: 1);
                  },
                ),
                ListTile(
                  title: const Text('Validés'),
                  onTap: () {
                    Get.back();
                    controller.loadBordereaux(status: 2);
                  },
                ),
                ListTile(
                  title: const Text('Rejetés'),
                  onTap: () {
                    Get.back();
                    controller.loadBordereaux(status: 3);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSubmitConfirmation(Bordereau bordereau) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous soumettre ce bordereau pour validation ?',
      textConfirm: 'Soumettre',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.submitBordereau(bordereau.id!);
      },
    );
  }

  void _showDeleteConfirmation(Bordereau bordereau) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous supprimer ce bordereau ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteBordereau(bordereau.id!);
      },
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
