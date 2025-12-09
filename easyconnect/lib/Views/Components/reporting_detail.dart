import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:intl/intl.dart';

class ReportingDetail extends StatelessWidget {
  final ReportingModel reporting;

  const ReportingDetail({super.key, required this.reporting});

  @override
  Widget build(BuildContext context) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'fcfa',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Rapport - ${formatDate.format(reporting.reportDate)}'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReporting(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            _buildHeaderCard(formatDate),
            const SizedBox(height: 16),

            // Informations de base
            _buildInfoCard('Informations générales', [
              _buildInfoRow(Icons.person, 'Employé', reporting.userName),
              _buildInfoRow(Icons.badge, 'Rôle', reporting.userRole),
              _buildInfoRow(
                Icons.calendar_today,
                'Date du rapport',
                formatDate.format(reporting.reportDate),
              ),
              _buildInfoRow(Icons.info, 'Statut', _getStatusText()),
            ]),

            // Métriques selon le rôle
            const SizedBox(height: 16),
            _buildMetricsCard(formatCurrency),
            
            // Notes des métriques (si disponibles)
            if (_hasNotes()) ...[
              const SizedBox(height: 16),
              _buildNotesCard(),
            ],

            // Commentaires
            if (reporting.comments != null &&
                reporting.comments!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Commentaires', [
                _buildInfoRow(
                  Icons.comment,
                  'Commentaires',
                  reporting.comments!,
                ),
              ]),
            ],

            // Note du patron
            if (reporting.patronNote != null &&
                reporting.patronNote!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoCard('Note du patron', [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    reporting.patronNote!,
                    style: TextStyle(color: Colors.blue.shade900),
                  ),
                ),
              ]),
            ],

            // Historique
            const SizedBox(height: 16),
            _buildHistoryCard(formatDate),

            // Boutons d'action pour le patron (si le rapport est soumis)
            if (_isPatron() && reporting.status == 'submitted') ...[
              const SizedBox(height: 16),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
    );
  }

  bool _isPatron() {
    final userRole = SessionService.getUserRole();
    return userRole == Roles.PATRON;
  }

  Widget _buildActionButtons() {
    if (!Get.isRegistered<ReportingController>()) {
      return const SizedBox.shrink();
    }
    final controller = Get.find<ReportingController>();

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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveConfirmation(controller),
                    icon: const Icon(Icons.check),
                    label: const Text('Valider'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(controller),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  void _showApproveConfirmation(ReportingController controller) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce rapport ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveReport(reporting.id);
        Get.back(); // Retourner à la page précédente
      },
    );
  }

  void _showRejectDialog(ReportingController controller) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le rapport',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: commentController,
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
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();
        controller.rejectReport(
          reporting.id,
          reason: commentController.text,
        );
        Get.back(); // Retourner à la page précédente
      },
    );
  }

  Widget _buildHeaderCard(DateFormat formatDate) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _getStatusColor().withOpacity(0.1),
              child: Icon(_getStatusIcon(), size: 30, color: _getStatusColor()),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rapport du ${formatDate.format(reporting.reportDate)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildStatusChip(),
                  const SizedBox(height: 8),
                  Text(
                    'Par ${reporting.userName}',
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
        color: _getStatusColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor().withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getStatusIcon(), size: 16, color: _getStatusColor()),
          const SizedBox(width: 4),
          Text(
            _getStatusText(),
            style: TextStyle(
              color: _getStatusColor(),
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

  Widget _buildMetricsCard(NumberFormat formatCurrency) {
    final role = reporting.userRole.toLowerCase();

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Métriques',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 12),
            if (role.contains('commercial')) ...[
              _buildCommercialMetrics(formatCurrency),
            ] else if (role.contains('comptable')) ...[
              _buildComptableMetrics(formatCurrency),
            ] else if (role.contains('technicien')) ...[
              _buildTechnicienMetrics(),
            ] else if (role.contains('ressources humaines') ||
                role.contains('rh')) ...[
              _buildRhMetrics(),
            ] else ...[
              _buildGenericMetrics(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCommercialMetrics(NumberFormat formatCurrency) {
    final metrics = reporting.metrics;
    final formatDate = DateFormat('dd/MM/yyyy');
    
    // Extraire les RDV
    List<RdvInfo> rdvList = [];
    try {
      if (metrics['rdv_list'] != null) {
        if (metrics['rdv_list'] is List) {
          rdvList = (metrics['rdv_list'] as List)
              .map((e) {
                try {
                  if (e is Map) {
                    return RdvInfo.fromJson(Map<String, dynamic>.from(e));
                  }
                  return null;
                } catch (e) {
                  return null;
                }
              })
              .whereType<RdvInfo>()
              .toList();
        }
      }
    } catch (e) {
      // Ignorer les erreurs de parsing
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métriques de base
        _buildMetricRow(
          'Clients prospectés',
          metrics['clients_prospectes']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'RDV obtenus',
          metrics['rdv_obtenus']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Devis créés',
          metrics['devis_crees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Devis acceptés',
          metrics['devis_acceptes']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Nouveaux clients',
          metrics['nouveaux_clients']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Appels effectués',
          metrics['appels_effectues']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Emails envoyés',
          metrics['emails_envoyes']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Visites réalisées',
          metrics['visites_realisees']?.toString() ?? '0',
        ),
        
        // Section RDV
        if (rdvList.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          const Text(
            'RDV obtenus',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 8),
          ...rdvList.map((rdv) => _buildRdvCard(rdv, formatDate)),
        ],
      ],
    );
  }
  
  Widget _buildRdvCard(RdvInfo rdv, DateFormat formatDate) {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (rdv.status.toLowerCase()) {
      case 'realise':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Réalisé';
        break;
      case 'annule':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Annulé';
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.event;
        statusText = 'Planifié';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    rdv.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  formatDate.format(rdv.dateRdv),
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  rdv.heureRdv,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.video_call, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  rdv.typeRdv,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ],
            ),
            if (rdv.notes != null && rdv.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 14, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rdv.notes!,
                        style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComptableMetrics(NumberFormat formatCurrency) {
    final metrics = reporting.metrics;
    return Column(
      children: [
        _buildMetricRow(
          'Factures émises',
          metrics['factures_emises']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Factures payées',
          metrics['factures_payees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Montant facturé',
          formatCurrency.format((metrics['montant_facture'] ?? 0).toDouble()),
        ),
        _buildMetricRow(
          'Montant encaissé',
          formatCurrency.format(
            (metrics['montant_encaissement'] ?? 0).toDouble(),
          ),
        ),
        _buildMetricRow(
          'Bordereaux traités',
          metrics['bordereaux_traites']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Bons de commande traités',
          metrics['bons_commande_traites']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Chiffre d\'affaires',
          formatCurrency.format((metrics['chiffre_affaires'] ?? 0).toDouble()),
        ),
        _buildMetricRow(
          'Clients facturés',
          metrics['clients_factures']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Relances effectuées',
          metrics['relances_effectuees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Encaissements',
          formatCurrency.format((metrics['encaissements'] ?? 0).toDouble()),
        ),
      ],
    );
  }

  Widget _buildTechnicienMetrics() {
    final metrics = reporting.metrics;
    return Column(
      children: [
        _buildMetricRow(
          'Interventions planifiées',
          metrics['interventions_planifiees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Interventions réalisées',
          metrics['interventions_realisees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Interventions annulées',
          metrics['interventions_annulees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Clients visités',
          metrics['clients_visites']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Problèmes résolus',
          metrics['problemes_resolus']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Problèmes en cours',
          metrics['problemes_en_cours']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Temps de travail',
          '${metrics['temps_travail']?.toString() ?? '0'} heures',
        ),
        _buildMetricRow(
          'Déplacements',
          metrics['deplacements']?.toString() ?? '0',
        ),
      ],
    );
  }

  Widget _buildRhMetrics() {
    final metrics = reporting.metrics;
    return Column(
      children: [
        _buildMetricRow(
          'Employés recrutés',
          metrics['employes_recrutes']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Demandes congé traitées',
          metrics['demandes_conge_traitees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Demandes congé approuvées',
          metrics['demandes_conge_approuvees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Demandes congé rejetées',
          metrics['demandes_conge_rejetees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Contrats créés',
          metrics['contrats_crees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Contrats renouvelés',
          metrics['contrats_renouveles']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Pointages validés',
          metrics['pointages_valides']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Entretiens réalisés',
          metrics['entretiens_realises']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Formations organisées',
          metrics['formations_organisees']?.toString() ?? '0',
        ),
        _buildMetricRow(
          'Évaluations effectuées',
          metrics['evaluations_effectuees']?.toString() ?? '0',
        ),
      ],
    );
  }

  Widget _buildGenericMetrics() {
    return Column(
      children:
          reporting.metrics.entries.map((entry) {
            return _buildMetricRow(
              entry.key.replaceAll('_', ' ').toUpperCase(),
              entry.value.toString(),
            );
          }).toList(),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(DateFormat formatDate) {
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
              'Créé',
              formatDate.format(reporting.createdAt),
              Colors.blue,
            ),
            if (reporting.submittedAt != null)
              _buildHistoryItem(
                Icons.send,
                'Soumis',
                formatDate.format(reporting.submittedAt!),
                Colors.orange,
              ),
            if (reporting.approvedAt != null)
              _buildHistoryItem(
                Icons.check_circle,
                'Approuvé',
                formatDate.format(reporting.approvedAt!),
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

  String _getStatusText() {
    switch (reporting.status.toLowerCase()) {
      case 'submitted':
        return 'Soumis';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return reporting.status;
    }
  }

  Color _getStatusColor() {
    switch (reporting.status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'submitted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    switch (reporting.status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'submitted':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  void _shareReporting() {
    Get.snackbar(
      'Partage',
      'Fonctionnalité de partage à implémenter',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
  
  bool _hasNotes() {
    final metrics = reporting.metrics;
    final role = reporting.userRole.toLowerCase();
    
    if (role.contains('commercial')) {
      return metrics['note_clients_prospectes'] != null ||
             metrics['note_rdv_obtenus'] != null ||
             metrics['note_devis_crees'] != null ||
             metrics['note_devis_acceptes'] != null ||
             metrics['note_nouveaux_clients'] != null ||
             metrics['note_appels_effectues'] != null ||
             metrics['note_emails_envoyes'] != null ||
             metrics['note_visites_realisees'] != null;
    } else if (role.contains('comptable')) {
      return metrics['note_factures_emises'] != null ||
             metrics['note_factures_payees'] != null ||
             metrics['note_montant_facture'] != null ||
             metrics['note_montant_encaissement'] != null ||
             metrics['note_bordereaux_traites'] != null ||
             metrics['note_bons_commande_traites'] != null ||
             metrics['note_chiffre_affaires'] != null ||
             metrics['note_clients_factures'] != null ||
             metrics['note_relances_effectuees'] != null ||
             metrics['note_encaissements'] != null;
    } else if (role.contains('technicien')) {
      return metrics['note_interventions_planifiees'] != null ||
             metrics['note_interventions_realisees'] != null ||
             metrics['note_interventions_annulees'] != null ||
             metrics['note_clients_visites'] != null ||
             metrics['note_problemes_resolus'] != null ||
             metrics['note_problemes_en_cours'] != null ||
             metrics['note_temps_travail'] != null ||
             metrics['note_deplacements'] != null;
    } else if (role.contains('ressources humaines') || role.contains('rh')) {
      return metrics['note_employes_recrutes'] != null ||
             metrics['note_demandes_conge_traitees'] != null ||
             metrics['note_contrats_crees'] != null ||
             metrics['note_pointages_valides'] != null ||
             metrics['note_entretiens_realises'] != null ||
             metrics['note_formations_organisees'] != null ||
             metrics['note_evaluations_effectuees'] != null;
    }
    
    return false;
  }
  
  Widget _buildNotesCard() {
    final metrics = reporting.metrics;
    final role = reporting.userRole.toLowerCase();
    
    List<Widget> noteWidgets = [];
    
    if (role.contains('commercial')) {
      _addNoteIfExists(noteWidgets, 'Clients prospectés', metrics['note_clients_prospectes']);
      _addNoteIfExists(noteWidgets, 'RDV obtenus', metrics['note_rdv_obtenus']);
      _addNoteIfExists(noteWidgets, 'Devis créés', metrics['note_devis_crees']);
      _addNoteIfExists(noteWidgets, 'Devis acceptés', metrics['note_devis_acceptes']);
      _addNoteIfExists(noteWidgets, 'Nouveaux clients', metrics['note_nouveaux_clients']);
      _addNoteIfExists(noteWidgets, 'Appels effectués', metrics['note_appels_effectues']);
      _addNoteIfExists(noteWidgets, 'Emails envoyés', metrics['note_emails_envoyes']);
      _addNoteIfExists(noteWidgets, 'Visites réalisées', metrics['note_visites_realisees']);
    } else if (role.contains('comptable')) {
      _addNoteIfExists(noteWidgets, 'Factures émises', metrics['note_factures_emises']);
      _addNoteIfExists(noteWidgets, 'Factures payées', metrics['note_factures_payees']);
      _addNoteIfExists(noteWidgets, 'Montant facturé', metrics['note_montant_facture']);
      _addNoteIfExists(noteWidgets, 'Montant encaissé', metrics['note_montant_encaissement']);
      _addNoteIfExists(noteWidgets, 'Bordereaux traités', metrics['note_bordereaux_traites']);
      _addNoteIfExists(noteWidgets, 'Bons de commande traités', metrics['note_bons_commande_traites']);
      _addNoteIfExists(noteWidgets, 'Chiffre d\'affaires', metrics['note_chiffre_affaires']);
      _addNoteIfExists(noteWidgets, 'Clients facturés', metrics['note_clients_factures']);
      _addNoteIfExists(noteWidgets, 'Relances effectuées', metrics['note_relances_effectuees']);
      _addNoteIfExists(noteWidgets, 'Encaissements', metrics['note_encaissements']);
    } else if (role.contains('technicien')) {
      _addNoteIfExists(noteWidgets, 'Interventions planifiées', metrics['note_interventions_planifiees']);
      _addNoteIfExists(noteWidgets, 'Interventions réalisées', metrics['note_interventions_realisees']);
      _addNoteIfExists(noteWidgets, 'Interventions annulées', metrics['note_interventions_annulees']);
      _addNoteIfExists(noteWidgets, 'Clients visités', metrics['note_clients_visites']);
      _addNoteIfExists(noteWidgets, 'Problèmes résolus', metrics['note_problemes_resolus']);
      _addNoteIfExists(noteWidgets, 'Problèmes en cours', metrics['note_problemes_en_cours']);
      _addNoteIfExists(noteWidgets, 'Temps de travail', metrics['note_temps_travail']);
      _addNoteIfExists(noteWidgets, 'Déplacements', metrics['note_deplacements']);
    } else if (role.contains('ressources humaines') || role.contains('rh')) {
      _addNoteIfExists(noteWidgets, 'Employés recrutés', metrics['note_employes_recrutes']);
      _addNoteIfExists(noteWidgets, 'Demandes congé traitées', metrics['note_demandes_conge_traitees']);
      _addNoteIfExists(noteWidgets, 'Contrats créés', metrics['note_contrats_crees']);
      _addNoteIfExists(noteWidgets, 'Pointages validés', metrics['note_pointages_valides']);
      _addNoteIfExists(noteWidgets, 'Entretiens réalisés', metrics['note_entretiens_realises']);
      _addNoteIfExists(noteWidgets, 'Formations organisées', metrics['note_formations_organisees']);
      _addNoteIfExists(noteWidgets, 'Évaluations effectuées', metrics['note_evaluations_effectuees']);
    }
    
    if (noteWidgets.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildInfoCard('Notes des métriques', noteWidgets);
  }
  
  void _addNoteIfExists(List<Widget> widgets, String label, dynamic note) {
    if (note != null && note.toString().trim().isNotEmpty) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  note.toString(),
                  style: TextStyle(fontSize: 13, color: Colors.blue.shade900),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
