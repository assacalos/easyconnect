import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:intl/intl.dart';

class BonDeCommandeFournisseurListPage extends StatelessWidget {
  final BonDeCommandeFournisseurController controller = Get.put(
    BonDeCommandeFournisseurController(),
  );

  BonDeCommandeFournisseurListPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadBonDeCommandes();
    });
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bons de commande fournisseur'),
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
                      : _buildBonDeCommandeList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/bons-de-commande-fournisseur/new'),
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
                  Text('Tous (${controller.bonDeCommandes.length})'),
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
                    'En attente (${controller.bonDeCommandes.where((bc) => bc.statut == 'en_attente').length})',
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
                    'Validés (${controller.bonDeCommandes.where((bc) => bc.statut == 'valide').length})',
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
                    'Rejetés (${controller.bonDeCommandes.where((bc) => bc.statut == 'rejete').length})',
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
                    'Livrés (${controller.bonDeCommandes.where((bc) => bc.statut == 'livre').length})',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBonDeCommandeList() {
    return Obx(() {
      final filteredBonDeCommandes = controller.getFilteredBonDeCommandes();

      if (filteredBonDeCommandes.isEmpty) {
        return const Center(child: Text('Aucun bon de commande trouvé'));
      }

      return ListView.builder(
        itemCount: filteredBonDeCommandes.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final bonDeCommande = filteredBonDeCommandes[index];
          return _buildBonDeCommandeCard(bonDeCommande);
        },
      );
    });
  }

  Widget _buildBonDeCommandeCard(BonDeCommande bonDeCommande) {
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (bonDeCommande.statut.toLowerCase()) {
      case 'en_attente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'valide':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejete':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      case 'livre':
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
          bonDeCommande.numeroCommande,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Date: ${formatDate.format(bonDeCommande.dateCommande)}'),
            if (bonDeCommande.dateLivraisonPrevue != null)
              Text(
                'Livraison prévue: ${formatDate.format(bonDeCommande.dateLivraisonPrevue!)}',
              ),
            Text(
              'Montant: ${formatCurrency.format(bonDeCommande.montantTotalCalcule)}',
            ),
            Text(
              'Status: ${bonDeCommande.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (bonDeCommande.statut == 'rejete' &&
                bonDeCommande.commentaire != null &&
                bonDeCommande.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${bonDeCommande.commentaire}',
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
              onPressed: () => controller.generatePDF(bonDeCommande.id!),
              tooltip: 'Générer PDF',
            ),
            _buildActionButton(bonDeCommande),
          ],
        ),
        onTap:
            () => Get.toNamed(
              '/bons-de-commande-fournisseur/${bonDeCommande.id}',
            ),
      ),
    );
  }

  Widget _buildActionButton(BonDeCommande bonDeCommande) {
    final userRole = Get.find<BonDeCommandeFournisseurController>().userId;

    if (userRole == Roles.COMMERCIAL) {
      if (bonDeCommande.statut == 'en_attente') {
        return PopupMenuButton(
          itemBuilder:
              (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
              ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                Get.toNamed(
                  '/bons-de-commande-fournisseur/${bonDeCommande.id}/edit',
                );
                break;
              case 'delete':
                _showDeleteConfirmation(bonDeCommande);
                break;
            }
          },
        );
      }
    }

    if (userRole == Roles.PATRON && bonDeCommande.statut == 'en_attente') {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'approve', child: Text('Valider')),
              const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveConfirmation(bonDeCommande);
              break;
            case 'reject':
              _showRejectDialog(bonDeCommande);
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
                    controller.loadBonDeCommandes();
                  },
                ),
                ListTile(
                  title: const Text('En attente'),
                  onTap: () {
                    Get.back();
                    controller.loadBonDeCommandes(status: 'en_attente');
                  },
                ),
                ListTile(
                  title: const Text('Validés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonDeCommandes(status: 'valide');
                  },
                ),
                ListTile(
                  title: const Text('Rejetés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonDeCommandes(status: 'rejete');
                  },
                ),
                ListTile(
                  title: const Text('Livrés'),
                  onTap: () {
                    Get.back();
                    controller.loadBonDeCommandes(status: 'livre');
                  },
                ),
              ],
            ),
          ),
    );
  }

  void _showDeleteConfirmation(BonDeCommande bonDeCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous supprimer ce bon de commande ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.deleteBonDeCommande(bonDeCommande.id!);
      },
    );
  }

  void _showApproveConfirmation(BonDeCommande bonDeCommande) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce bon de commande ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveBonDeCommande(bonDeCommande.id!);
      },
    );
  }

  void _showRejectDialog(BonDeCommande bonDeCommande) {
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
        controller.rejectBonDeCommande(
          bonDeCommande.id!,
          commentController.text,
        );
      },
    );
  }
}
