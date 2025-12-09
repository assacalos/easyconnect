import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class ReportingValidationPage extends StatefulWidget {
  const ReportingValidationPage({super.key});

  @override
  State<ReportingValidationPage> createState() =>
      _ReportingValidationPageState();
}

class _ReportingValidationPageState extends State<ReportingValidationPage>
    with SingleTickerProviderStateMixin {
  final ReportingController controller = Get.find<ReportingController>();
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _onTabChanged();
    });
    _loadReports();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadReports();
    }
  }

  Future<void> _loadReports() async {
    await controller.loadReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Rapports'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadReports();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'En attente', icon: Icon(Icons.pending)),
            Tab(text: 'Validés', icon: Icon(Icons.check_circle)),
            Tab(text: 'Rejetés', icon: Icon(Icons.cancel)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher par utilisateur...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                          },
                        )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          // Contenu des onglets
          Expanded(
            child: Obx(
              () =>
                  controller.isLoading.value
                      ? const SkeletonSearchResults(itemCount: 6)
                      : _buildReportList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    // Filtrer les rapports selon l'onglet et la recherche
    List<ReportingModel> filteredReports;

    switch (_tabController.index) {
      case 0: // Tous
        filteredReports = controller.reports;
        break;
      case 1: // En attente
        filteredReports =
            controller.reports
                .where((report) => report.status == 'submitted')
                .toList();
        break;
      case 2: // Validés
        filteredReports =
            controller.reports
                .where((report) => report.status == 'approved')
                .toList();
        break;
      case 3: // Rejetés
        filteredReports =
            controller.reports
                .where((report) => report.status == 'rejected')
                .toList();
        break;
      default:
        filteredReports = controller.reports;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filteredReports =
          filteredReports
              .where(
                (report) =>
                    report.userName.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ||
                    report.userRole.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (filteredReports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun rapport trouvé'
                  : 'Aucun rapport correspondant à "$_searchQuery"',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            if (_searchQuery.isNotEmpty) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.clear),
                label: const Text('Effacer la recherche'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredReports.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final report = filteredReports[index];
        return _buildReportCard(context, report);
      },
    );
  }

  Widget _buildReportCard(BuildContext context, ReportingModel report) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(report.status);
    final statusIcon = _getStatusIcon(report.status);
    final statusText = _getStatusText(report.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: () {
          // Naviguer vers la page de détail
          Get.toNamed(
            '/user-reportings/${report.id}',
            arguments: report,
          );
        },
        child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          'Rapport - ${formatDate.format(report.reportDate)}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Utilisateur: ${report.userName}'),
            Text('Rôle: ${report.userRole}'),
            Text('Date: ${formatDate.format(report.reportDate)}'),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations utilisateur
                const Text(
                  'Informations utilisateur',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Utilisateur: ${report.userName}'),
                      Text('Rôle: ${report.userRole}'),
                      Text(
                        'Date du rapport: ${formatDate.format(report.reportDate)}',
                      ),
                      if (report.submittedAt != null)
                        Text(
                          'Soumis le: ${formatDate.format(report.submittedAt!)}',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Métriques
                const Text(
                  'Métriques',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Column(
                    children:
                        report.metrics.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(entry.key),
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                  ),
                ),
                if (report.comments != null && report.comments!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Commentaires',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
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
                ],
                // Note du patron (uniquement pour les rapports soumis)
                if (report.status == 'submitted') ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Note du patron',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          report.patronNote != null &&
                                  report.patronNote!.isNotEmpty
                              ? Icons.edit
                              : Icons.note_add,
                          color: Colors.blue,
                        ),
                        onPressed: () => _showPatronNoteDialog(report),
                        tooltip:
                            report.patronNote != null &&
                                    report.patronNote!.isNotEmpty
                                ? 'Modifier la note'
                                : 'Ajouter une note',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          report.patronNote != null &&
                                  report.patronNote!.isNotEmpty
                              ? Colors.blue.withOpacity(0.1)
                              : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            report.patronNote != null &&
                                    report.patronNote!.isNotEmpty
                                ? Colors.blue
                                : Colors.grey,
                      ),
                    ),
                    child: Text(
                      report.patronNote != null && report.patronNote!.isNotEmpty
                          ? report.patronNote!
                          : 'Aucune note ajoutée. Cliquez sur l\'icône pour ajouter une note.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontStyle:
                            report.patronNote != null &&
                                    report.patronNote!.isNotEmpty
                                ? FontStyle.normal
                                : FontStyle.italic,
                        color:
                            report.patronNote != null &&
                                    report.patronNote!.isNotEmpty
                                ? Colors.black87
                                : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _buildActionButtons(report, statusColor),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReportingModel report, Color statusColor) {
    if (report.status == 'submitted') {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(report),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(report),
                icon: const Icon(Icons.close),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      );
    } else if (report.status == 'approved') {
      // Validé - Afficher seulement info
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green),
            const SizedBox(width: 8),
            Text(
              'Rapport validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (report.status == 'rejected') {
      // Rejeté - Afficher motif du rejet
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cancel, color: Colors.red),
            const SizedBox(width: 8),
            Text(
              'Rapport rejeté',
              style: TextStyle(
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else {
      // Autres statuts
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              'Statut: ${report.status}',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'submitted':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'submitted':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'submitted':
        return 'Soumis';
      case 'approved':
        return 'Approuvé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(ReportingModel report) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce rapport ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveReport(report.id);
        _loadReports();
      },
    );
  }

  void _showRejectDialog(ReportingModel report) {
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
        controller.rejectReport(report.id, reason: commentController.text);
        _loadReports();
      },
    );
  }

  void _showPatronNoteDialog(ReportingModel report) {
    final noteController = TextEditingController(text: report.patronNote ?? '');

    Get.dialog(
      AlertDialog(
        title: const Text('Note du patron'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajoutez une note sur ce rapport avant validation :',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  hintText: 'Entrez votre note sur ce rapport...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final note = noteController.text.trim();
              Get.back();
              controller.addPatronNote(
                report.id,
                note: note.isEmpty ? null : note,
              );
              _loadReports();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
