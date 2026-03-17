import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/attendance_punch_model.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/services/location_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class AttendanceController {
  static final AttendanceController _instance = AttendanceController._();
  static AttendanceController get to => _instance;
  factory AttendanceController() => _instance;
  AttendanceController._();

  final AttendancePunchService _attendanceService = AttendancePunchService();
  final AuthController _authController = AuthController.to;

  // Variables (plain types)
  bool isLoading = false;
  bool isCheckingIn = false;
  bool isCheckingOut = false;
  bool isLoadingMore = false;
  String currentStatus = 'unknown';
  LocationInfo? currentLocation;
  String? photoPath;
  String notes = '';
  final List<AttendancePunchModel> attendanceHistory = [];

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';

  // Variables pour le formulaire
  final TextEditingController notesController = TextEditingController();
  bool isLocationLoading = false;
  bool isPhotoLoading = false;
  String locationError = '';
  String photoError = '';

  void dispose() {
    notesController.dispose();
  }

  bool _isLoadingAttendanceInProgress = false;

  /// Charge les pointages : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadAttendanceData({int page = 1}) async {
    final user = _authController.userAuth;
    if (user == null) return;
    if (_isLoadingAttendanceInProgress) return;
    _isLoadingAttendanceInProgress = true;

    if (page == 1) {
      isLoading = true;
      final cached = AttendancePunchService.getCachedAttendances();
      if (cached.isNotEmpty) {
        attendanceHistory.clear();
        attendanceHistory.addAll(cached);
        isLoading = false;
      } else {
        attendanceHistory.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final paginatedResponse = await _attendanceService
          .getAttendancesPaginated(
            userId: user.role == Roles.PATRON ? null : user.id,
            page: page,
            perPage: perPage,
            search: searchQuery.isNotEmpty ? searchQuery : null,
          );

      if (page == 1) {
        attendanceHistory.clear();
        attendanceHistory.addAll(paginatedResponse.data);
      } else {
        attendanceHistory.addAll(paginatedResponse.data);
      }
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = paginatedResponse.meta.currentPage;
      await checkCurrentStatus();
    } catch (e) {
      try {
        final history =
            user.role == Roles.PATRON
                ? await _attendanceService.getAttendances()
                : await _attendanceService.getAttendances(userId: user.id);
        if (page == 1) {
          attendanceHistory.clear();
          attendanceHistory.addAll(history);
        } else {
          attendanceHistory.addAll(history);
        }
        await checkCurrentStatus();
      } catch (_) {
        if (attendanceHistory.isEmpty) {
          final fallback = AttendancePunchService.getCachedAttendances();
          if (fallback.isNotEmpty) {
            attendanceHistory.clear();
            attendanceHistory.addAll(fallback);
          }
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingAttendanceInProgress = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadAttendanceData(page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadAttendanceData(page: currentPage - 1);
    }
  }

  Future<void> checkCurrentStatus() async {
    try {
      final user = _authController.userAuth;
      if (user == null) return;

      final canPunchData = await _attendanceService.canPunch(type: 'check_in');
      currentStatus =
          canPunchData['can_punch'] == true ? 'checked_out' : 'checked_in';
    } catch (e) {
      currentStatus = 'unknown';
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      isLocationLoading = true;
      locationError = '';

      final locationService = LocationService();
      final hasPermission = await locationService.requestLocationPermission();
      if (!hasPermission) {
        locationError =
            'Permission de géolocalisation refusée. Veuillez l\'activer dans les paramètres.';
        return;
      }

      final location = await locationService.getLocationInfo();
      currentLocation = location;
    } catch (e) {
      String errorMessage = 'Impossible d\'obtenir la position';

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

      locationError = errorMessage;
    } finally {
      isLocationLoading = false;
    }
  }

  Future<void> takePhoto() async {
    try {
      isPhotoLoading = true;
      photoError = '';

      final cameraService = CameraService();
      final photo = await cameraService.takePicture();
      if (photo != null) {
        photoPath = photo.path;
      } else {
        photoError = 'Aucune photo prise';
      }
    } catch (e) {
      photoError = 'Erreur lors de la prise de photo: $e';
    } finally {
      isPhotoLoading = false;
    }
  }

  Future<void> checkIn() async {
    try {
      isCheckingIn = true;

      final user = _authController.userAuth;
      if (user == null) {
        return;
      }

      if (currentLocation == null) {
        await getCurrentLocation();
        if (currentLocation == null) {
          return;
        }
      }

      if (photoPath == null) {
        return;
      }

      final result = await _attendanceService.punchAttendance(
        type: 'check_in',
        photo: File(photoPath!),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        currentStatus = 'checked_in';

        final attendanceData = result['data'] as AttendancePunchModel?;
        if (attendanceData != null && attendanceData.id != null) {
          final user = _authController.userAuth;
          final employeeName =
              user != null
                  ? '${user.prenom ?? ''} ${user.nom ?? ''}'.trim()
                  : 'Employé';

          NotificationHelper.notifySubmission(
            entityType: 'attendance',
            entityName: 'Pointage d\'arrivée de $employeeName',
            entityId: attendanceData.id.toString(),
            route: NotificationHelper.getEntityRoute(
              'attendance',
              attendanceData.id.toString(),
            ),
          );
        }

        await loadAttendanceData();

        photoPath = null;
        notesController.clear();
        notes = '';
      }
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isCheckingIn = false;
    }
  }

  Future<void> checkOut() async {
    try {
      isCheckingOut = true;

      final user = _authController.userAuth;
      if (user == null) {
        return;
      }

      final result = await _attendanceService.punchAttendance(
        type: 'check_out',
        photo: File(photoPath!),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (result['success'] == true) {
        currentStatus = 'checked_out';

        try {
          final attendanceData = result['data'];
          if (attendanceData is AttendancePunchModel &&
              attendanceData.id != null) {
            final user = _authController.userAuth;
            final employeeName =
                user != null
                    ? '${user.prenom ?? ''} ${user.nom ?? ''}'.trim()
                    : 'Employé';

            NotificationHelper.notifySubmission(
              entityType: 'attendance',
              entityName: 'Pointage de départ de $employeeName',
              entityId: attendanceData.id.toString(),
              route: NotificationHelper.getEntityRoute(
                'attendance',
                attendanceData.id.toString(),
              ),
            );
          }
        } catch (e) {
          // Ignorer les erreurs de notification
        }

        await loadAttendanceData();

        notesController.clear();
        notes = '';
      }
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isCheckingOut = false;
    }
  }

  void removePhoto() {
    photoPath = null;
    photoError = '';
  }

  void updateNotes(String value) {
    notes = value;
  }

  bool get canCheckIn =>
      currentStatus == 'checked_out' || currentStatus == 'unknown';

  bool get canCheckOut => currentStatus == 'checked_in';

  String get mainButtonText {
    if (isCheckingIn) return 'Pointage en cours...';
    if (isCheckingOut) return 'Pointage en cours...';
    if (canCheckIn) return 'Pointer l\'arrivée';
    if (canCheckOut) return 'Pointer le départ';
    return 'Pointage indisponible';
  }

  Color get mainButtonColor {
    if (canCheckIn) return Colors.green;
    if (canCheckOut) return Colors.orange;
    return Colors.grey;
  }

  IconData get mainButtonIcon {
    if (canCheckIn) return Icons.login;
    if (canCheckOut) return Icons.logout;
    return Icons.block;
  }
}
