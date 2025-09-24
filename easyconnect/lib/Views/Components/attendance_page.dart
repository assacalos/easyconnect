import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Views/Components/attendance_history.dart';
import 'package:easyconnect/Views/Components/attendance_stats.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AttendanceController controller = Get.put(AttendanceController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Get.to(() => const AttendanceHistory()),
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => Get.to(() => const AttendanceStats()),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Carte de statut
              _buildStatusCard(controller),
              const SizedBox(height: 20),

              // Section géolocalisation
              _buildLocationSection(controller),
              const SizedBox(height: 20),

              // Section photo
              _buildPhotoSection(controller),
              const SizedBox(height: 20),

              // Section notes
              _buildNotesSection(controller),
              const SizedBox(height: 30),

              // Bouton principal de pointage
              _buildMainButton(controller),
              const SizedBox(height: 20),

              // Statistiques rapides
              _buildQuickStats(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildStatusCard(AttendanceController controller) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              controller.currentStatus.value == 'checked_in'
                  ? Icons.check_circle
                  : controller.currentStatus.value == 'checked_out'
                  ? Icons.cancel
                  : Icons.help,
              size: 48,
              color:
                  controller.currentStatus.value == 'checked_in'
                      ? Colors.green
                      : controller.currentStatus.value == 'checked_out'
                      ? Colors.red
                      : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(
              controller.currentStatus.value == 'checked_in'
                  ? 'Vous êtes présent'
                  : controller.currentStatus.value == 'checked_out'
                  ? 'Vous êtes absent'
                  : 'Statut inconnu',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Dernière mise à jour: ${DateTime.now().toString().substring(0, 16)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(AttendanceController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Position actuelle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () =>
                      controller.isLocationLoading.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: controller.getCurrentLocation,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.currentLocation.value != null) {
                final location = controller.currentLocation.value!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Latitude: ${location.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'Longitude: ${location.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (location.address != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Adresse: ${location.address}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    if (location.accuracy != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Précision: ${location.accuracy!.toStringAsFixed(1)}m',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                );
              } else if (controller.locationError.value.isNotEmpty) {
                return Text(
                  controller.locationError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                );
              } else {
                return const Text(
                  'Aucune position enregistrée',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(AttendanceController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.camera_alt, color: Colors.purple),
                const SizedBox(width: 8),
                const Text(
                  'Photo de pointage',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Obx(
                  () =>
                      controller.isPhotoLoading.value
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed: controller.takePhoto,
                          ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Obx(() {
              final photoPath = controller.photoPath.value;
              if (photoPath != null && photoPath.isNotEmpty) {
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(File(photoPath), fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Photo prise avec succès',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: controller.removePhoto,
                          icon: const Icon(Icons.delete, size: 16),
                          label: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  ],
                );
              } else if (controller.photoError.value.isNotEmpty) {
                return Text(
                  controller.photoError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                );
              } else {
                return const Text(
                  'Aucune photo prise',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection(AttendanceController controller) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.note, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Notes (optionnel)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller.notesController,
              onChanged: controller.updateNotes,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ajoutez des notes sur votre pointage...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton(AttendanceController controller) {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed:
              controller.canCheckIn
                  ? controller.checkIn
                  : controller.canCheckOut
                  ? controller.checkOut
                  : null,
          icon: Icon(controller.mainButtonIcon),
          label: Text(controller.mainButtonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: controller.mainButtonColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats(AttendanceController controller) {
    return Obx(() {
      if (controller.attendanceStats.value == null) {
        return const SizedBox.shrink();
      }

      final stats = controller.attendanceStats.value!;
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text(
                    'Statistiques du mois',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Présents',
                      stats.presentDays,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Absents',
                      stats.absentDays,
                      Colors.red,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Retards',
                      stats.lateDays,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Heures moyennes: ${stats.averageHours.toStringAsFixed(1)}h',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
