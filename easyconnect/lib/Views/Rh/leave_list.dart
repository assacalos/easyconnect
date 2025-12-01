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

    // Charger les congés au chargement de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLeaveRequests();
    });

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Congés'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => controller.loadLeaveRequests(),
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
                _buildLeaveList('pending', controller), // En attente
                _buildLeaveList('approved', controller), // Validés
                _buildLeaveList('rejected', controller), // Rejetés
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
      ),
    );
  }

  Widget _buildLeaveList(String status, LeaveController controller) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      // Filtrer selon le statut
      final leaveList =
          controller.leaveRequests.where((l) => l.status == status).toList();

      if (leaveList.isEmpty) {
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
                    ? 'Aucun congé en attente'
                    : status == 'approved'
                    ? 'Aucun congé validé'
                    : 'Aucun congé rejeté',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: leaveList.length,
        itemBuilder: (context, index) {
          final request = leaveList[index];
          return _buildLeaveCard(request, controller);
        },
      );
    });
  }

  Widget _buildLeaveCard(LeaveRequest request, LeaveController controller) {
    final formatDate = DateFormat('dd/MM/yyyy');

    Color statusColor;
    IconData statusIcon;

    switch (request.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
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
          request.employeeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${request.leaveTypeText}'),
            Text(
              'Date: ${formatDate.format(request.startDate)} - ${formatDate.format(request.endDate)}',
            ),
            Text(
              'Durée: ${request.totalDays} jour${request.totalDays > 1 ? 's' : ''}',
            ),
            Text(
              'Status: ${request.statusText}',
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w500),
            ),
            if (request.status == 'rejected' &&
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
        onTap: () => Get.to(() => LeaveDetail(request: request)),
      ),
    );
  }

  Widget _buildActionButton(LeaveRequest request, LeaveController controller) {
    if (request.isPending && controller.canApproveLeaves.value) {
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

    if (request.isPending && controller.canManageLeaves.value) {
      return IconButton(
        icon: const Icon(Icons.edit),
        onPressed: () => Get.to(() => LeaveForm(request: request)),
        tooltip: 'Modifier',
      );
    }

    return const SizedBox.shrink();
  }

  void _showApproveDialog(LeaveRequest request, LeaveController controller) {
    controller.commentsController.clear();

    Get.defaultDialog(
      title: 'Approuver la demande',
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
      textConfirm: 'Approuver',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveLeaveRequest(request);
      },
    );
  }

  void _showRejectDialog(LeaveRequest request, LeaveController controller) {
    controller.rejectionReasonController.clear();

    Get.defaultDialog(
      title: 'Rejeter la demande',
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
      textConfirm: 'Rejeter',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        if (controller.rejectionReasonController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectLeaveRequest(request);
      },
    );
  }
}
