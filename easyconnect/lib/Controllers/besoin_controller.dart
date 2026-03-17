import 'package:flutter/material.dart';
import 'package:easyconnect/Models/besoin_model.dart';
import 'package:easyconnect/services/besoin_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/error_helper.dart';

class BesoinController {
  static final BesoinController _instance = BesoinController._();
  static BesoinController get to => _instance;
  factory BesoinController() => _instance;
  BesoinController._();

  final BesoinService _besoinService = BesoinService();
  final AuthController _authController = AuthController.to;

  final List<Besoin> besoins = [];
  bool isLoading = false;
  String selectedStatus = 'all';

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  String reminderFrequency = 'weekly';

  bool get isTechnicien => _authController.userAuth?.role == Roles.TECHNICIEN;
  bool get canMarkTreated =>
      _authController.userAuth?.role == Roles.PATRON ||
      _authController.userAuth?.role == Roles.ADMIN;

  static const List<Map<String, String>> reminderOptions = [
    {'value': 'daily', 'label': 'Tous les jours'},
    {'value': 'every_2_days', 'label': 'Tous les 2 jours'},
    {'value': 'weekly', 'label': 'Toutes les semaines'},
  ];

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
  }

  Future<void> loadBesoins({bool forceRefresh = false}) async {
    if (isLoading && !forceRefresh) return;
    final status = selectedStatus == 'all' ? null : selectedStatus;

    if (!forceRefresh) {
      final hiveList = BesoinService.getCachedBesoins(status);
      if (hiveList.isNotEmpty) {
        besoins.clear();
        besoins.addAll(hiveList);
        isLoading = false;
        Future.microtask(() => _refreshBesoinsFromApi(status));
        return;
      }
    }

    isLoading = true;
    try {
      final list = await _besoinService.getBesoins(status: status);
      besoins.clear();
      besoins.addAll(list);
    } catch (e) {
      if (besoins.isEmpty) {
        errorHelperShowSnackbar?.call('Erreur', 'Impossible de charger les besoins: $e');
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refreshBesoinsFromApi(String? status) async {
    try {
      final list = await _besoinService.getBesoins(status: status);
      final sameFilter = (status == null && selectedStatus == 'all') ||
          (status != null && selectedStatus == status);
      if (sameFilter) {
        besoins.clear();
        besoins.addAll(list);
      }
    } catch (_) {}
  }

  Future<void> createBesoin() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      errorHelperShowSnackbar?.call('Erreur', 'Le titre est obligatoire');
      return;
    }
    isLoading = true;
    try {
      await _besoinService.createBesoin(
        title: title,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        reminderFrequency: reminderFrequency,
      );
      clearForm();
      ErrorHelper.showSuccess('Besoin enregistré. Le patron sera rappelé automatiquement.');
      loadBesoins(forceRefresh: true);
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading = false;
    }
  }

  Future<void> markTreated(int id, {String? note}) async {
    isLoading = true;
    try {
      await _besoinService.markTreated(id, treatedNote: note);
      ErrorHelper.showSuccess('Besoin marqué comme traité.');
      loadBesoins(forceRefresh: true);
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading = false;
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    reminderFrequency = 'weekly';
  }

  void setReminderFrequency(String value) {
    reminderFrequency = value;
  }
}
