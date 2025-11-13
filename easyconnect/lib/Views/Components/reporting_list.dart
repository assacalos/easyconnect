import 'package:easyconnect/Views/Components/reporting_form.dart';
import 'package:easyconnect/Views/Components/uniform_buttons.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/utils/roles.dart';

class ReportingList extends StatelessWidget {
  const ReportingList({super.key});

  @override
  Widget build(BuildContext context) {
    final reportingController = Get.find<ReportingController>();
    final authController = Get.find<AuthController>();
    final userRole = authController.userAuth.value?.role;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapports'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed:
                () => _showFilterDialog(context, reportingController, userRole),
          ),
        ],
      ),
      body: Stack(
        children: [
          Obx(() {
            if (reportingController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            if (reportingController.reports.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.assessment, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Aucun rapport trouvé',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Créez votre premier rapport',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reportingController.reports.length,
              itemBuilder: (context, index) {
                final report = reportingController.reports[index];
                return _buildReportCard(
                  context,
                  report,
                  reportingController,
                  userRole,
                );
              },
            );
          }),
          // Bouton d'ajout uniforme en bas à droite
          UniformAddButton(
            onPressed: () => Get.to(() => const ReportingForm()),
            label: 'Nouveau Rapport',
            icon: Icons.assessment,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    ReportingModel report,
    ReportingController controller,
    int? userRole,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du rapport
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rapport du ${_formatDate(report.reportDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${report.userName} (${report.userRole})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(report.status),
              ],
            ),

            const SizedBox(height: 16),

            // Métriques selon le rôle
            if (report.userRole.toLowerCase().contains('commercial')) ...[
              _buildCommercialMetrics(report.metrics),
            ] else if (report.userRole.toLowerCase().contains('comptable')) ...[
              _buildComptableMetrics(report.metrics),
            ] else if (report.userRole.toLowerCase().contains(
              'technicien',
            )) ...[
              _buildTechnicienMetrics(report.metrics),
            ],

            const SizedBox(height: 16),

            // Commentaires
            if (report.comments != null && report.comments!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  report.comments!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Actions
            Row(
              children: [
                if (report.status == 'submitted' &&
                    (userRole == Roles.ADMIN || userRole == Roles.PATRON)) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => controller.approveReport(report.id),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approuver'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showReportDetails(context, report),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.deepPurple,
                      side: const BorderSide(color: Colors.deepPurple),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status) {
      case 'submitted':
        color = Colors.blue;
        label = 'Soumis';
        break;
      case 'approved':
        color = Colors.green;
        label = 'Approuvé';
        break;
      default:
        color = Colors.grey;
        label = status;
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildCommercialMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métriques Commerciales:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip(
              'Clients prospectés',
              metrics['clients_prospectes']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'RDV obtenus',
              metrics['rdv_obtenus']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Devis créés',
              metrics['devis_crees']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Devis acceptés',
              metrics['devis_acceptes']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'CA (fcfa)',
              metrics['chiffre_affaires']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Nouveaux clients',
              metrics['nouveaux_clients']?.toString() ?? '0',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComptableMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métriques Comptables:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip(
              'Factures émises',
              metrics['factures_emises']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Factures payées',
              metrics['factures_payees']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Montant facturé (fcfa)',
              metrics['montant_facture']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Montant encaissé (fcfa)',
              metrics['montant_encaissement']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Bordereaux traités',
              metrics['bordereaux_traites']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Bons de commande',
              metrics['bons_commande_traites']?.toString() ?? '0',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTechnicienMetrics(Map<String, dynamic> metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Métriques Techniques:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildMetricChip(
              'Interventions planifiées',
              metrics['interventions_planifiees']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Interventions réalisées',
              metrics['interventions_realisees']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Clients visités',
              metrics['clients_visites']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Problèmes résolus',
              metrics['problemes_resolus']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Temps de travail (h)',
              metrics['temps_travail']?.toString() ?? '0',
            ),
            _buildMetricChip(
              'Déplacements',
              metrics['deplacements']?.toString() ?? '0',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.deepPurple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showFilterDialog(
    BuildContext context,
    ReportingController controller,
    int? userRole,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Filtrer les rapports'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (userRole == Roles.ADMIN || userRole == Roles.PATRON) ...[
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Rôle utilisateur',
                    ),
                    value: controller.selectedUserRole.value,
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child: Text('Tous les rôles'),
                      ),
                      DropdownMenuItem(
                        value: 'Commercial',
                        child: Text('Commercial'),
                      ),
                      DropdownMenuItem(
                        value: 'Comptable',
                        child: Text('Comptable'),
                      ),
                      DropdownMenuItem(
                        value: 'Technicien',
                        child: Text('Technicien'),
                      ),
                    ],
                    onChanged: (value) => controller.filterByUserRole(value),
                  ),
                  const SizedBox(height: 16),
                ],
                ListTile(
                  title: const Text('Période'),
                  subtitle: Text(
                    '${_formatDate(controller.startDate.value)} - ${_formatDate(controller.endDate.value)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(
                        start: controller.startDate.value,
                        end: controller.endDate.value,
                      ),
                    );
                    if (range != null) {
                      controller.updateDateRange(range.start, range.end);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  void _showReportDetails(BuildContext context, ReportingModel report) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Détails du rapport - ${_formatDate(report.reportDate)}',
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Utilisateur: ${report.userName}'),
                  Text('Rôle: ${report.userRole}'),
                  Text('Statut: ${report.status}'),
                  if (report.submittedAt != null)
                    Text('Soumis le: ${_formatDate(report.submittedAt!)}'),
                  if (report.approvedAt != null)
                    Text('Approuvé le: ${_formatDate(report.approvedAt!)}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Métriques:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...report.metrics.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text('${entry.key}: ${entry.value}'),
                    ),
                  ),
                  if (report.comments != null &&
                      report.comments!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Commentaires:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(report.comments!),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fermer'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
