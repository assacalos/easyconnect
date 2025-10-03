import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Models/supplier_model.dart';

class SupplierList extends StatelessWidget {
  const SupplierList({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ SupplierList: build() appelé');

    final SupplierController controller = Get.find<SupplierController>();
    print('✅ SupplierList: SupplierController trouvé');
    print(
      '📊 SupplierList: Nombre de fournisseurs: ${controller.suppliers.length}',
    );
    print('⏳ SupplierList: isLoading: ${controller.isLoading.value}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Fournisseurs'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadSuppliers(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche et filtres
          _buildSearchAndFilters(controller),

          // Statistiques rapides
          _buildQuickStats(controller),

          // Liste des fournisseurs
          Expanded(child: _buildSupplierList(controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(controller),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchAndFilters(SupplierController controller) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un fournisseur...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.searchSuppliers(value),
          ),

          const SizedBox(height: 12),

          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Tous', 'all', controller),
                const SizedBox(width: 8),
                _buildFilterChip('En attente', 'pending', controller),
                const SizedBox(width: 8),
                _buildFilterChip('Approuvés', 'approved', controller),
                const SizedBox(width: 8),
                _buildFilterChip('Rejetés', 'rejected', controller),
                const SizedBox(width: 8),
                _buildFilterChip('Actifs', 'active', controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    SupplierController controller,
  ) {
    return Obx(() {
      print('🔍 SupplierList: _buildFilterChip($label, $value) - Obx rebuild');
      print(
        '📊 SupplierList: selectedStatus = ${controller.selectedStatus.value}',
      );

      return FilterChip(
        label: Text(label),
        selected: controller.selectedStatus.value == value,
        onSelected: (selected) {
          print('🔘 SupplierList: FilterChip $label sélectionné: $selected');
          if (selected) {
            controller.filterByStatus(value);
          }
        },
        selectedColor: Colors.deepPurple.withOpacity(0.2),
        checkmarkColor: Colors.deepPurple,
      );
    });
  }

  Widget _buildQuickStats(SupplierController controller) {
    return Obx(() {
      if (controller.supplierStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.supplierStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats.total.toString(),
                Icons.business,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En attente',
                stats.pending.toString(),
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Approuvés',
                stats.approved.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Actifs',
                stats.active.toString(),
                Icons.verified,
                Colors.purple,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: color),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierList(SupplierController controller) {
    return Obx(() {
      print('🔄 SupplierList: _buildSupplierList() - Obx rebuild');
      print('⏳ SupplierList: isLoading = ${controller.isLoading.value}');
      print(
        '📊 SupplierList: suppliers.length = ${controller.suppliers.length}',
      );

      if (controller.isLoading.value) {
        print('⏳ SupplierList: Affichage du loading...');
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.suppliers.isEmpty) {
        print('📭 SupplierList: Aucun fournisseur trouvé');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.business_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun fournisseur trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter un fournisseur',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      print(
        '📋 SupplierList: Affichage de la liste avec ${controller.suppliers.length} fournisseurs',
      );
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.suppliers.length,
        itemBuilder: (context, index) {
          final supplier = controller.suppliers[index];
          print(
            '🏢 SupplierList: Affichage du fournisseur $index: ${supplier.nom}',
          );
          return _buildSupplierCard(supplier, controller);
        },
      );
    });
  }

  Widget _buildSupplierCard(Supplier supplier, SupplierController controller) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showSupplierDetails(supplier, controller),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec nom et statut
              Row(
                children: [
                  Expanded(
                    child: Text(
                      supplier.nom,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(supplier),
                ],
              ),

              const SizedBox(height: 8),

              // Informations de contact
              Row(
                children: [
                  Icon(Icons.email, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      supplier.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    supplier.telephone,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${supplier.ville}, ${supplier.pays}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ),
                ],
              ),

              // Note d'évaluation si disponible
              if (supplier.noteEvaluation != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Note: ${supplier.noteEvaluation!.toStringAsFixed(1)}/5',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              // Actions
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (supplier.isPending) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(supplier, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(supplier, controller),
                    ),
                  ],
                  if (supplier.isApproved) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Évaluer'),
                      onPressed: () => _showRatingDialog(supplier, controller),
                    ),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () => _showEditDialog(supplier, controller),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    onPressed: () => _showDeleteDialog(supplier, controller),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Supplier supplier) {
    Color color;
    switch (supplier.statusColor) {
      case 'orange':
        color = Colors.orange;
        break;
      case 'blue':
        color = Colors.blue;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        supplier.statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Dialogues
  void _showCreateDialog(SupplierController controller) {
    controller.clearForm();
    Get.dialog(
      AlertDialog(
        title: const Text('Nouveau Fournisseur'),
        content: _buildSupplierForm(controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.createSupplier();
              Get.back();
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Supplier supplier, SupplierController controller) {
    controller.fillForm(supplier);
    Get.dialog(
      AlertDialog(
        title: const Text('Modifier le Fournisseur'),
        content: _buildSupplierForm(controller),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.updateSupplier(supplier);
              Get.back();
            },
            child: const Text('Modifier'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupplierForm(SupplierController controller) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller.nomController,
            decoration: const InputDecoration(labelText: 'Nom'),
          ),
          TextField(
            controller: controller.emailController,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: controller.telephoneController,
            decoration: const InputDecoration(labelText: 'Téléphone'),
          ),
          TextField(
            controller: controller.adresseController,
            decoration: const InputDecoration(labelText: 'Adresse'),
          ),
          TextField(
            controller: controller.villeController,
            decoration: const InputDecoration(labelText: 'Ville'),
          ),
          TextField(
            controller: controller.paysController,
            decoration: const InputDecoration(labelText: 'Pays'),
          ),
          TextField(
            controller: controller.contactPrincipalController,
            decoration: const InputDecoration(labelText: 'Contact Principal'),
          ),
          TextField(
            controller: controller.descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  void _showSupplierDetails(Supplier supplier, SupplierController controller) {
    Get.dialog(
      AlertDialog(
        title: Text(supplier.nom),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${supplier.email}'),
              Text('Téléphone: ${supplier.telephone}'),
              Text('Adresse: ${supplier.adresse}'),
              Text('Ville: ${supplier.ville}'),
              Text('Pays: ${supplier.pays}'),
              Text('Contact: ${supplier.contactPrincipal}'),
              if (supplier.description != null)
                Text('Description: ${supplier.description}'),
              if (supplier.noteEvaluation != null)
                Text('Note: ${supplier.noteEvaluation}/5'),
              if (supplier.commentaires != null)
                Text('Commentaires: ${supplier.commentaires}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Fermer')),
        ],
      ),
    );
  }

  void _showApproveDialog(Supplier supplier, SupplierController controller) {
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

  void _showRejectDialog(Supplier supplier, SupplierController controller) {
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

  void _showRatingDialog(Supplier supplier, SupplierController controller) {
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

  void _showDeleteDialog(Supplier supplier, SupplierController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer le fournisseur'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${supplier.nom} ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.deleteSupplier(supplier);
              Get.back();
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

  // Méthodes manquantes pour la compatibilité
  void rateSupplier(Supplier supplier, double rating, {String? comments}) {
    // Cette méthode sera implémentée dans le contrôleur
  }
}
