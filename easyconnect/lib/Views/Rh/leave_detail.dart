import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Models/leave_model.dart';
import 'package:easyconnect/Views/Rh/leave_form.dart';
import 'package:intl/intl.dart';

class LeaveDetail extends StatelessWidget {
  final LeaveRequest request;

  const LeaveDetail({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final LeaveController controller = Get.put(LeaveController());
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');
    final formatDateOnly = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text('Demande de ${request.employeeName}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (controller.canManageLeaves.value && request.isPending)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => LeaveForm(request: request)),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareRequest(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations de base', [
              _buildInfoRow(Icons.person, 'Employé', request.employeeName),
              _buildInfoRow(
                Icons.event,
                'Type de congé',
                request.leaveTypeText,
              ),
              _buildInfoRow(
                Icons.calendar_today,
                'Période',
                '${formatDateOnly.format(request.startDate)} - ${formatDateOnly.format(request.endDate)}',
              ),
              _buildInfoRow(
                Icons.schedule,
                'Durée',
                '${request.totalDays} jour${request.totalDays > 1 ? 's' : ''}',
              ),
              _buildInfoRow(Icons.help_outline, 'Raison', request.reason),
            ]),

            // Statut et approbation
            const SizedBox(height: 16),
            _buildInfoCard('Statut et approbation', [
              _buildInfoRow(
                Icons.info,
                'Statut',
                request.statusText,
                statusColor: _getStatusColor(request.statusColor),
              ),
              if (request.approvedAt != null)
                _buildInfoRow(
                  Icons.check_circle,
                  'Approuvé le',
                  formatDate.format(request.approvedAt!),
                ),
              if (request.approvedByName != null)
                _buildInfoRow(
                  Icons.person,
                  'Approuvé par',
                  request.approvedByName!,
                ),
              if (request.rejectionReason != null)
                _buildInfoRow(
                  Icons.cancel,
                  'Raison du rejet',
                  request.rejectionReason!,
                  statusColor: Colors.red,
                ),
            ]),

            // Commentaires
            if (request.comments != null && request.comments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaires', [
                _buildInfoRow(Icons.comment, 'Commentaires', request.comments!),
              ]),
            ],

            // Justificatifs
            if (request.attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildAttachmentsCard(),
            ],

            // Historique
            const SizedBox(height: 16),
            _buildHistoryCard(),

            const SizedBox(height: 16),

            // Actions
            _buildActionButtons(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getStatusColor(
                request.statusColor,
              ).withOpacity(0.1),
              child: Icon(
                _getStatusIcon(request.status),
                size: 30,
                color: _getStatusColor(request.statusColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Demande de ${request.employeeName}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Créée le ${DateFormat('dd/MM/yyyy à HH:mm').format(request.createdAt)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(request.statusColor).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(request.statusColor).withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(request.status),
            size: 16,
            color: _getStatusColor(request.statusColor),
          ),
          const SizedBox(width: 4),
          Text(
            request.statusText,
            style: TextStyle(
              color: _getStatusColor(request.statusColor),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Justificatifs',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            if (request.attachments.isEmpty)
              const Text('Aucun justificatif')
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: request.attachments.length,
                itemBuilder: (context, index) {
                  return _buildAttachmentItem(request.attachments[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(LeaveAttachment attachment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(_getFileIcon(attachment.fileType), color: Colors.blue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  attachment.fileName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(attachment.fileSize / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadAttachment(attachment),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Historique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            _buildHistoryItem(
              Icons.add,
              'Demande créée',
              DateFormat('dd/MM/yyyy à HH:mm').format(request.createdAt),
              Colors.blue,
            ),
            if (request.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Demande approuvée',
                DateFormat('dd/MM/yyyy à HH:mm').format(request.approvedAt!),
                Colors.green,
              ),
            if (request.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Demande rejetée',
                DateFormat('dd/MM/yyyy à HH:mm').format(request.updatedAt),
                Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    IconData icon,
    String action,
    String date,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LeaveController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (request.isPending && controller.canApproveLeaves.value) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approuver'),
                      onPressed: () => _showApproveDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Rejeter'),
                      onPressed: () => _showRejectDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (request.isPending && controller.canManageLeaves.value) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(() => LeaveForm(request: request)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (request.canCancel) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Annuler'),
                      onPressed: () => _showCancelDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusColor) {
    switch (statusColor) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.schedule;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.block;
      default:
        return Icons.help;
    }
  }

  IconData _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      default:
        return Icons.attach_file;
    }
  }

  void _shareRequest() {
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _downloadAttachment(LeaveAttachment attachment) {
    Get.snackbar(
      'Téléchargement',
      'Téléchargement de ${attachment.fileName}',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showApproveDialog(LeaveController controller) {
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
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
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

  void _showRejectDialog(LeaveController controller) {
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
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
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

  void _showCancelDialog(LeaveController controller) {
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
