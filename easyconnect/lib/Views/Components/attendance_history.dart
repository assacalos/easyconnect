import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Models/attendance_model.dart';

class AttendanceHistory extends StatelessWidget {
  const AttendanceHistory({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.find<AttendanceController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique de pointage'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.attendanceHistory.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Aucun historique de pointage',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.attendanceHistory.length,
          itemBuilder: (context, index) {
            final attendance = controller.attendanceHistory[index];
            return _buildAttendanceCard(attendance);
          },
        );
      }),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec date et statut
            Row(
              children: [
                Icon(
                  _getStatusIcon(attendance.status),
                  color: _getStatusColor(attendance.status),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _formatDate(attendance.checkInTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(attendance.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(attendance.status),
                    style: TextStyle(
                      color: _getStatusColor(attendance.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Heures de pointage
            Row(
              children: [
                const Icon(Icons.login, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Arrivée: ${_formatTime(attendance.checkInTime)}',
                  style: const TextStyle(fontSize: 14),
                ),
                if (attendance.checkOutTime != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.logout, size: 16, color: Colors.red),
                  const SizedBox(width: 8),
                  Text(
                    'Départ: ${_formatTime(attendance.checkOutTime!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
            
            // Durée de travail
            if (attendance.checkOutTime != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Durée: ${_calculateDuration(attendance.checkInTime, attendance.checkOutTime!)}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
            
            // Position
            if (attendance.location.address != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      attendance.location.address!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
            
            // Photo
            if (attendance.photoPath != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.camera_alt, size: 16, color: Colors.purple),
                  const SizedBox(width: 8),
                  const Text(
                    'Photo prise',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
            
            // Notes
            if (attendance.notes != null && attendance.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  attendance.notes!,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'present':
        return Icons.check_circle;
      case 'absent':
        return Icons.cancel;
      case 'late':
        return Icons.schedule;
      case 'early_leave':
        return Icons.exit_to_app;
      default:
        return Icons.help;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'present':
        return Colors.green;
      case 'absent':
        return Colors.red;
      case 'late':
        return Colors.orange;
      case 'early_leave':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'present':
        return 'Présent';
      case 'absent':
        return 'Absent';
      case 'late':
        return 'En retard';
      case 'early_leave':
        return 'Départ anticipé';
      default:
        return 'Inconnu';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Aujourd\'hui';
    } else if (dateOnly == yesterday) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
