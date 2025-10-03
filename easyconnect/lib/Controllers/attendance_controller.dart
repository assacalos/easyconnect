import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/services/location_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class AttendanceController extends GetxController {
  final AttendancePunchService _attendanceService = AttendancePunchService();
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxBool isCheckingIn = false.obs;
  final RxBool isCheckingOut = false.obs;
  final RxString currentStatus =
      'unknown'.obs; // 'checked_in', 'checked_out', 'unknown'
  final Rx<LocationInfo?> currentLocation = Rx<LocationInfo?>(null);
  final Rx<String?> photoPath = Rx<String?>(null);
  final RxString notes = ''.obs;
  final RxList<AttendancePunchModel> attendanceHistory =
      <AttendancePunchModel>[].obs;
  // final Rx<AttendanceStats?> attendanceStats = Rx<AttendanceStats?>(null);
  // final Rx<AttendanceSettings?> attendanceSettings = Rx<AttendanceSettings?>(null);

  // Variables pour le formulaire
  final TextEditingController notesController = TextEditingController();
  final RxBool isLocationLoading = false.obs;
  final RxBool isPhotoLoading = false.obs;
  final RxString locationError = ''.obs;
  final RxString photoError = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAttendanceData();
  }

  @override
  void onClose() {
    notesController.dispose();
    super.onClose();
  }

  // Charger les données de pointage
  Future<void> loadAttendanceData() async {
    try {
      isLoading.value = true;
      print('🔄 Début du chargement des données de pointage...');

      final user = _authController.userAuth.value;
      if (user == null) {
        print('❌ Utilisateur non connecté');
        return;
      }

      print('👤 Utilisateur connecté: ${user.nom} (ID: ${user.id})');

      // Charger l'historique de pointage - utiliser getAttendances pour avoir tous les pointages
      print('📡 Appel de getAttendances...');
      final history = await _attendanceService.getAttendances(
        userId: user.id, // Filtrer par utilisateur
      );

      print('📊 Nombre de pointages récupérés: ${history.length}');
      attendanceHistory.value = history;

      // Charger les statistiques
      /* print('📈 Chargement des statistiques...');
      final stats = await _attendanceService.getAttendanceStats(
        userId: user.id,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      attendanceStats.value = stats;
      print('✅ Statistiques chargées'); */

      // Vérifier le statut actuel
      await checkCurrentStatus();
      print('✅ Données de pointage chargées avec succès');
    } catch (e) {
      print('❌ Erreur lors du chargement des données de pointage: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données de pointage: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les paramètres de pointage (supprimé - pas nécessaire pour le nouveau système)

  // Vérifier le statut actuel de l'utilisateur
  Future<void> checkCurrentStatus() async {
    try {
      final user = _authController.userAuth.value;
      if (user == null) return;

      final canPunchData = await _attendanceService.canPunch(type: 'check_in');
      currentStatus.value =
          canPunchData['can_punch'] == true ? 'checked_out' : 'checked_in';
    } catch (e) {
      print('Erreur lors de la vérification du statut: $e');
      currentStatus.value = 'unknown';
    }
  }

  // Obtenir la position actuelle
  Future<void> getCurrentLocation() async {
    try {
      isLocationLoading.value = true;
      locationError.value = '';

      // Vérifier d'abord les permissions
      final locationService = LocationService();
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        locationError.value =
            'Permission de géolocalisation refusée. Veuillez l\'activer dans les paramètres.';
        return;
      }

      final location = await locationService.getLocationInfo();
      currentLocation.value = location;

      // Afficher un message de succès
      Get.snackbar(
        'Succès',
        'Position obtenue avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      String errorMessage = 'Impossible d\'obtenir la position';

      // Messages d'erreur plus spécifiques
      if (e.toString().contains('Permission')) {
        errorMessage = 'Permission de géolocalisation refusée';
      } else if (e.toString().contains('timeout')) {
        errorMessage =
            'Délai d\'attente dépassé. Vérifiez votre connexion GPS.';
      } else if (e.toString().contains('location')) {
        errorMessage = 'Service de géolocalisation indisponible';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }

      locationError.value = errorMessage;
      print('Erreur géolocalisation: $e');

      // Afficher l'erreur à l'utilisateur
      Get.snackbar(
        'Erreur de géolocalisation',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } finally {
      isLocationLoading.value = false;
    }
  }

  // Prendre une photo
  Future<void> takePhoto() async {
    try {
      isPhotoLoading.value = true;
      photoError.value = '';

      final cameraService = CameraService();
      final photo = await cameraService.takePicture();
      if (photo != null) {
        photoPath.value = photo.path;
      } else {
        photoError.value = 'Aucune photo prise';
      }
    } catch (e) {
      photoError.value = 'Erreur lors de la prise de photo: $e';
      print('Erreur photo: $e');
    } finally {
      isPhotoLoading.value = false;
    }
  }

  // Pointer l'arrivée
  Future<void> checkIn() async {
    try {
      isCheckingIn.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      // Test de connectivité rapide
      print('🔍 Test de connectivité API...');
      try {
        await _attendanceService.canPunch(type: 'check_in');
        print('✅ Connectivité API confirmée');
      } catch (e) {
        print('❌ Échec du test de connectivité');
        Get.snackbar(
          'Erreur de connexion',
          'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      // Vérifier si la géolocalisation est requise (toujours obligatoire dans le nouveau système)
      if (currentLocation.value == null) {
        await getCurrentLocation();
        if (currentLocation.value == null) {
          Get.snackbar('Erreur', 'Position requise pour pointer');
          return;
        }
      }

      // Vérifier si la photo est requise (toujours obligatoire dans le nouveau système)
      if (photoPath.value == null) {
        Get.snackbar('Erreur', 'Photo requise pour pointer');
        return;
      }

      final result = await _attendanceService.punchAttendance(
        type: 'check_in',
        photo: File(photoPath.value!),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        currentStatus.value = 'checked_in';
        Get.snackbar(
          'Succès',
          'Pointage d\'arrivée enregistré',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );

        // Recharger les données
        await loadAttendanceData();

        // Réinitialiser le formulaire
        photoPath.value = null;
        notesController.clear();
        notes.value = '';
      } else {
        String errorMessage = result['message'] ?? 'Erreur lors du pointage';
        Get.snackbar(
          'Erreur de pointage',
          errorMessage,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      String errorMessage = 'Erreur lors du pointage d\'arrivée';

      // Messages d'erreur plus spécifiques
      if (e.toString().contains('Permission')) {
        errorMessage = 'Permission de géolocalisation refusée';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Délai d\'attente dépassé. Vérifiez votre connexion.';
      } else if (e.toString().contains('404')) {
        errorMessage =
            'Service de pointage indisponible. Contactez l\'administrateur.';
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erreur serveur. Réessayez plus tard.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';
      } else {
        errorMessage = 'Erreur: ${e.toString()}';
      }

      Get.snackbar(
        'Erreur de pointage',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      print('Erreur checkIn: $e');
    } finally {
      isCheckingIn.value = false;
    }
  }

  // Pointer le départ
  Future<void> checkOut() async {
    try {
      isCheckingOut.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        Get.snackbar('Erreur', 'Utilisateur non connecté');
        return;
      }

      final result = await _attendanceService.punchAttendance(
        type: 'check_out',
        photo: File(photoPath.value!),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        currentStatus.value = 'checked_out';
        Get.snackbar('Succès', 'Pointage de départ enregistré');

        // Recharger les données
        await loadAttendanceData();

        // Réinitialiser le formulaire
        notesController.clear();
        notes.value = '';
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du pointage');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du pointage de départ: $e');
      print('Erreur checkOut: $e');
    } finally {
      isCheckingOut.value = false;
    }
  }

  // Supprimer la photo
  void removePhoto() {
    photoPath.value = null;
    photoError.value = '';
  }

  // Mettre à jour les notes
  void updateNotes(String value) {
    notes.value = value;
  }

  // Vérifier si l'utilisateur peut pointer l'arrivée
  bool get canCheckIn =>
      currentStatus.value == 'checked_out' || currentStatus.value == 'unknown';

  // Vérifier si l'utilisateur peut pointer le départ
  bool get canCheckOut => currentStatus.value == 'checked_in';

  // Obtenir le texte du bouton principal
  String get mainButtonText {
    if (isCheckingIn.value) return 'Pointage en cours...';
    if (isCheckingOut.value) return 'Pointage en cours...';
    if (canCheckIn) return 'Pointer l\'arrivée';
    if (canCheckOut) return 'Pointer le départ';
    return 'Pointage indisponible';
  }

  // Obtenir la couleur du bouton principal
  Color get mainButtonColor {
    if (canCheckIn) return Colors.green;
    if (canCheckOut) return Colors.orange;
    return Colors.grey;
  }

  // Obtenir l'icône du bouton principal
  IconData get mainButtonIcon {
    if (canCheckIn) return Icons.login;
    if (canCheckOut) return Icons.logout;
    return Icons.block;
  }
}
