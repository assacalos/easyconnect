import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Views/Components/skeleton_loaders.dart';

class RecruitmentValidationPage extends StatefulWidget {
  const RecruitmentValidationPage({super.key});

  @override
  State<RecruitmentValidationPage> createState() =>
      _RecruitmentValidationPageState();
}

class _RecruitmentValidationPageState extends State<RecruitmentValidationPage>
    with SingleTickerProviderStateMixin {
  final RecruitmentController controller = Get.find<RecruitmentController>();
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
    _loadRecruitments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadRecruitments();
    }
  }

  Future<void> _loadRecruitments() async {
    String? status;
    switch (_tabController.index) {
      case 0: // Tous
        status = null;
        break;
      case 1: // En attente
        status = 'draft';
        break;
      case 2: // Validés
        status = 'published';
        break;
      case 3: // Rejetés
        status = 'cancelled';
        break;
    }

    controller.selectedStatus.value = status ?? 'all';
    await controller.loadRecruitmentRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Recrutements'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadRecruitments();
            },
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
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
                hintText: 'Rechercher par poste, département...',
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
                      : _buildRecruitmentList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentList() {
    // Filtrer les recrutements selon la recherche
    final filteredRecruitments =
        _searchQuery.isEmpty
            ? controller.recruitmentRequests
            : controller.recruitmentRequests
                .where(
                  (recruitment) =>
                      recruitment.position.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      recruitment.department.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ),
                )
                .toList();

    if (filteredRecruitments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun recrutement trouvé'
                  : 'Aucun recrutement correspondant à "$_searchQuery"',
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
      itemCount: filteredRecruitments.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final recruitment = filteredRecruitments[index];
        return _buildRecruitmentCard(context, recruitment);
      },
    );
  }

  Widget _buildRecruitmentCard(
    BuildContext context,
    RecruitmentRequest recruitment,
  ) {
    final formatDate = DateFormat('dd/MM/yyyy');
    final statusColor = _getStatusColor(recruitment.status);
    final statusIcon = _getStatusIcon(recruitment.status);
    final statusText = _getStatusText(recruitment.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          recruitment.position,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Département: ${recruitment.department}'),
            Text(
              'Date limite: ${formatDate.format(recruitment.applicationDeadline)}',
            ),
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
                // Informations générales
                const Text(
                  'Informations générales',
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
                      Text('Titre: ${recruitment.title}'),
                      Text('Poste: ${recruitment.position}'),
                      Text('Département: ${recruitment.department}'),
                      Text('Type: ${recruitment.employmentType}'),
                      Text('Niveau: ${recruitment.experienceLevel}'),
                      Text('Salaire: ${recruitment.salaryRange}'),
                      Text('Localisation: ${recruitment.location}'),
                      Text(
                        'Date limite: ${formatDate.format(recruitment.applicationDeadline)}',
                      ),
                      if (recruitment.description.isNotEmpty)
                        Text('Description: ${recruitment.description}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(recruitment, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    RecruitmentRequest recruitment,
    Color statusColor,
  ) {
    if (recruitment.status.toLowerCase() == 'draft') {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(recruitment),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(recruitment),
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
    } else if (recruitment.status.toLowerCase() == 'published') {
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
              'Recrutement validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (recruitment.status.toLowerCase() == 'cancelled') {
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
              'Recrutement rejeté',
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
              'Statut: ${recruitment.status}',
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
    switch (status.toLowerCase()) {
      case 'draft':
        return Colors.orange;
      case 'published':
        return Colors.blue;
      case 'closed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return Icons.pending;
      case 'published':
        return Icons.publish;
      case 'closed':
        return Icons.lock;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'draft':
        return 'Brouillon';
      case 'published':
        return 'Publié';
      case 'closed':
        return 'Fermé';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Inconnu';
    }
  }

  void _showApproveConfirmation(RecruitmentRequest recruitment) {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce recrutement ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () {
        Get.back();
        controller.approveRecruitmentRequest(recruitment);
        _loadRecruitments();
      },
    );
  }

  void _showRejectDialog(RecruitmentRequest recruitment) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le recrutement',
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
        controller.rejectRecruitmentRequest(
          recruitment,
          commentController.text,
        );
        _loadRecruitments();
      },
    );
  }
}
