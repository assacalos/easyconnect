import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/Views/Components/role_based_widget.dart';

class PointageValidationPage extends StatefulWidget {
  const PointageValidationPage({Key? key}) : super(key: key);

  @override
  State<PointageValidationPage> createState() => _PointageValidationPageState();
}

class _PointageValidationPageState extends State<PointageValidationPage> {
  final AttendancePunchService _attendanceService = AttendancePunchService();
  List<AttendancePunchModel> _pointageList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatus = 'pending'; // pending, approved, rejected

  @override
  void initState() {
    super.initState();
    _loadPointages();
  }

  Future<void> _loadPointages() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pointages = await _attendanceService.getAttendances(
        status: _selectedStatus,
      );
      setState(() {
        _pointageList = pointages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Get.snackbar(
        'Erreur',
        'Erreur lors du chargement des pointages: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _validatePointage(AttendancePunchModel pointage) async {
    try {
      final success = await _attendanceService.approveAttendance(pointage.id!);
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Pointage validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadPointages();
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

  Future<void> _rejectPointage(
    AttendancePunchModel pointage,
    String comment,
  ) async {
    try {
      final success = await _attendanceService.rejectAttendance(
        pointage.id!,
        comment,
      );
      if (success['success'] == true) {
        Get.snackbar(
          'Succès',
          'Pointage rejeté avec succès',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        _loadPointages();
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

  void _showValidationDialog(AttendancePunchModel pointage) {
    Get.dialog(
      AlertDialog(
        title: const Text('Valider le pointage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employé: ${pointage.userName}'),
            const SizedBox(height: 8),
            Text(
              'Date: ${pointage.timestamp.day}/${pointage.timestamp.month}/${pointage.timestamp.year}',
            ),
            const SizedBox(height: 8),
            Text(
              'Heure d\'arrivée: ${pointage.timestamp.hour}:${pointage.timestamp.minute}',
            ),
            const SizedBox(height: 8),
            Text(
              'Heure de départ: ${pointage.timestamp.hour}:${pointage.timestamp.minute}',
            ),
            const SizedBox(height: 8),
            Text('Soumis par: ${pointage.userName}'),
            const SizedBox(height: 16),
            const Text('Êtes-vous sûr de vouloir valider ce pointage ?'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _validatePointage(pointage);
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

  void _showRejectionDialog(AttendancePunchModel pointage) {
    final TextEditingController commentController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Rejeter le pointage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Employé: ${pointage.userName}'),
            const SizedBox(height: 8),
            Text(
              'Date: ${pointage.timestamp.day}/${pointage.timestamp.month}/${pointage.timestamp.year}',
            ),
            const SizedBox(height: 8),
            Text(
              'Heure d\'arrivée: ${pointage.timestamp.hour}:${pointage.timestamp.minute}',
            ),
            const SizedBox(height: 8),
            Text('Soumis par: ${pointage.userName}'),
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
              _rejectPointage(pointage, commentController.text.trim());
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

  List<AttendancePunchModel> get _filteredPointages {
    if (_searchQuery.isEmpty) {
      return _pointageList;
    }
    return _pointageList
        .where(
          (pointage) =>
              pointage.userName?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ==
                  true ||
              pointage.timestamp.toString().contains(_searchQuery) ||
              pointage.timestamp.hour.toString().contains(_searchQuery) ||
              pointage.timestamp.minute.toString().contains(_searchQuery) ||
              pointage.timestamp.day.toString().contains(_searchQuery) ||
              pointage.timestamp.month.toString().contains(_searchQuery) ||
              pointage.timestamp.year.toString().contains(_searchQuery),
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
        title: const Text('Validation du Pointage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPointages,
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
                    hintText: 'Rechercher par employé, date ou heure...',
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
                          _loadPointages();
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
                          _loadPointages();
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
                          _loadPointages();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Liste des pointages
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredPointages.isEmpty
                    ? const Center(
                      child: Text(
                        'Aucun pointage trouvé',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                    : ListView.builder(
                      itemCount: _filteredPointages.length,
                      itemBuilder: (context, index) {
                        final pointage = _filteredPointages[index];
                        return _buildPointageCard(pointage);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointageCard(AttendancePunchModel pointage) {
    final statusColor = _getStatusColor(pointage.status);
    final statusText = _getStatusText(pointage.status);
    final statusIcon = _getStatusIcon(pointage.status);

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
                        pointage.userName ?? 'Utilisateur inconnu',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Date: ${pointage.timestamp.day}/${pointage.timestamp.month}/${pointage.timestamp.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Arrivée: ${pointage.timestamp.hour}:${pointage.timestamp.minute}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Départ: ${pointage.timestamp.hour}:${pointage.timestamp.minute}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soumis par: ${pointage.userName}',
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
                    if (pointage.status == 'pending') // En attente
                      const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
            if (pointage.notes != null && pointage.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${pointage.notes}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
            if (pointage.status ==
                'pending') // En attente - Afficher les boutons d'action
              RoleBasedWidget(
                allowedRoles: [Roles.ADMIN, Roles.PATRON],
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showValidationDialog(pointage),
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
                          onPressed: () => _showRejectionDialog(pointage),
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
            if (pointage.status == 'rejected' &&
                pointage.rejectionReason != null) ...[
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
                      pointage.rejectionReason!,
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
