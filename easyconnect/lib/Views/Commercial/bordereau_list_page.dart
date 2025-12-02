import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class BordereauListPage extends StatelessWidget {
  final int? clientId;

  BordereauListPage({super.key, this.clientId});
  final BordereauxController controller = Get.put(BordereauxController());

  @override
  Widget build(BuildContext context) {
    // Charger les données au démarrage de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Toujours charger au démarrage de la page (le contrôleur ne charge plus automatiquement)
      controller.loadBordereaux();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bordereaux'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'Validés'),
              Tab(text: 'Rejetés'),
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              children: [
                _buildBordereauList(1), // En attente
                _buildBordereauList(2), // Validés
                _buildBordereauList(3), // Rejetés
              ],
            ),
            // Bouton d'ajout uniforme en bas à droite
            UniformAddButton(
              onPressed: () => Get.toNamed('/bordereaux/new'),
              label: 'Nouveau Bordereau',
              icon: Icons.assignment,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBordereauList(int status) {
    // Récupérer clientId depuis les arguments
    final args = Get.arguments as Map<String, dynamic>?;
    final filterClientId = clientId ?? args?['clientId'] as int?;

    return Obx(() {
      if (controller.isLoading.value) {
        return const SkeletonSearchResults(itemCount: 6);
      }

      var bordereauList =
          controller.bordereaux.where((b) => b.status == status).toList();

      // Filtrer par clientId si fourni
      if (filterClientId != null) {
        bordereauList =
            bordereauList.where((b) => b.clientId == filterClientId).toList();
      }

      if (bordereauList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 1
                    ? Icons.access_time
                    : status == 2
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 1
                    ? 'Aucun bordereau en attente'
                    : status == 2
                    ? 'Aucun bordereau validé'
                    : 'Aucun bordereau rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bordereauList.length,
        itemBuilder: (context, index) {
          final bordereau = bordereauList[index];
          return _buildBordereauCard(bordereau);
        },
      );
    });
  }

  Widget _buildBordereauCard(Bordereau bordereau) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (bordereau.status) {
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
            if (bordereau.status == 3 &&
                (bordereau.commentaireRejet != null &&
                    bordereau.commentaireRejet!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${bordereau.commentaireRejet}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => controller.generatePDF(bordereau.id!),
              tooltip: 'Générer PDF',
            ),
            _buildActionButton(bordereau),
          ],
        ),
        onTap: () => Get.toNamed('/bordereaux/${bordereau.id}'),
      ),
    );
  }

  Widget _buildActionButton(Bordereau bordereau) {
    final userRole = Get.put(BordereauxController()).userId;

    if (userRole == Roles.COMMERCIAL && bordereau.status == 1) {
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

    // Bouton Modifier pour les bordereaux validés ou rejetés
    if (userRole == Roles.COMMERCIAL &&
        (bordereau.status == 2 || bordereau.status == 3)) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => Get.toNamed('/bordereaux/${bordereau.id}/edit'),
        tooltip: 'Modifier',
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
