import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class BonCommandeListPage extends StatelessWidget {
  final BonCommandeController controller = Get.find<BonCommandeController>();
  BonCommandeListPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadBonCommandes();
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de commande'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatusTabs(),
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBonCommandeList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/bon-commandes/new'),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau bon de commande'),
      ),
    );
  }

  Widget _buildStatusTabs() {
    return Obx(
      () => Container(
        color: Colors.grey[100],
        child: TabBar(
          controller: controller.tabController,
          isScrollable: true,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[600],
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.all_inclusive, size: 16),
                  const SizedBox(width: 4),
                  Text('Tous (${controller.bonCommandes.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pending, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'En attente (${controller.bonCommandes.where((bc) => bc.status == 1).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Validés (${controller.bonCommandes.where((bc) => bc.status == 2).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Rejetés (${controller.bonCommandes.where((bc) => bc.status == 3).length})',
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_shipping, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Livrés (${controller.bonCommandes.where((bc) => bc.status == 4).length})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonCommandeList() {
    return Obx(() {
      final filteredBonCommandes = controller.getFilteredBonCommandes();

      if (filteredBonCommandes.isEmpty) {
        return const Center(child: Text('Aucun bon de commande trouvé'));
      }

      return ListView.builder(
        itemCount: filteredBonCommandes.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final bonCommande = filteredBonCommandes[index];
          return _buildBonCommandeCard(bonCommande);
        },
      );
    });
  }

  Widget _buildBonCommandeCard(BonCommande bonCommande) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (bonCommande.status) {
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
      case 4: // Livré
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
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
            Text(
              'Status: ${bonCommande.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: _buildActionButton(bonCommande),
        onTap: () => Get.toNamed('/bon-commandes/${bonCommande.id}'),
      ),
    );
  }

  Widget _buildActionButton(BonCommande bonCommande) {
    final userRole = Get.put(BonCommandeController()).userId;

    if (userRole == Roles.COMMERCIAL) {
      if (bonCommande.status == 0) {
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
                Get.toNamed('/bon-commandes/${bonCommande.id}/edit');
                break;
              case 'submit':
                _showSubmitConfirmation(bonCommande);
                break;
              case 'delete':
                _showDeleteConfirmation(bonCommande);
                break;
            }
          },
        );
      }
      if (bonCommande.status == 2 && !bonCommande.estLivre) {
        return IconButton(
          icon: const Icon(Icons.local_shipping),
          onPressed: () => _showDeliveryConfirmation(bonCommande),
        );
      }
    }

    if (userRole == Roles.PATRON && bonCommande.status == 1) {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'approve', child: Text('Valider')),
              const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(bonCommande);
              break;
            case 'reject':
              _showRejectDialog(bonCommande);
              break;
          }
        },
      );
    }

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
                    controller.loadBonCommandes();
                  },
                ),
                ListTile(
                  title: const Text('En attente'),
                  onTap: () {
                    Get.back();
                    controller.loadBonCommandes(status: 1);
                  },
                ),
                ListTile(
                  title: const Text('Validés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonCommandes(status: 2);
                  },
                ),
                ListTile(
                  title: const Text('Rejetés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonCommandes(status: 3);
                  },
                ),
                ListTile(
                  title: const Text('Livrés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonCommandes(status: 4);
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showSubmitConfirmation(BonCommande bonCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous soumettre ce bon de commande pour validation ?',
      textConfirm: 'Soumettre',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.submitBonCommande(bonCommande.id!);
      },
    );
  }

  void _showDeleteConfirmation(BonCommande bonCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous supprimer ce bon de commande ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteBonCommande(bonCommande.id!);
      },
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

  void _showDeliveryConfirmation(BonCommande bonCommande) {
    Get.defaultDialog(
      title: 'Confirmation de livraison',
      middleText: 'Confirmez-vous la livraison de ce bon de commande ?',
      textConfirm: 'Confirmer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.markAsDelivered(bonCommande.id!);
      },
    );
  }
}
