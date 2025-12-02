import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/attendance_punch_service.dart';
import '../../services/location_service.dart';
import '../../services/camera_service.dart';
import '../../Models/attendance_punch_model.dart';
import '../../Views/Components/skeleton_loaders.dart';

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
  String _punchMessage = '';

  @override
  void initState() {
    super.initState();
    _checkCanPunch();
    _getLocation();
  }

  Future<void> _checkCanPunch() async {
    setState(() => _isLoading = true);

    try {
      print(
        '🔍 [ATTENDANCE_PUNCH_PAGE] Vérification canPunch, type: $_punchType',
      );
      final result = await _punchService.canPunch(type: _punchType);
      print('🔍 [ATTENDANCE_PUNCH_PAGE] Résultat reçu: $result');

      setState(() {
        _canPunch = result['can_punch'] ?? false;
        _punchMessage =
            result['message'] ??
            (_canPunch
                ? 'Vous pouvez pointer maintenant'
                : 'Vous ne pouvez pas pointer maintenant');
      });

      print('🔍 [ATTENDANCE_PUNCH_PAGE] canPunch: $_canPunch');
      print('🔍 [ATTENDANCE_PUNCH_PAGE] message: $_punchMessage');
    } catch (e) {
      // Erreur silencieuse - ne pas afficher de message
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
      // Erreur silencieuse - ne pas afficher de message
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
      // Erreur silencieuse - ne pas afficher de message
    }
  }

  Future<void> _submitPunch() async {
    print('🚀 [ATTENDANCE_PUNCH_PAGE] Début de la soumission du pointage');
    print('🚀 [ATTENDANCE_PUNCH_PAGE] Type: $_punchType');

    if (_selectedImage == null) {
      return;
    }
    print(
      '✅ [ATTENDANCE_PUNCH_PAGE] Photo disponible: ${_selectedImage!.path}',
    );

    if (_locationInfo == null) {
      return;
    }
    print(
      '✅ [ATTENDANCE_PUNCH_PAGE] Localisation disponible: ${_locationInfo!.address}',
    );

    setState(() => _isLoading = true);

    try {
      print('✅ [ATTENDANCE_PUNCH_PAGE] Envoi du pointage au serveur...');
      print(
        '📤 [ATTENDANCE_PUNCH_PAGE] Données: type=$_punchType, photo=${_selectedImage!.path}, notes=${_notesController.text.trim()}',
      );

      final result = await _punchService.punchAttendance(
        type: _punchType,
        photo: _selectedImage!,
        notes: _notesController.text.trim(),
      );

      print('📥 [ATTENDANCE_PUNCH_PAGE] Résultat reçu: $result');

      if (result['success'] == true) {
        print('✅ [ATTENDANCE_PUNCH_PAGE] Pointage enregistré avec succès');

        // Réinitialiser le formulaire
        setState(() {
          _selectedImage = null;
          _notesController.clear();
        });

        // Vérifier que le pointage est bien en statut pending (soumis au patron)
        final attendanceData = result['data'] as AttendancePunchModel?;
        final status = attendanceData?.status ?? 'pending';
        final isPending = status == 'pending';

        print('📊 [ATTENDANCE_PUNCH_PAGE] Statut du pointage: $status');
        print('📊 [ATTENDANCE_PUNCH_PAGE] Est en attente: $isPending');

        // Message de succès plus informatif
        final typeLabel = _punchType == 'check_in' ? 'arrivée' : 'départ';
        final message =
            isPending
                ? 'Votre pointage d\'$typeLabel a été enregistré et soumis au patron pour validation. Vous serez notifié de la décision.'
                : 'Votre pointage d\'$typeLabel a été enregistré avec succès.';

        // Arrêter le loading avant d'afficher le message
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // Afficher le message de succès
        try {
          Get.snackbar(
            '✅ Pointage enregistré',
            message,
            backgroundColor: Colors.green,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(16),
            borderRadius: 8,
            icon: const Icon(Icons.check_circle, color: Colors.white, size: 28),
            shouldIconPulse: true,
            isDismissible: true,
            mainButton: TextButton(
              onPressed: () => Get.back(),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          );
        } catch (e) {
          print(
            '❌ [ATTENDANCE_PUNCH_PAGE] Erreur lors de l\'affichage du snackbar: $e',
          );
          // Afficher un message alternatif si le snackbar échoue
          if (mounted) {
            Get.dialog(
              AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text('Pointage enregistré'),
                  ],
                ),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () {
                      Get.back(); // Fermer le dialog
                      Get.back(); // Fermer la page de pointage
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        }

        // Attendre un peu pour que l'utilisateur voie le message, puis fermer la page
        await Future.delayed(const Duration(milliseconds: 2000));

        // Fermer la page automatiquement
        if (mounted) {
          print('🚪 [ATTENDANCE_PUNCH_PAGE] Fermeture de la page');
          Get.back();
        }
      } else {
        // Arrêter le loading en cas d'erreur
        if (mounted) {
          setState(() => _isLoading = false);
        }

        final errorMessage =
            result['message'] ?? 'Erreur lors de l\'enregistrement du pointage';

        // Afficher un message d'erreur
        Get.snackbar(
          '❌ Erreur',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 4),
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          icon: const Icon(Icons.error, color: Colors.white, size: 28),
        );

        final statusCode = result['status_code'] ?? 0;
        // Si c'est une erreur 400 (ne peut pas pointer), re-vérifier le statut
        if (statusCode == 400) {
          await _checkCanPunch();
        }
      }
    } catch (e) {
      print('❌ [ATTENDANCE_PUNCH_PAGE] Erreur lors de la soumission: $e');

      // Arrêter le loading en cas d'erreur
      if (mounted) {
        setState(() => _isLoading = false);
      }

      // Afficher un message d'erreur
      Get.snackbar(
        '❌ Erreur',
        'Une erreur est survenue lors de l\'enregistrement du pointage. Veuillez réessayer.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white, size: 28),
      );
    }
  }

  void _togglePunchType() {
    setState(() {
      _punchType = _punchType == 'check_in' ? 'check_out' : 'check_in';
      _punchMessage = ''; // Réinitialiser le message
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
              ? const SkeletonPage(listItemCount: 6)
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
                            if (!_canPunch && _punchMessage.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  _punchMessage,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
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
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _takePicture,
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Prendre une photo'),
                              ),
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
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(0, 44),
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
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
