import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Models/intervention_model.dart';
import 'package:easyconnect/Views/Technicien/intervention_form.dart';
import 'package:intl/intl.dart';

class InterventionDetail extends StatelessWidget {
  final Intervention intervention;

  const InterventionDetail({super.key, required this.intervention});

  @override
  Widget build(BuildContext context) {
    final InterventionController controller = Get.put(InterventionController());
    final formatCurrency = NumberFormat.currency(locale: 'fr_FR', symbol: '€');
    final formatDate = DateFormat('dd/MM/yyyy à HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(intervention.title),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          if (controller.canManageInterventions &&
              intervention.status == 'pending')
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed:
                  () => Get.to(
                    () => InterventionForm(intervention: intervention),
                  ),
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareIntervention(),
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
              _buildInfoRow(Icons.title, 'Titre', intervention.title),
              _buildInfoRow(Icons.category, 'Type', intervention.typeText),
              _buildInfoRow(
                Icons.priority_high,
                'Priorité',
                intervention.priorityText,
              ),
              _buildInfoRow(
                Icons.description,
                'Description',
                intervention.description,
              ),
            ]),

            // Informations de planification
            const SizedBox(height: 16),
            _buildInfoCard('Planification', [
              _buildInfoRow(
                Icons.calendar_today,
                'Date programmée',
                DateFormat('dd/MM/yyyy').format(intervention.scheduledDate),
              ),
              if (intervention.startDate != null)
                _buildInfoRow(
                  Icons.play_arrow,
                  'Date de début',
                  formatDate.format(intervention.startDate!),
                ),
              if (intervention.endDate != null)
                _buildInfoRow(
                  Icons.stop,
                  'Date de fin',
                  formatDate.format(intervention.endDate!),
                ),
              if (intervention.estimatedDuration != null)
                _buildInfoRow(
                  Icons.schedule,
                  'Durée estimée',
                  '${intervention.estimatedDuration!.toStringAsFixed(1)}h',
                ),
              if (intervention.actualDuration != null)
                _buildInfoRow(
                  Icons.timer,
                  'Durée réelle',
                  '${intervention.actualDuration!.toStringAsFixed(1)}h',
                ),
            ]),

            // Informations client
            if (intervention.clientName != null ||
                intervention.location != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations client', [
                if (intervention.clientName != null)
                  _buildInfoRow(Icons.person, 'Nom', intervention.clientName!),
                if (intervention.clientPhone != null)
                  _buildInfoRow(
                    Icons.phone,
                    'Téléphone',
                    intervention.clientPhone!,
                  ),
                if (intervention.clientEmail != null)
                  _buildInfoRow(
                    Icons.email,
                    'Email',
                    intervention.clientEmail!,
                  ),
                if (intervention.location != null)
                  _buildInfoRow(
                    Icons.location_on,
                    'Localisation',
                    intervention.location!,
                  ),
              ]),
            ],

            // Informations techniques
            if (intervention.equipment != null ||
                intervention.problemDescription != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Informations techniques', [
                if (intervention.equipment != null)
                  _buildInfoRow(
                    Icons.build,
                    'Équipement',
                    intervention.equipment!,
                  ),
                if (intervention.problemDescription != null)
                  _buildInfoRow(
                    Icons.warning,
                    'Problème',
                    intervention.problemDescription!,
                  ),
                if (intervention.solution != null)
                  _buildInfoRow(
                    Icons.check_circle,
                    'Solution',
                    intervention.solution!,
                  ),
              ]),
            ],

            // Coût
            if (intervention.cost != null) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Coût', [
                _buildInfoRow(
                  Icons.euro,
                  'Coût',
                  formatCurrency.format(intervention.cost!),
                ),
              ]),
            ],

            // Notes
            if (intervention.notes != null &&
                intervention.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes', [
                _buildInfoRow(Icons.note, 'Notes', intervention.notes!),
              ]),
            ],

            // Motif du rejet
            if (intervention.status == 'rejected' &&
                intervention.rejectionReason != null &&
                intervention.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Motif du rejet', [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    intervention.rejectionReason!,
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                ),
              ]),
            ],

            // Notes de fin
            if (intervention.completionNotes != null &&
                intervention.completionNotes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Notes de fin', [
                _buildInfoRow(
                  Icons.done_all,
                  'Notes de fin',
                  intervention.completionNotes!,
                ),
              ]),
            ],

            // Pièces jointes
            if (intervention.attachments != null &&
                intervention.attachments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Pièces jointes', [
                for (String attachment in intervention.attachments!)
                  _buildInfoRow(Icons.attach_file, 'Fichier', attachment),
              ]),
            ],

            // Historique des actions
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
              backgroundColor: intervention.statusColor.withOpacity(0.1),
              child: Icon(
                intervention.statusIcon,
                size: 30,
                color: intervention.statusColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    intervention.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        intervention.typeIcon,
                        size: 16,
                        color: intervention.typeColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intervention.typeText,
                        style: TextStyle(
                          color: intervention.typeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        intervention.priorityIcon,
                        size: 16,
                        color: intervention.priorityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        intervention.priorityText,
                        style: TextStyle(
                          color: intervention.priorityColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Créé le ${DateFormat('dd/MM/yyyy').format(intervention.createdAt)}',
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
        color: intervention.statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: intervention.statusColor.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            intervention.statusIcon,
            size: 16,
            color: intervention.statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            intervention.statusText,
            style: TextStyle(
              color: intervention.statusColor,
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

  Widget _buildInfoRow(IconData icon, String label, String value) {
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
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
              'Créée',
              DateFormat('dd/MM/yyyy à HH:mm').format(intervention.createdAt),
              Colors.blue,
            ),
            if (intervention.status == 'approved' &&
                intervention.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvée',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(DateTime.parse(intervention.approvedAt!)),
                Colors.green,
              ),
            if (intervention.status == 'rejected')
              _buildHistoryItem(
                Icons.cancel,
                'Rejetée',
                DateFormat('dd/MM/yyyy à HH:mm').format(intervention.updatedAt),
                Colors.red,
              ),
            if (intervention.status == 'in_progress' &&
                intervention.startDate != null)
              _buildHistoryItem(
                Icons.play_arrow,
                'Démarrée',
                DateFormat(
                  'dd/MM/yyyy à HH:mm',
                ).format(intervention.startDate!),
                Colors.purple,
              ),
            if (intervention.status == 'completed' &&
                intervention.endDate != null)
              _buildHistoryItem(
                Icons.done_all,
                'Terminée',
                DateFormat('dd/MM/yyyy à HH:mm').format(intervention.endDate!),
                Colors.green,
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

  Widget _buildActionButtons(InterventionController controller) {
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
                if (intervention.status == 'pending' &&
                    controller.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text('Modifier'),
                      onPressed:
                          () => Get.to(
                            () => InterventionForm(intervention: intervention),
                          ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'approved' &&
                    controller.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Démarrer'),
                      onPressed: () => _showStartDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'in_progress' &&
                    controller.canManageInterventions) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.stop),
                      label: const Text('Terminer'),
                      onPressed: () => _showCompleteDialog(controller),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (intervention.status == 'pending' &&
                    controller.canApproveInterventions) ...[
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
                if (intervention.status == 'completed') ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility),
                      label: const Text('Voir détails'),
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey,
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

  void _shareIntervention() {
    // Implémentation du partage
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _showStartDialog(InterventionController controller) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Démarrer l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir démarrer cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
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
              controller.notesController.text = notesController.text;
              controller.startIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Démarrer'),
          ),
        ],
      ),
    );
  }

  void _showCompleteDialog(InterventionController controller) {
    final solutionController = TextEditingController();
    final completionNotesController = TextEditingController();
    final actualDurationController = TextEditingController();
    final costController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Terminer l\'intervention'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: solutionController,
                decoration: const InputDecoration(
                  labelText: 'Solution appliquée *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: completionNotesController,
                decoration: const InputDecoration(
                  labelText: 'Notes de fin (optionnel)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: actualDurationController,
                decoration: const InputDecoration(
                  labelText: 'Durée réelle (heures)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                decoration: const InputDecoration(
                  labelText: 'Coût (€)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              controller.solutionController.text = solutionController.text;
              controller.completionNotesController.text =
                  completionNotesController.text;
              controller.actualDurationController.text =
                  actualDurationController.text;
              controller.costController.text = costController.text;
              controller.completeIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _showApproveDialog(InterventionController controller) {
    final notesController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Approuver l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir approuver cette intervention ?',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
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
              controller.notesController.text = notesController.text;
              controller.approveIntervention(intervention);
              Get.back();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approuver'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(InterventionController controller) {
    final reasonController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter l\'intervention'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Veuillez indiquer la raison du rejet :'),
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
                controller.rejectIntervention(
                  intervention,
                  reasonController.text.trim(),
                );
                Get.back();
              } else {
                Get.snackbar('Erreur', 'Veuillez indiquer la raison du rejet');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
  }
}
