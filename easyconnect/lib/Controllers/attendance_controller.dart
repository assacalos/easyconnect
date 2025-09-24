import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/attendance_model.dart';
import 'package:easyconnect/services/attendance_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class AttendanceController extends GetxController {
  final AttendanceService _attendanceService = AttendanceService.to;
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
  final RxList<AttendanceModel> attendanceHistory = <AttendanceModel>[].obs;
  final Rx<AttendanceStats?> attendanceStats = Rx<AttendanceStats?>(null);
  final Rx<AttendanceSettings?> attendanceSettings = Rx<AttendanceSettings?>(
    null,
  );

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
    loadAttendanceSettings();
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

      final user = _authController.userAuth.value;
      if (user == null) return;

      // Charger l'historique de pointage
      final history = await _attendanceService.getUserAttendance(
        userId: user.id!,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      attendanceHistory.value = history;

      // Charger les statistiques
      final stats = await _attendanceService.getAttendanceStats(
        userId: user.id!,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now(),
      );
      attendanceStats.value = stats;

      // Vérifier le statut actuel
      await checkCurrentStatus();
    } catch (e) {
      print('Erreur lors du chargement des données de pointage: $e');
      Get.snackbar(
        'Erreur',
        'Impossible de charger les données de pointage',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les paramètres de pointage
  Future<void> loadAttendanceSettings() async {
    try {
      final settings = await _attendanceService.getAttendanceSettings();
      attendanceSettings.value = settings;
    } catch (e) {
      print('Erreur lors du chargement des paramètres: $e');
    }
  }

  // Vérifier le statut actuel de l'utilisateur
  Future<void> checkCurrentStatus() async {
    try {
      final user = _authController.userAuth.value;
      if (user == null) return;

      final canCheckInData = await _attendanceService.canCheckIn(user.id!);
      currentStatus.value = canCheckInData['status'] ?? 'unknown';
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

      final location = await _attendanceService.getCurrentLocation();
      currentLocation.value = location;
    } catch (e) {
      locationError.value = 'Impossible d\'obtenir la position: $e';
      print('Erreur géolocalisation: $e');
    } finally {
      isLocationLoading.value = false;
    }
  }

  // Prendre une photo
  Future<void> takePhoto() async {
    try {
      isPhotoLoading.value = true;
      photoError.value = '';

      final path = await _attendanceService.takePhoto();
      if (path != null) {
        photoPath.value = path;
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

      // Vérifier si la géolocalisation est requise
      if (attendanceSettings.value?.requireLocation == true &&
          currentLocation.value == null) {
        await getCurrentLocation();
        if (currentLocation.value == null) {
          Get.snackbar('Erreur', 'Position requise pour pointer');
          return;
        }
      }

      // Vérifier si la photo est requise
      if (attendanceSettings.value?.requirePhoto == true &&
          photoPath.value == null) {
        Get.snackbar('Erreur', 'Photo requise pour pointer');
        return;
      }

      final result = await _attendanceService.checkIn(
        userId: user.id!,
        userName: user.nom ?? 'Utilisateur',
        userRole: user.role?.toString() ?? 'employee',
        photoPath: photoPath.value,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        currentStatus.value = 'checked_in';
        Get.snackbar('Succès', 'Pointage d\'arrivée enregistré');

        // Recharger les données
        await loadAttendanceData();

        // Réinitialiser le formulaire
        photoPath.value = null;
        notesController.clear();
        notes.value = '';
      } else {
        Get.snackbar('Erreur', result['message'] ?? 'Erreur lors du pointage');
      }
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors du pointage d\'arrivée: $e');
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

      final result = await _attendanceService.checkOut(
        userId: user.id!,
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
