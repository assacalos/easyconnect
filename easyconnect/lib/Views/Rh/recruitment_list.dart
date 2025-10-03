import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Views/Rh/recruitment_form.dart';
import 'package:easyconnect/Views/Rh/recruitment_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';

class RecruitmentList extends StatelessWidget {
  const RecruitmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final RecruitmentController controller = Get.put(RecruitmentController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Recrutements'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadRecruitmentRequests(),
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
              Expanded(child: _buildRecruitmentList(controller)),
            ],
          ),
          // Bouton d'ajout uniforme en bas à droite
          if (controller.canManageRecruitment.value)
            UniformAddButton(
              onPressed: () => Get.to(() => const RecruitmentForm()),
              label: 'Nouvelle Demande',
              icon: Icons.work,
            ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(RecruitmentController controller) {
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
                    items:
                        controller.statusOptions.map<DropdownMenuItem<String>>((
                          status,
                        ) {
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
                    value: controller.selectedDepartment.value,
                    decoration: const InputDecoration(
                      labelText: 'Département',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    items:
                        controller.departmentOptions
                            .map<DropdownMenuItem<String>>((dept) {
                              return DropdownMenuItem<String>(
                                value: dept['value']!,
                                child: Text(dept['label']!),
                              );
                            })
                            .toList(),
                    onChanged: (value) => controller.filterByDepartment(value!),
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

  Widget _buildQuickStats(RecruitmentController controller) {
    return Obx(() {
      if (controller.recruitmentStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.recruitmentStats.value!;
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
                'Brouillons',
                '${stats.draftRequests}',
                Icons.edit,
                Colors.grey,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Publiés',
                '${stats.publishedRequests}',
                Icons.publish,
                Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                'Fermés',
                '${stats.closedRequests}',
                Icons.close,
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

  Widget _buildRecruitmentList(RecruitmentController controller) {
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
              Icon(Icons.work_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Aucune demande de recrutement trouvée',
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
          return _buildRecruitmentCard(request, controller);
        },
      );
    });
  }

  Widget _buildRecruitmentCard(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.to(() => RecruitmentDetail(request: request)),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête avec titre et statut
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${request.position} - ${request.department}',
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

              // Informations clés
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${request.numberOfPositions} poste${request.numberOfPositions > 1 ? 's' : ''}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.location,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Type d'emploi et niveau
              Row(
                children: [
                  Icon(Icons.work, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.employmentTypeText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.trending_up, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    request.experienceLevelText,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Échéance
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: ${formatDate.format(request.applicationDeadline)}',
                    style: TextStyle(
                      color:
                          request.applicationDeadline.isBefore(DateTime.now())
                              ? Colors.red
                              : Colors.grey[600],
                      fontSize: 14,
                      fontWeight:
                          request.applicationDeadline.isBefore(DateTime.now())
                              ? FontWeight.bold
                              : FontWeight.normal,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Description
              if (request.description.isNotEmpty) ...[
                Text(
                  request.description,
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
                  if (request.isDraft &&
                      controller.canManageRecruitment.value) ...[
                    TextButton.icon(
                      icon: const Icon(Icons.publish, size: 16),
                      label: const Text('Publier'),
                      onPressed: () => _showPublishDialog(request, controller),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(() => RecruitmentForm(request: request)),
                    ),
                  ],
                  if (request.isPublished &&
                      controller.canApproveRecruitment.value) ...[
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
                  if (request.isPublished &&
                      controller.canManageRecruitment.value) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Fermer'),
                      onPressed: () => _showCloseDialog(request, controller),
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

  Widget _buildStatusChip(RecruitmentRequest request) {
    Color color;
    switch (request.statusColor) {
      case 'grey':
        color = Colors.grey;
        break;
      case 'green':
        color = Colors.green;
        break;
      case 'red':
        color = Colors.red;
        break;
      case 'orange':
        color = Colors.orange;
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

  void _showPublishDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Publier la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir publier cette demande de recrutement ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.publishRecruitmentRequest(request);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir approuver cette demande de recrutement ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.approveRecruitmentRequest(request);
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

  void _showRejectDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter la demande'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Êtes-vous sûr de vouloir rejeter cette demande ?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet *',
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
                controller.rejectRecruitmentRequest(
                  request,
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

  void _showCloseDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Fermer la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir fermer cette demande de recrutement ?',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.closeRecruitmentRequest(request);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.dialog(
      AlertDialog(
        title: const Text('Annuler la demande'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette demande ? Cette action est irréversible.',
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Non')),
          ElevatedButton(
            onPressed: () {
              controller.cancelRecruitmentRequest(request);
              Get.back();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }
}
