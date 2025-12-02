import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Views/Rh/recruitment_form.dart';
import 'package:easyconnect/Views/Rh/recruitment_detail.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class RecruitmentList extends StatelessWidget {
  const RecruitmentList({super.key});

  @override
  Widget build(BuildContext context) {
    final RecruitmentController controller = Get.put(RecruitmentController());

    // Charger les recrutements au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // S'assurer de charger tous les recrutements (sans filtre de statut)
      controller.selectedStatus.value = 'all';
      controller.loadRecruitmentRequests();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Recrutements'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                controller.selectedStatus.value = 'all';
                controller.loadRecruitmentRequests();
              },
              tooltip: 'Actualiser',
            ),
          ],
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
                _buildRecruitmentList('pending', controller), // En attente
                _buildRecruitmentList('approved', controller), // Validés
                _buildRecruitmentList('rejected', controller), // Rejetés
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
      ),
    );
  }

  Widget _buildRecruitmentList(
    String status,
    RecruitmentController controller,
  ) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const SkeletonSearchResults(itemCount: 6);
      }

      // Filtrer selon le statut
      List<RecruitmentRequest> recruitmentList;
      if (status == 'pending') {
        // En attente = published (publié mais pas encore validé)
        recruitmentList =
            controller.recruitmentRequests
                .where((r) => r.status == 'published')
                .toList();
      } else if (status == 'approved') {
        // Validés = closed (fermés avec succès)
        recruitmentList =
            controller.recruitmentRequests
                .where((r) => r.status == 'closed')
                .toList();
      } else if (status == 'rejected') {
        // Rejetés = cancelled (annulés)
        recruitmentList =
            controller.recruitmentRequests
                .where((r) => r.status == 'cancelled')
                .toList();
      } else {
        recruitmentList = [];
      }

      if (recruitmentList.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                status == 'pending'
                    ? Icons.pending
                    : status == 'approved'
                    ? Icons.check_circle
                    : Icons.cancel,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                status == 'pending'
                    ? 'Aucun recrutement en attente'
                    : status == 'approved'
                    ? 'Aucun recrutement validé'
                    : 'Aucun recrutement rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recruitmentList.length,
        itemBuilder: (context, index) {
          final request = recruitmentList[index];
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

    Color statusColor;
    IconData statusIcon;

    if (request.status == 'published') {
      statusColor = Colors.orange;
      statusIcon = Icons.pending;
    } else if (request.status == 'closed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (request.status == 'cancelled') {
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    } else {
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
          request.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${request.position} - ${request.department}'),
            Text('Échéance: ${formatDate.format(request.applicationDeadline)}'),
            Text(
              'Status: ${request.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (request.status == 'cancelled' &&
                (request.rejectionReason != null &&
                    request.rejectionReason!.isNotEmpty)) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.report, size: 14, color: Colors.red),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Raison du rejet: ${request.rejectionReason}',
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: _buildActionButton(request, controller),
        onTap: () => Get.to(() => RecruitmentDetail(request: request)),
      ),
    );
  }

  Widget _buildActionButton(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    if (request.isPublished && controller.canApproveRecruitment.value) {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'approve', child: Text('Valider')),
              const PopupMenuItem(value: 'reject', child: Text('Rejeter')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'approve':
              _showApproveDialog(request, controller);
              break;
            case 'reject':
              _showRejectDialog(request, controller);
              break;
          }
        },
      );
    }

    if (request.isDraft && controller.canManageRecruitment.value) {
      return PopupMenuButton(
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifier')),
              const PopupMenuItem(value: 'publish', child: Text('Publier')),
              const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
        onSelected: (value) {
          switch (value) {
            case 'edit':
              Get.to(() => RecruitmentForm(request: request));
              break;
            case 'publish':
              _showPublishDialog(request, controller);
              break;
            case 'delete':
              _showDeleteConfirmation(request, controller);
              break;
          }
        },
      );
    }

    return const SizedBox.shrink();
  }

  void _showPublishDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous publier cette demande de recrutement ?',
      textConfirm: 'Publier',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.publishRecruitmentRequest(request);
      },
    );
  }

  void _showApproveDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider cette demande de recrutement ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveRecruitmentRequest(request);
      },
    );
  }

  void _showRejectDialog(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    final reasonController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter la demande',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Êtes-vous sûr de vouloir rejeter cette demande ?'),
          const SizedBox(height: 16),
          TextField(
            controller: reasonController,
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
        if (reasonController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectRecruitmentRequest(
          request,
          reasonController.text.trim(),
        );
      },
    );
  }

  void _showDeleteConfirmation(
    RecruitmentRequest request,
    RecruitmentController controller,
  ) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous supprimer cette demande de recrutement ?',
      textConfirm: 'Supprimer',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.cancelRecruitmentRequest(request);
      },
    );
  }
}
