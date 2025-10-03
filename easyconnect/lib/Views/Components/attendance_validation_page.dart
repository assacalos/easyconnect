import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../Models/attendance_punch_model.dart';
import '../../services/attendance_punch_service.dart';

class AttendanceValidationPage extends StatefulWidget {
  const AttendanceValidationPage({super.key});

  @override
  State<AttendanceValidationPage> createState() =>
      _AttendanceValidationPageState();
}

class _AttendanceValidationPageState extends State<AttendanceValidationPage> {
  final AttendancePunchService _punchService = AttendancePunchService();

  List<AttendancePunchModel> _attendances = [];
  bool _isLoading = false;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() => _isLoading = true);

    try {
      final attendances = await _punchService.getPendingAttendances();
      setState(() {
        _attendances = attendances;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de charger les pointages');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAttendance(AttendancePunchModel attendance) async {
    try {
      final result = await _punchService.approveAttendance(attendance.id!);

      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          'Pointage approuvé',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _loadAttendances();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'approbation: $e');
    }
  }

  Future<void> _rejectAttendance(AttendancePunchModel attendance) async {
    final TextEditingController reasonController = TextEditingController();

    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Rejeter le pointage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Pointage de ${attendance.userName ?? 'Utilisateur inconnu'}'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison du rejet',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (result == true && reasonController.text.trim().isNotEmpty) {
      try {
        final rejectResult = await _punchService.rejectAttendance(
          attendance.id!,
          reasonController.text.trim(),
        );

        if (rejectResult['success'] == true) {
          Get.snackbar(
            'Succès',
            'Pointage rejeté',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
          _loadAttendances();
        } else {
          Get.snackbar(
            'Erreur',
            rejectResult['message'],
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      } catch (e) {
        Get.snackbar('Erreur', 'Erreur lors du rejet: $e');
      }
    }
  }

  List<AttendancePunchModel> get _filteredAttendances {
    switch (_selectedFilter) {
      case 'check_in':
        return _attendances.where((a) => a.isCheckIn).toList();
      case 'check_out':
        return _attendances.where((a) => a.isCheckOut).toList();
      default:
        return _attendances;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Validation des pointages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed('/attendance-punch'),
            tooltip: 'Nouveau pointage',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendances,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filtrer: '),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Tous')),
                      DropdownMenuItem(
                        value: 'check_in',
                        child: Text('Arrivées'),
                      ),
                      DropdownMenuItem(
                        value: 'check_out',
                        child: Text('Départs'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedFilter = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Liste des pointages
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredAttendances.isEmpty
                    ? const Center(child: Text('Aucun pointage en attente'))
                    : ListView.builder(
                      itemCount: _filteredAttendances.length,
                      itemBuilder: (context, index) {
                        final attendance = _filteredAttendances[index];
                        return _buildAttendanceCard(attendance);
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCard(AttendancePunchModel attendance) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attendance.userName ?? 'Utilisateur inconnu',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(attendance.formattedTimestamp),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getTypeColor(attendance.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    attendance.typeLabel,
                    style: TextStyle(
                      color: _getTypeColor(attendance.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Localisation
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    attendance.address ?? 'Adresse inconnue',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),

            if (attendance.notes != null && attendance.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.note, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attendance.notes!,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],

            // Photo
            if (attendance.photoPath != null) ...[
              const SizedBox(height: 12),
              Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    attendance.photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveAttendance(attendance),
                    icon: const Icon(Icons.check),
                    label: const Text('Approuver'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectAttendance(attendance),
                    icon: const Icon(Icons.close),
                    label: const Text('Rejeter'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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

  Color _getTypeColor(String type) {
    switch (type) {
      case 'check_in':
        return Colors.blue;
      case 'check_out':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
