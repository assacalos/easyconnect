import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/attendance_punch_service.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../Models/attendance_punch_model.dart';

class AttendancePunchPage extends StatefulWidget {
  const AttendancePunchPage({super.key});

  @override
  State<AttendancePunchPage> createState() => _AttendancePunchPageState();
}

class _AttendancePunchPageState extends State<AttendancePunchPage> {
  final AttendancePunchService _punchService = AttendancePunchService();
  final LocationService _locationService = LocationService();
  final CameraService _cameraService = CameraService();

  final TextEditingController _notesController = TextEditingController();

  File? _selectedImage;
  bool _isLoading = false;
  bool _canPunch = false;
  String _punchType = 'check_in';
  LocationInfo? _locationInfo;

  @override
  void initState() {
    super.initState();
    _checkCanPunch();
    _getLocation();
  }

  Future<void> _checkCanPunch() async {
    setState(() => _isLoading = true);

    try {
      final result = await _punchService.canPunch(type: _punchType);
      setState(() {
        _canPunch = result['can_punch'] ?? false;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de vérifier le statut de pointage');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getLocation() async {
    try {
      final location = await _locationService.getLocationInfo();
      setState(() {
        _locationInfo = location;
      });
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible d\'obtenir la localisation');
    }
  }

  Future<void> _takePicture() async {
    try {
      final image = await _cameraService.takePicture();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de prendre la photo: $e');
    }
  }

  Future<void> _selectFromGallery() async {
    try {
      final image = await _cameraService.pickImageFromGallery();
      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Impossible de sélectionner l\'image: $e');
    }
  }

  Future<void> _submitPunch() async {
    if (_selectedImage == null) {
      Get.snackbar('Erreur', 'Veuillez prendre une photo');
      return;
    }

    if (_locationInfo == null) {
      Get.snackbar('Erreur', 'Localisation non disponible');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _punchService.punchAttendance(
        type: _punchType,
        photo: _selectedImage!,
        notes: _notesController.text.trim(),
      );

      if (result['success'] == true) {
        Get.snackbar(
          'Succès',
          result['message'],
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        Get.back();
      } else {
        Get.snackbar(
          'Erreur',
          result['message'],
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du pointage: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _togglePunchType() {
    setState(() {
      _punchType = _punchType == 'check_in' ? 'check_out' : 'check_in';
    });
    _checkCanPunch();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointage'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Get.toNamed('/attendance-validation'),
            tooltip: 'Voir la liste des pointages',
          ),
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: _getLocation,
            tooltip: 'Actualiser la localisation',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Statut de pointage
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Type de pointage',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                Switch(
                                  value: _punchType == 'check_out',
                                  onChanged: (_) => _togglePunchType(),
                                  activeColor: Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    _punchType == 'check_in'
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _punchType == 'check_in' ? 'Arrivée' : 'Départ',
                                style: TextStyle(
                                  color:
                                      _punchType == 'check_in'
                                          ? Colors.blue
                                          : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!_canPunch)
                              const Text(
                                'Vous ne pouvez pas pointer maintenant',
                                style: TextStyle(color: Colors.red),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Localisation
                    if (_locationInfo != null)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Localisation',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(_locationInfo!.address),
                              const SizedBox(height: 4),
                              Text(
                                'Précision: ${_locationInfo!.accuracy.toStringAsFixed(1)}m',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Photo
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Photo obligatoire',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_selectedImage != null)
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt,
                                        size: 48,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Aucune photo sélectionnée'),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _takePicture,
                                    icon: const Icon(Icons.camera_alt),
                                    label: const Text('Prendre une photo'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _selectFromGallery,
                                    icon: const Icon(Icons.photo_library),
                                    label: const Text('Galerie'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Notes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.note, color: Colors.orange),
                                const SizedBox(width: 8),
                                Text(
                                  'Notes (optionnel)',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _notesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                hintText: 'Ajoutez une note...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Bouton de soumission
                    ElevatedButton(
                      onPressed:
                          _canPunch && _selectedImage != null && !_isLoading
                              ? _submitPunch
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _punchType == 'check_in'
                                ? Colors.blue
                                : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child:
                          _isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text(
                                _punchType == 'check_in'
                                    ? 'Pointer l\'arrivée'
                                    : 'Pointer le départ',
                                style: const TextStyle(fontSize: 16),
                              ),
                    ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed('/attendance-validation'),
        icon: const Icon(Icons.list_alt),
        label: const Text('Liste des pointages'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
