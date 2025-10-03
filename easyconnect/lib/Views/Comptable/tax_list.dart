import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Models/tax_model.dart';

class TaxList extends StatelessWidget {
  const TaxList({super.key});

  @override
  Widget build(BuildContext context) {
    print('🏗️ TaxList: build() appelé');

    final TaxController controller = Get.find<TaxController>();
    print('✅ TaxList: TaxController trouvé');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Taxes et Impôts'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadTaxes(),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              print('🐛 DEBUG: État du contrôleur');
              print('📊 allTaxes.length: ${controller.allTaxes.length}');
              print('📊 taxes.length: ${controller.taxes.length}');
              print('📊 selectedStatus: ${controller.selectedStatus.value}');
              print('📊 searchQuery: "${controller.searchQuery.value}"');
              print('📊 isLoading: ${controller.isLoading.value}');
              controller.loadTaxes();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistiques rapides
          _buildQuickStats(controller),

          // Onglets de statut
          _buildStatusTabs(controller),

          // Liste des taxes
          Expanded(child: _buildTaxList(controller)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(controller),
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickStats(TaxController controller) {
    return Obx(() {
      if (controller.taxStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.taxStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                stats.total.toString(),
                Icons.receipt,
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
                'Validés',
                stats.validated.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Rejetés',
                stats.rejected.toString(),
                Icons.cancel,
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

  Widget _buildStatusTabs(TaxController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: _buildStatusTab('Tous', 'all', controller)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatusTab('En attente', 'pending', controller)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatusTab('Validés', 'validated', controller)),
          const SizedBox(width: 8),
          Expanded(child: _buildStatusTab('Rejetés', 'rejected', controller)),
        ],
      ),
    );
  }

  Widget _buildStatusTab(
    String label,
    String status,
    TaxController controller,
  ) {
    return Obx(() {
      final isSelected = controller.selectedStatus.value == status;
      return GestureDetector(
        onTap: () => controller.filterByStatus(status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.deepPurple : Colors.grey[300]!,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTaxList(TaxController controller) {
    return Obx(() {
      print('🔄 TaxList: _buildTaxList() - Obx rebuild');
      print('⏳ TaxList: isLoading = ${controller.isLoading.value}');
      print('📊 TaxList: taxes.length = ${controller.taxes.length}');

      if (controller.isLoading.value) {
        print('⏳ TaxList: Affichage du loading...');
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.taxes.isEmpty) {
        print('📭 TaxList: Aucune taxe trouvée');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune taxe trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par ajouter une taxe',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      print(
        '📋 TaxList: Affichage de la liste avec ${controller.taxes.length} taxes',
      );
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.taxes.length,
        itemBuilder: (context, index) {
          final tax = controller.taxes[index];
          print('💰 TaxList: Affichage de la taxe $index: ${tax.name}');
          return _buildTaxCard(tax, controller);
        },
      );
    });
  }

  Widget _buildTaxCard(Tax tax, TaxController controller) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTaxDetails(tax, controller),
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
                      tax.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildStatusChip(tax),
                ],
              ),

              const SizedBox(height: 8),

              // Informations de la taxe
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Montant: ${tax.amount.toStringAsFixed(2)} €',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Date: ${tax.dueDate.day}/${tax.dueDate.month}/${tax.dueDate.year}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              if (tax.description != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.description, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tax.description ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                  if (tax.status == 'pending') ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Valider'),
                      onPressed: () => _showValidateDialog(tax, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(tax, controller),
                    ),
                  ],
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Modifier'),
                    onPressed: () => _showEditDialog(tax, controller),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Supprimer'),
                    onPressed: () => _showDeleteDialog(tax, controller),
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

  Widget _buildStatusChip(Tax tax) {
    Color color;
    String statusText;

    switch (tax.status) {
      case 'pending':
        color = Colors.orange;
        statusText = 'En attente';
        break;
      case 'validated':
        color = Colors.green;
        statusText = 'Validé';
        break;
      case 'rejected':
        color = Colors.red;
        statusText = 'Rejeté';
        break;
      default:
        color = Colors.grey;
        statusText = 'Inconnu';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Dialogues
  void _showCreateDialog(TaxController controller) {
    Get.toNamed('/taxes/new');
  }

  void _showTaxDetails(Tax tax, TaxController controller) {
    Get.toNamed('/taxes/${tax.id}', arguments: tax);
  }

  void _showValidateDialog(Tax tax, TaxController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider la taxe'),
        content: const Text('Êtes-vous sûr de vouloir valider cette taxe ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.validateTax(tax);
              Get.back();
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Tax tax, TaxController controller) {
    final reasonController = TextEditingController();
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la taxe'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Motif du rejet :'),
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
                controller.rejectTax(tax, reasonController.text.trim());
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

  void _showEditDialog(Tax tax, TaxController controller) {
    Get.toNamed('/taxes/${tax.id}/edit', arguments: tax);
  }

  void _showDeleteDialog(Tax tax, TaxController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Supprimer la taxe'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${tax.name} ?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.deleteTax(tax);
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
}
