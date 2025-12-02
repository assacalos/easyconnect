import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class SupplierValidationPage extends StatefulWidget {
  const SupplierValidationPage({super.key});

  @override
  State<SupplierValidationPage> createState() => _SupplierValidationPageState();
}

class _SupplierValidationPageState extends State<SupplierValidationPage>
    with SingleTickerProviderStateMixin {
  final SupplierController controller = Get.find<SupplierController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadSuppliers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadSuppliers();
    }
  }

  Future<void> _loadSuppliers() async {
    // Toujours charger tous les fournisseurs, le filtrage se fait côté client dans _buildSupplierList
    controller.selectedStatus.value = 'all';
    await controller.loadSuppliers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Fournisseurs'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSuppliers();
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
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, email...',
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
          Expanded(child: _buildSupplierList()),
        ],
      ),
    );
  }

  Widget _buildSupplierList() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SkeletonSearchResults(itemCount: 6);
      }

      // Utiliser allSuppliers au lieu de suppliers pour avoir tous les fournisseurs
      List<Supplier> filteredSuppliers = List.from(controller.allSuppliers);

      // Filtrer selon l'onglet actif
      switch (_tabController.index) {
        case 0: // Tous
          filteredSuppliers = controller.allSuppliers;
          break;
        case 1: // En attente
          filteredSuppliers =
              controller.allSuppliers
                  .where((supplier) => supplier.isPending)
                  .toList();
          break;
        case 2: // Validés
          filteredSuppliers =
              controller.allSuppliers
                  .where((supplier) => supplier.isValidated)
                  .toList();
          break;
        case 3: // Rejetés
          filteredSuppliers =
              controller.allSuppliers
                  .where((supplier) => supplier.isRejected)
                  .toList();
          break;
        default:
          filteredSuppliers = controller.allSuppliers;
      }
      
      // Appliquer aussi le filtre de recherche
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        filteredSuppliers = filteredSuppliers.where((supplier) {
          return supplier.nom.toLowerCase().contains(query) ||
              supplier.email.toLowerCase().contains(query) ||
              supplier.telephone.toLowerCase().contains(query) ||
              supplier.ville.toLowerCase().contains(query) ||
              supplier.pays.toLowerCase().contains(query);
        }).toList();
      }

      if (filteredSuppliers.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun fournisseur trouvé',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        itemCount: filteredSuppliers.length,
        padding: const EdgeInsets.all(8),
        itemBuilder: (context, index) {
          final supplier = filteredSuppliers[index];
          return _buildSupplierCard(supplier);
        },
      );
    });
  }

  Widget _buildSupplierCard(Supplier supplier) {
    Color statusColor;
    switch (supplier.statusColor) {
      case 'orange':
        statusColor = Colors.orange;
        break;
      case 'green':
        statusColor = Colors.green;
        break;
      case 'red':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.business, color: statusColor),
        ),
        title: Text(
          supplier.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.email, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    supplier.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  supplier.telephone,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.5)),
          ),
          child: Text(
            supplier.statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Adresse', supplier.adresse),
                _buildInfoRow('Ville', supplier.ville),
                _buildInfoRow('Pays', supplier.pays),
                if (supplier.description != null)
                  _buildInfoRow('Description', supplier.description!),
                if (supplier.noteEvaluation != null)
                  _buildInfoRow(
                    'Note',
                    '${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                  ),
                const SizedBox(height: 16),
                _buildActionButtons(supplier, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Supplier supplier, Color statusColor) {
    if (supplier.isPending) {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(supplier),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(supplier),
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
      );
    }

    if (supplier.isValidated) {
      // Validé - Afficher seulement info
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
              'Fournisseur validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (supplier.isRejected) {
      // Rejeté - Afficher motif du rejet
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
              'Fournisseur rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.help, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            'Statut: ${supplier.statusText}',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showApproveConfirmation(Supplier supplier) {
    final commentsController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous valider le fournisseur ${supplier.nom} ?'),
            const SizedBox(height: 16),
            TextField(
              controller: commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires d\'approbation (optionnel)',
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
            onPressed: () async {
              Get.back();
              await controller.approveSupplier(
                supplier,
                validationComment:
                    commentsController.text.trim().isEmpty
                        ? null
                        : commentsController.text.trim(),
              );
              // Recharger la liste après validation pour voir le changement
              await Future.delayed(const Duration(milliseconds: 800));
              _loadSuppliers();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Supplier supplier) {
    final reasonController = TextEditingController();
    final commentController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le fournisseur'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Voulez-vous rejeter le fournisseur ${supplier.nom} ?'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Motif du rejet (obligatoire)',
                  hintText: 'Expliquez la raison du rejet...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Commentaire (optionnel)',
                  hintText: 'Commentaire supplémentaire...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Le motif du rejet est obligatoire',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              controller.rejectSupplier(
                supplier,
                rejectionReason: reasonController.text.trim(),
                rejectionComment:
                    commentController.text.trim().isEmpty
                        ? null
                        : commentController.text.trim(),
              );
              _loadSuppliers();
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
}
