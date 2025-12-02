import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/services/location_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/logger.dart';

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

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;

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
  Future<void> loadAttendanceData({int page = 1}) async {
    try {
      isLoading.value = true;

      final user = _authController.userAuth.value;
      if (user == null) {
        return;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _attendanceService
            .getAttendancesPaginated(
              userId: user.role == Roles.PATRON ? null : user.id,
              page: page,
              perPage: perPage.value,
              search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
            );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          attendanceHistory.value = paginatedResponse.data;
        } else {
          attendanceHistory.addAll(paginatedResponse.data);
        }
      } catch (e, stackTrace) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        try {
          final history =
              user.role == Roles.PATRON
                  ? await _attendanceService.getAttendances()
                  : await _attendanceService.getAttendances(userId: user.id);
          if (page == 1) {
            attendanceHistory.value = history;
          } else {
            attendanceHistory.addAll(history);
          }
        } catch (fallbackError) {
          rethrow;
        }
      }

      // Vérifier le statut actuel
      await checkCurrentStatus();
    } catch (e, stackTrace) {
      /*  Get.snackbar(
        'Erreur',
        'Impossible de charger les données de pointage: $e',
        snackPosition: SnackPosition.BOTTOM,
      ); */
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
      loadAttendanceData(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadAttendanceData(page: currentPage.value - 1);
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
      /*  Get.snackbar(
        'Succès',
        'Position obtenue avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      ); */
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

      // Afficher l'erreur à l'utilisateur
      /* Get.snackbar(
        'Erreur de géolocalisation',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      ); */
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
        return;
      }

      // Test de connectivité rapide
      /* try {
        await _attendanceService.canPunch(type: 'check_in');
      } catch (e) {
        Get.snackbar(
          'Erreur de connexion',
          'Impossible de se connecter au serveur. Vérifiez votre connexion internet.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      } */

      // Vérifier si la géolocalisation est requise (toujours obligatoire dans le nouveau système)
      if (currentLocation.value == null) {
        await getCurrentLocation();
        if (currentLocation.value == null) {
          return;
        }
      }

      // Vérifier si la photo est requise (toujours obligatoire dans le nouveau système)
      if (photoPath.value == null) {
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
        /* Get.snackbar(
          'Succès',
          'Pointage d\'arrivée enregistré',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        ); */

        // Recharger les données
        await loadAttendanceData();

        // Réinitialiser le formulaire
        photoPath.value = null;
        notesController.clear();
        notes.value = '';
      } else {
        // Erreur lors du pointage
        /*  Get.snackbar(
          'Erreur de pointage',
          result['message'] ?? 'Erreur lors du pointage',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        ); */
      }
    } catch (e) {
      // Erreur lors du pointage d'arrivée
      /*  Get.snackbar(
        'Erreur de pointage',
        'Erreur lors du pointage d\'arrivée',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      ); */
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

        // Recharger les données
        await loadAttendanceData();

        // Réinitialiser le formulaire
        notesController.clear();
        notes.value = '';
      }
    } catch (e) {
      // Erreur silencieuse - ne pas afficher de message
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
