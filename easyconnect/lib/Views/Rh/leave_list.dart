import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/Views/Rh/leave_form.dart';
import 'package:easyconnect/Views/Rh/leave_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class LeaveList extends StatelessWidget {
  const LeaveList({super.key});

  @override
  Widget build(BuildContext context) {
    final LeaveController controller = Get.put(LeaveController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Congés'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadLeaveRequests(),
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

              // Liste des demandes
              Expanded(child: _buildLeaveList(controller)),
            ],
          ),
          // Bouton d'ajout uniforme en bas à droite
          if (controller.canManageLeaves.value)
            UniformAddButton(
              onPressed: () => Get.to(() => const LeaveForm()),
              label: 'Nouvelle Demande',
              icon: Icons.event,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(LeaveController controller) {
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
            controller: controller.searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher une demande...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) => controller.searchRequests(value),
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
                    items: controller.statusOptions.map<DropdownMenuItem<String>>((status) {
                      return DropdownMenuItem<String>(
                        value: status['value']!,
                        child: Text(status['label']!),
                      );
                    }).toList(),
                    onChanged: (value) => controller.filterByStatus(value!),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(
                  () => DropdownButtonFormField<String>(
                    value: controller.selectedLeaveType.value,
                    decoration: const InputDecoration(
                      labelText: 'Type',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items: controller.leaveTypeOptions.map<DropdownMenuItem<String>>((type) {
                      return DropdownMenuItem<String>(
                        value: type['value']!,
                        child: Text(type['label']!),
                      );
                    }).toList(),
                    onChanged: (value) => controller.filterByLeaveType(value!),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Bouton pour réinitialiser les filtres
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Réinitialiser'),
                onPressed: () => controller.clearFilters(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(LeaveController controller) {
    return Obx(() {
      if (controller.leaveStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.leaveStats.value!;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total',
                '${stats.totalRequests}',
                Icons.list_alt,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'En attente',
                '${stats.pendingRequests}',
                Icons.schedule,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Approuvés',
                '${stats.approvedRequests}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Rejetés',
                '${stats.rejectedRequests}',
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

  Widget _buildLeaveList(LeaveController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      final filteredRequests = controller.filteredRequests;

      if (filteredRequests.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune demande de congé trouvée',
                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                'Commencez par créer une demande',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          final request = filteredRequests[index];
          return _buildLeaveCard(request, controller);
        },
      );
    });
  }

  Widget _buildLeaveCard(LeaveRequest request, LeaveController controller) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => LeaveDetail(request: request)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec employé et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.employeeName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.leaveTypeText,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusChip(request),
                ],
              ),

              const SizedBox(height: 12),

              // Dates
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${formatDate.format(request.startDate)} - ${formatDate.format(request.endDate)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${request.totalDays} jour${request.totalDays > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Raison
              if (request.reason.isNotEmpty) ...[
                Text(
                  request.reason,
                  style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (request.isPending && controller.canApproveLeaves.value) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(request, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(request, controller),
                    ),
                  ],
                  if (request.isPending && controller.canManageLeaves.value) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed: () => Get.to(() => LeaveForm(request: request)),
                    ),
                  ],
                  if (request.canCancel) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel, size: 16),
                      label: const Text('Annuler'),
                      onPressed: () => _showCancelDialog(request, controller),
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

  Widget _buildStatusChip(LeaveRequest request) {
    Color color;
    switch (request.statusColor) {
      case 'orange':
        color = Colors.orange;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'grey':
        color = Colors.grey;
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
        request.statusText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showApproveDialog(LeaveRequest request, LeaveController controller) {
    controller.commentsController.clear();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir approuver cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller.commentsController,
              decoration: const InputDecoration(
                labelText: 'Commentaires (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.approveLeaveRequest(request);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(LeaveRequest request, LeaveController controller) {
    controller.rejectionReasonController.clear();
    
    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: controller.rejectionReasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.rejectLeaveRequest(request);
              Get.back();
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

  void _showCancelDialog(LeaveRequest request, LeaveController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette demande ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              controller.cancelLeaveRequest(request);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
