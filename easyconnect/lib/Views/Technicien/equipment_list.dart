import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/Views/Technicien/equipment_form.dart';
import 'package:easyconnect/Views/Technicien/equipment_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class EquipmentList extends StatelessWidget {
  const EquipmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final EquipmentController controller = Get.put(EquipmentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Équipements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadEquipments(),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Barre de recherche et filtres
              _buildSearchAndFilters(controller),

              // Statistiques rapides
              _buildQuickStats(controller),

              // Liste des équipements
              Expanded(child: _buildEquipmentList(controller)),
            ],
          ),
          // Bouton d'ajout uniforme en bas à droite
          if (controller.canManageEquipments)
            UniformAddButton(
              onPressed: () => Get.to(() => const EquipmentForm()),
              label: 'Nouvel Équipement',
              icon: Icons.devices,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(EquipmentController controller) {
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
              hintText: 'Rechercher un équipement...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.searchEquipments(value),
          ),

          const SizedBox(height: 12),

          // Filtres
          Row(
            children: [
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedStatus.value,
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(value: 'active', child: Text('Actif')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactif')),
                      DropdownMenuItem(value: 'maintenance', child: Text('En maintenance')),
                      DropdownMenuItem(value: 'broken', child: Text('Hors service')),
                      DropdownMenuItem(value: 'retired', child: Text('Retiré')),
                    ],
                    onChanged: (value) => controller.filterByStatus(value!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCategory.value,
                    decoration: const InputDecoration(
                      labelText: 'Catégorie',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Toutes')),
                      DropdownMenuItem(value: 'computer', child: Text('Ordinateur')),
                      DropdownMenuItem(value: 'printer', child: Text('Imprimante')),
                      DropdownMenuItem(value: 'network', child: Text('Réseau')),
                      DropdownMenuItem(value: 'server', child: Text('Serveur')),
                      DropdownMenuItem(value: 'mobile', child: Text('Mobile')),
                      DropdownMenuItem(value: 'tablet', child: Text('Tablette')),
                      DropdownMenuItem(value: 'monitor', child: Text('Écran')),
                      DropdownMenuItem(value: 'other', child: Text('Autre')),
                    ],
                    onChanged: (value) => controller.filterByCategory(value!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedCondition.value,
                    decoration: const InputDecoration(
                      labelText: 'État',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(value: 'excellent', child: Text('Excellent')),
                      DropdownMenuItem(value: 'good', child: Text('Bon')),
                      DropdownMenuItem(value: 'fair', child: Text('Correct')),
                      DropdownMenuItem(value: 'poor', child: Text('Mauvais')),
                      DropdownMenuItem(value: 'critical', child: Text('Critique')),
                    ],
                    onChanged: (value) => controller.filterByCondition(value!),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(EquipmentController controller) {
    return Obx(() {
      if (controller.equipmentStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.equipmentStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats.totalEquipment}',
                Icons.devices,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Actifs',
                '${stats.activeEquipment}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Maintenance',
                '${stats.maintenanceEquipment}',
                Icons.build,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Hors service',
                '${stats.brokenEquipment}',
                Icons.error,
                Colors.red,
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

  Widget _buildEquipmentList(EquipmentController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredEquipments = controller.filteredEquipments;

      if (filteredEquipments.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.devices_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucun équipement trouvé',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter un équipement',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredEquipments.length,
        itemBuilder: (context, index) {
          final equipment = filteredEquipments[index];
          return _buildEquipmentCard(equipment, controller);
        },
      );
    });
  }

  Widget _buildEquipmentCard(Equipment equipment, EquipmentController controller) {
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: 'fcfa');
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => EquipmentDetail(equipment: equipment)),
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
                      equipment.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(equipment),
                ],
              ),

              const SizedBox(height: 8),

              // Catégorie et état
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(equipment.category),
                    size: 16,
                    color: _getCategoryColor(equipment.category),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getCategoryLabel(equipment.category),
                    style: TextStyle(
                      color: _getCategoryColor(equipment.category),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    equipment.conditionIcon,
                    size: 16,
                    color: equipment.conditionColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    equipment.conditionText,
                    style: TextStyle(
                      color: equipment.conditionColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                equipment.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 8),

              // Informations détaillées
              if (equipment.serialNumber != null) ...[
                Row(
                  children: [
                    Icon(Icons.qr_code, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'S/N: ${equipment.serialNumber}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (equipment.location != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      equipment.location!,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (equipment.assignedTo != null) ...[
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Assigné à: ${equipment.assignedTo}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (equipment.purchasePrice != null) ...[
                Row(
                  children: [
                    Icon(Icons.euro, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Achat: ${formatCurrency.format(equipment.purchasePrice!)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (equipment.nextMaintenance != null) ...[
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Prochaine maintenance: ${formatDate.format(equipment.nextMaintenance!)}',
                      style: TextStyle(
                        color: equipment.needsMaintenance ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: equipment.needsMaintenance ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              if (equipment.warrantyExpiry != null) ...[
                Row(
                  children: [
                    Icon(Icons.security, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Garantie: ${formatDate.format(equipment.warrantyExpiry!)}',
                      style: TextStyle(
                        color: equipment.isWarrantyExpired ? Colors.red : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: equipment.isWarrantyExpired ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (controller.canManageEquipments) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => Get.to(() => EquipmentForm(equipment: equipment)),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Détails'),
                      onPressed: () => Get.to(() => EquipmentDetail(equipment: equipment)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(Equipment equipment) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: equipment.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: equipment.statusColor.withOpacity(0.5)),
      ),
      child: Text(
        equipment.statusText,
        style: TextStyle(
          color: equipment.statusColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'computer':
        return Icons.computer;
      case 'printer':
        return Icons.print;
      case 'network':
        return Icons.router;
      case 'server':
        return Icons.dns;
      case 'mobile':
        return Icons.phone_android;
      case 'tablet':
        return Icons.tablet;
      case 'monitor':
        return Icons.monitor;
      default:
        return Icons.devices_other;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'computer':
        return Colors.blue;
      case 'printer':
        return Colors.green;
      case 'network':
        return Colors.orange;
      case 'server':
        return Colors.purple;
      case 'mobile':
        return Colors.teal;
      case 'tablet':
        return Colors.indigo;
      case 'monitor':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'computer':
        return 'Ordinateur';
      case 'printer':
        return 'Imprimante';
      case 'network':
        return 'Réseau';
      case 'server':
        return 'Serveur';
      case 'mobile':
        return 'Mobile';
      case 'tablet':
        return 'Tablette';
      case 'monitor':
        return 'Écran';
      default:
        return 'Autre';
    }
  }
}
