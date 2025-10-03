import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/recruitment_model.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class RecruitmentValidationPage extends StatefulWidget {
  const RecruitmentValidationPage({Key? key}) : super(key: key);

  @override
  State<RecruitmentValidationPage> createState() =>
      _RecruitmentValidationPageState();
}

class _RecruitmentValidationPageState extends State<RecruitmentValidationPage> {
  final RecruitmentService _recruitmentService = RecruitmentService();
  List<RecruitmentRequest> _recruitmentList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadRecruitments();
  }

  Future<void> _loadRecruitments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final recruitments = await _recruitmentService.getAllRecruitmentRequests(
        status: _selectedStatus,
      );
      setState(() {
        _recruitmentList = recruitments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des recrutements: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validateRecruitment(RecruitmentRequest recruitment) async {
    try {
      final success = await _recruitmentService.approveRecruitmentRequest(
        recruitment.id!,
      );
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Recrutement validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadRecruitments();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la validation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _rejectRecruitment(
    RecruitmentRequest recruitment,
    String comment,
  ) async {
    try {
      final success = await _recruitmentService.rejectRecruitmentRequest(
        recruitment.id!,
        rejectionReason: comment,
      );
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Recrutement rejeté avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadRecruitments();
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _showValidationDialog(RecruitmentRequest recruitment) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le recrutement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidat: ${recruitment.applications.first.user.fullName}'),
            const SizedBox(height: 8),
            Text('Poste: ${recruitment.position}'),
            const SizedBox(height: 8),
            Text('Département: ${recruitment.department}'),
            const SizedBox(height: 8),
            Text(
              'Salaire proposé: ${recruitment.applications.first.user.salary} FCFA',
            ),
            const SizedBox(height: 8),
            Text('Soumis par: ${recruitment.applications.first.user.fullName}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce recrutement ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validateRecruitment(recruitment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(RecruitmentRequest recruitment) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le recrutement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidat: ${recruitment.applications.first.user.fullName}'),
            const SizedBox(height: 8),
            Text('Poste: ${recruitment.position}'),
            const SizedBox(height: 8),
            Text('Département: ${recruitment.department}'),
            const SizedBox(height: 8),
            Text('Soumis par: ${recruitment.applications.first.user.fullName}'),
            const SizedBox(height: 16),
            const Text('Motif du rejet (obligatoire):'),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'Saisissez le motif du rejet...',
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
              if (commentController.text.trim().isEmpty) {
                Get.snackbar(
                  'Erreur',
                  'Veuillez saisir un motif de rejet',
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }
              Get.back();
              _rejectRecruitment(recruitment, commentController.text.trim());
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

  List<RecruitmentRequest> get _filteredRecruitments {
    if (_searchQuery.isEmpty) {
      return _recruitmentList;
    }
    return _recruitmentList
        .where(
          (recruitment) =>
              recruitment.applications.first.user.fullName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              recruitment.position.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              recruitment.department.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'approved':
        return 'Validé';
      case 'rejected':
        return 'Rejeté';
      default:
        return 'Inconnu';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.access_time;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation du Recrutement'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecruitments,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Barre de recherche
                TextField(
                  decoration: const InputDecoration(
                    hintText:
                        'Rechercher par candidat, poste ou département...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                // Filtres de statut
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: const Text('En attente'),
                        selected: _selectedStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'pending';
                          });
                          _loadRecruitments();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Validés'),
                        selected: _selectedStatus == 'approved',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'approved';
                          });
                          _loadRecruitments();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilterChip(
                        label: const Text('Rejetés'),
                        selected: _selectedStatus == 'rejected',
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = 'rejected';
                          });
                          _loadRecruitments();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des recrutements
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredRecruitments.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun recrutement trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredRecruitments.length,
                      itemBuilder: (context, index) {
                        final recruitment = _filteredRecruitments[index];
                        return _buildRecruitmentCard(recruitment);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentCard(RecruitmentRequest recruitment) {
    final statusColor = _getStatusColor(recruitment.status);
    final statusText = _getStatusText(recruitment.status);
    final statusIcon = _getStatusIcon(recruitment.status);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recruitment.applications.first.user.fullName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Poste: ${recruitment.position}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Département: ${recruitment.department}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Salaire proposé: ${recruitment.applications.first.user.salary} FCFA',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${recruitment.applications.first.user.fullName}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (recruitment.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (recruitment.applications.first.notes != null &&
                recruitment.applications.first.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${recruitment.applications.first.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (recruitment.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(recruitment),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Valider'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showRejectionDialog(recruitment),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Rejeter'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (recruitment.status == 'rejected' &&
                recruitment.applications.first.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Motif du rejet:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recruitment.applications.first.rejectionReason ?? '',
                      style: const TextStyle(color: Colors.red),
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
}
