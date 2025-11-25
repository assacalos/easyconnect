import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/reporting_model.dart';
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
          ],
        ),
      ),
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
    return Column(
      children: [
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
      ],
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
}
