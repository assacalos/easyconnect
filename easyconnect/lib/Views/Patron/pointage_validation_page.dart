import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:intl/intl.dart';

class PointageValidationPage extends StatefulWidget {
  const PointageValidationPage({super.key});

  @override
  State<PointageValidationPage> createState() => _PointageValidationPageState();
}

class _PointageValidationPageState extends State<PointageValidationPage>
    with SingleTickerProviderStateMixin {
  final AttendanceController controller = Get.find<AttendanceController>();
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
    // Charger les données après que le widget soit monté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAttendanceData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      _loadAttendanceData();
    }
  }

  Future<void> _loadAttendanceData() async {
    print('🔄 PointageValidationPage._loadAttendanceData - Début');
    try {
      await controller.loadAttendanceData();
      print('✅ PointageValidationPage._loadAttendanceData - Terminé');
      print(
        '📊 Nombre de pointages après chargement: ${controller.attendanceHistory.length}',
      );
      // Forcer la mise à jour de l'UI
      setState(() {});
    } catch (e) {
      print('❌ Erreur lors du chargement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des Pointages'),
        backgroundColor: Colors.blueGrey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadAttendanceData();
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
                hintText: 'Rechercher par nom d\'utilisateur...',
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
            child: Obx(() {
              // Forcer l'observation de attendanceHistory
              controller
                  .attendanceHistory
                  .length; // Accès pour déclencher la réactivité
              return controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : _buildAttendanceList();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceList() {
    // Filtrer les pointages selon l'onglet et la recherche
    print('🔍 _buildAttendanceList - Onglet: ${_tabController.index}');
    print(
      '🔍 Nombre total de pointages: ${controller.attendanceHistory.length}',
    );

    List<AttendancePunchModel> filteredPointages;

    switch (_tabController.index) {
      case 0: // Tous
        filteredPointages = controller.attendanceHistory;
        print('📋 Onglet "Tous": ${filteredPointages.length} pointages');
        for (var p in filteredPointages) {
          print('   - ID: ${p.id}, Status: "${p.status}", User: ${p.userName}');
        }
        break;
      case 1: // En attente
        print(
          '🔍 Filtrage "En attente" - Total: ${controller.attendanceHistory.length}',
        );
        for (var p in controller.attendanceHistory) {
          print(
            '   - ID: ${p.id}, Status: "${p.status}" (lowercase: "${p.status.toLowerCase()}"), User: ${p.userName}',
          );
        }
        filteredPointages =
            controller.attendanceHistory.where((pointage) {
              final status = pointage.status.toLowerCase();
              final matches = status == 'pending';
              if (matches) {
                print(
                  '✅ Pointage ${pointage.id} correspond au filtre "pending"',
                );
              }
              return matches;
            }).toList();
        print(
          '📋 Onglet "En attente": ${filteredPointages.length} pointages filtrés',
        );
        break;
      case 2: // Validés
        filteredPointages =
            controller.attendanceHistory
                .where(
                  (pointage) => pointage.status.toLowerCase() == 'approved',
                )
                .toList();
        break;
      case 3: // Rejetés
        filteredPointages =
            controller.attendanceHistory
                .where(
                  (pointage) => pointage.status.toLowerCase() == 'rejected',
                )
                .toList();
        break;
      default:
        filteredPointages = controller.attendanceHistory;
    }

    // Appliquer la recherche
    if (_searchQuery.isNotEmpty) {
      filteredPointages =
          filteredPointages
              .where(
                (pointage) => (pointage.userName ?? '').toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
    }

    if (filteredPointages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.access_time, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun pointage trouvé'
                  : 'Aucun pointage correspondant à "$_searchQuery"',
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
      itemCount: filteredPointages.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final pointage = filteredPointages[index];
        return _buildPointageCard(context, pointage);
      },
    );
  }

  Widget _buildPointageCard(
    BuildContext context,
    AttendancePunchModel pointage,
  ) {
    final formatDateTime = DateFormat('dd/MM/yyyy HH:mm');
    final statusColor = _getStatusColor(pointage.status);
    final statusIcon = _getStatusIcon(pointage.status);
    final statusText = _getStatusText(pointage.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          pointage.userName ?? 'Utilisateur inconnu',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Type: ${pointage.type}'),
            Text('Date: ${formatDateTime.format(pointage.timestamp)}'),
            Text('Lieu: ${pointage.address}'),
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
                // Informations employé
                const Text(
                  'Informations employé',
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
                      Text('Employé: ${pointage.userName ?? 'Inconnu'}'),
                      Text('ID Employé: ${pointage.userId}'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Détails du pointage
                const Text(
                  'Détails du pointage',
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
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [const Text('Type:'), Text(pointage.type)],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Heure:'),
                          Text(formatDateTime.format(pointage.timestamp)),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Lieu:'),
                          Text(pointage.address ?? 'Inconnu'),
                        ],
                      ),
                      if (pointage.photoPath != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Photo:'),
                            Text(pointage.photoPath!),
                          ],
                        ),
                      if (pointage.notes != null && pointage.notes!.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            const Text(
                              'Notes:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(pointage.notes!),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(pointage, statusColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(AttendancePunchModel pointage, Color statusColor) {
    if (pointage.status.toLowerCase() == 'pending') {
      // En attente - Afficher boutons Valider/Rejeter
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showApproveConfirmation(pointage),
                icon: const Icon(Icons.check),
                label: const Text('Valider'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRejectDialog(pointage),
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
    } else if (pointage.status.toLowerCase() == 'approved') {
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
              'Pointage validé',
              style: TextStyle(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    } else if (pointage.status.toLowerCase() == 'rejected') {
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
              'Pointage rejeté',
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
              'Statut: ${pointage.status}',
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

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
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
    switch (status.toLowerCase()) {
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

  void _showApproveConfirmation(AttendancePunchModel pointage) async {
    Get.defaultDialog(
      title: 'Confirmation',
      middleText: 'Voulez-vous valider ce pointage ?',
      textConfirm: 'Valider',
      textCancel: 'Annuler',
      confirmTextColor: Colors.white,
      onConfirm: () async {
        Get.back();

        try {
          final AttendancePunchService _punchService = AttendancePunchService();
          final result = await _punchService.approveAttendance(pointage.id!);

          if (result['success'] == true) {
            Get.snackbar(
              'Succès',
              'Pointage validé avec succès',
              backgroundColor: Colors.green,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
            _loadAttendanceData();
          } else {
            Get.snackbar(
              'Erreur',
              result['message'] ?? 'Erreur lors de la validation',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } catch (e) {
          Get.snackbar(
            'Erreur',
            'Erreur lors de la validation: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }

  void _showRejectDialog(AttendancePunchModel pointage) {
    final commentController = TextEditingController();

    Get.defaultDialog(
      title: 'Rejeter le pointage',
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
      onConfirm: () async {
        if (commentController.text.isEmpty) {
          Get.snackbar(
            'Erreur',
            'Veuillez entrer un motif de rejet',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
        }
        Get.back();

        try {
          final AttendancePunchService _punchService = AttendancePunchService();
          final result = await _punchService.rejectAttendance(
            pointage.id!,
            commentController.text.trim(),
          );

          if (result['success'] == true) {
            Get.snackbar(
              'Succès',
              'Pointage rejeté avec succès',
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 3),
            );
            _loadAttendanceData();
          } else {
            Get.snackbar(
              'Erreur',
              result['message'] ?? 'Erreur lors du rejet',
              backgroundColor: Colors.red,
              colorText: Colors.white,
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        } catch (e) {
          Get.snackbar(
            'Erreur',
            'Erreur lors du rejet: $e',
            backgroundColor: Colors.red,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      },
    );
  }
}
