import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/Views/Rh/recruitment_form.dart';
import 'package:intl/intl.dart';

class RecruitmentDetail extends StatelessWidget {
  final RecruitmentRequest request;

  const RecruitmentDetail({super.key, required this.request});

  @override
  Widget build(BuildContext context) {
    final RecruitmentController controller = Get.put(RecruitmentController());
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');
    final formatDateOnly = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(request.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (controller.canManageRecruitment.value && request.isDraft)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Get.to(() => RecruitmentForm(request: request)),
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
              _buildInfoRow(Icons.title, 'Titre', request.title),
              _buildInfoRow(Icons.business, 'Département', request.department),
              _buildInfoRow(Icons.work, 'Poste', request.position),
              _buildInfoRow(Icons.people, 'Nombre de postes', '${request.numberOfPositions}'),
              _buildInfoRow(Icons.schedule, 'Type d\'emploi', request.employmentTypeText),
              _buildInfoRow(Icons.trending_up, 'Niveau d\'expérience', request.experienceLevelText),
              _buildInfoRow(Icons.attach_money, 'Fourchette salariale', request.salaryRange),
              _buildInfoRow(Icons.location_on, 'Localisation', request.location),
              _buildInfoRow(
                Icons.calendar_today,
                'Date d\'échéance',
                formatDateOnly.format(request.applicationDeadline),
                isOverdue: request.applicationDeadline.isBefore(DateTime.now()),
              ),
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
              if (request.publishedAt != null)
                _buildInfoRow(
                  Icons.publish,
                  'Publié le',
                  formatDate.format(request.publishedAt!),
                ),
              if (request.publishedByName != null)
                _buildInfoRow(
                  Icons.person,
                  'Publié par',
                  request.publishedByName!,
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

            // Description du poste
            const SizedBox(height: 16),
            _buildInfoCard('Description du poste', [
              _buildInfoRow(Icons.description, 'Description', request.description),
            ]),

            // Exigences
            const SizedBox(height: 16),
            _buildInfoCard('Exigences et qualifications', [
              _buildInfoRow(Icons.checklist, 'Exigences', request.requirements),
            ]),

            // Responsabilités
            const SizedBox(height: 16),
            _buildInfoCard('Responsabilités principales', [
              _buildInfoRow(Icons.assignment, 'Responsabilités', request.responsibilities),
            ]),

            // Candidatures
            if (request.applications.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildApplicationsCard(),
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
              backgroundColor: _getStatusColor(request.statusColor).withOpacity(0.1),
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
                    request.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    '${request.position} - ${request.department}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
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
        border: Border.all(color: _getStatusColor(request.statusColor).withOpacity(0.5)),
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
    bool? isOverdue,
  }) {
    Color? textColor;
    if (isOverdue == true) {
      textColor = Colors.red;
    } else if (statusColor != null) {
      textColor = statusColor;
    }

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
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Candidatures',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${request.applications.length} candidature${request.applications.length > 1 ? 's' : ''} reçue${request.applications.length > 1 ? 's' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (request.stats != null) ...[
              Row(
                children: [
                  _buildApplicationStat('En attente', '${request.stats!.pendingApplications}', Colors.orange),
                  const SizedBox(width: 12),
                  _buildApplicationStat('Pré-sélectionnés', '${request.stats!.shortlistedApplications}', Colors.blue),
                  const SizedBox(width: 12),
                  _buildApplicationStat('Interviewés', '${request.stats!.interviewedApplications}', Colors.purple),
                  const SizedBox(width: 12),
                  _buildApplicationStat('Embauchés', '${request.stats!.hiredApplications}', Colors.green),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
            ),
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
            if (request.publishedAt != null)
              _buildHistoryItem(
                Icons.publish,
                'Demande publiée',
                DateFormat('dd/MM/yyyy à HH:mm').format(request.publishedAt!),
                Colors.green,
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
            if (request.status == 'closed')
              _buildHistoryItem(
                Icons.close,
                'Demande fermée',
                DateFormat('dd/MM/yyyy à HH:mm').format(request.updatedAt),
                Colors.orange,
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

  Widget _buildActionButtons(RecruitmentController controller) {
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
                if (request.isDraft && controller.canManageRecruitment.value) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.publish),
                      label: const Text('Publier'),
                      onPressed: () => _showPublishDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed: () => Get.to(() => RecruitmentForm(request: request)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (request.isPublished && controller.canApproveRecruitment.value) ...[
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
                if (request.isPublished && controller.canManageRecruitment.value) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                      onPressed: () => _showCloseDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
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
                        backgroundColor: Colors.red,
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
      case 'grey':
        return Colors.grey;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'draft':
        return Icons.edit;
      case 'published':
        return Icons.publish;
      case 'closed':
        return Icons.close;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _shareRequest() {
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showPublishDialog(RecruitmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Publier la demande'),
        content: const Text('Êtes-vous sûr de vouloir publier cette demande de recrutement ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
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

  void _showApproveDialog(RecruitmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Approuver la demande'),
        content: const Text('Êtes-vous sûr de vouloir approuver cette demande de recrutement ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
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

  void _showRejectDialog(RecruitmentController controller) {
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
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                controller.rejectRecruitmentRequest(request, reasonController.text.trim());
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

  void _showCloseDialog(RecruitmentController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('Fermer la demande'),
        content: const Text('Êtes-vous sûr de vouloir fermer cette demande de recrutement ?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Annuler'),
          ),
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

  void _showCancelDialog(RecruitmentController controller) {
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
