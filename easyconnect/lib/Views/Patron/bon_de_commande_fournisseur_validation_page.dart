import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:intl/intl.dart';

class BonDeCommandeFournisseurValidationPage extends StatefulWidget {
  const BonDeCommandeFournisseurValidationPage({super.key});

  @override
  State<BonDeCommandeFournisseurValidationPage> createState() =>
      _BonDeCommandeFournisseurValidationPageState();
}

class _BonDeCommandeFournisseurValidationPageState
    extends State<BonDeCommandeFournisseurValidationPage>
    with SingleTickerProviderStateMixin {
  late final BonDeCommandeFournisseurController controller;
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<BonDeCommandeFournisseurController>()) {
      Get.put(BonDeCommandeFournisseurController(), permanent: true);
    }
    controller = Get.find<BonDeCommandeFournisseurController>();

    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadBonDeCommandes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadBonDeCommandes();
    }
  }

  Future<void> _loadBonDeCommandes() async {
    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 'en_attente';
        break;
      case 2: // Validés
        status = 'valide';
        break;
      case 3: // Rejetés
        status = 'rejete';
        break;
    }

    await controller.loadBonDeCommandes(status: status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Bons de Commande Fournisseur'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadBonDeCommandes();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par numéro de commande...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              var filteredBonDeCommandes =
                  controller.getFilteredBonDeCommandes();

              if (_searchQuery.isNotEmpty) {
                filteredBonDeCommandes =
                    filteredBonDeCommandes
                        .where(
                          (bc) => bc.numeroCommande.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ),
                        )
                        .toList();
              }

              if (filteredBonDeCommandes.isEmpty) {
                return const Center(
                  child: Text('Aucun bon de commande trouvé'),
                );
              }

              return ListView.builder(
                itemCount: filteredBonDeCommandes.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final bonDeCommande = filteredBonDeCommandes[index];
                  return _buildBonDeCommandeCard(bonDeCommande);
                },
              );
            }),
          ),
        ],
      ),
    );
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
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withOpacity(0.1),
                  child: Icon(statusIcon, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bonDeCommande.numeroCommande,
                        style: const TextStyle(
                          fontSize: 18,
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
                          bonDeCommande.statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatCurrency.format(bonDeCommande.montantTotalCalcule),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(
              Icons.calendar_today,
              'Date de commande',
              formatDate.format(bonDeCommande.dateCommande),
            ),
            if (bonDeCommande.dateLivraisonPrevue != null)
              _buildInfoRow(
                Icons.local_shipping,
                'Livraison prévue',
                formatDate.format(bonDeCommande.dateLivraisonPrevue!),
              ),
            _buildInfoRow(
              Icons.shopping_cart,
              'Nombre d\'articles',
              '${bonDeCommande.items.length}',
            ),
            if (bonDeCommande.description != null &&
                bonDeCommande.description!.isNotEmpty)
              _buildInfoRow(
                Icons.description,
                'Description',
                bonDeCommande.description!,
              ),
            if (bonDeCommande.statut == 'rejete' &&
                bonDeCommande.commentaire != null &&
                bonDeCommande.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.report, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Motif du rejet:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            bonDeCommande.commentaire!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _buildActionButtons(bonDeCommande, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BonDeCommande bonDeCommande, Color statusColor) {
    switch (bonDeCommande.statut.toLowerCase()) {
      case 'en_attente':
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showApproveConfirmation(bonDeCommande),
                  icon: const Icon(Icons.check),
                  label: const Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _showRejectDialog(bonDeCommande),
                  icon: const Icon(Icons.close),
                  label: const Text('Rejeter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed:
                  () => Get.toNamed(
                    '/bons-de-commande-fournisseur/${bonDeCommande.id}',
                  ),
              icon: const Icon(Icons.visibility),
              label: const Text('Voir les détails'),
            ),
          ],
        );
      case 'valide':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Bon de commande validé',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      case 'rejete':
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                'Bon de commande rejeté',
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
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
        _loadBonDeCommandes();
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
              labelText: 'Motif du rejet *',
              hintText: 'Entrez le motif du rejet',
              border: OutlineInputBorder(),
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
        _loadBonDeCommandes();
      },
    );
  }
}
