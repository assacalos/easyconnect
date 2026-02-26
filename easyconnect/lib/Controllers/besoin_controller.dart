import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/besoin_model.dart';
import 'package:easyconnect/services/besoin_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/roles.dart';

class BesoinController extends GetxController {
  final BesoinService _besoinService = BesoinService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<Besoin> besoins = <Besoin>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedStatus = 'all'.obs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final RxString reminderFrequency = 'weekly'.obs;

  bool get isTechnicien => _authController.userAuth.value?.role == Roles.TECHNICIEN;
  bool get canMarkTreated =>
      _authController.userAuth.value?.role == Roles.PATRON ||
      _authController.userAuth.value?.role == Roles.ADMIN;

  static const List<Map<String, String>> reminderOptions = [
    {'value': 'daily', 'label': 'Tous les jours'},
    {'value': 'every_2_days', 'label': 'Tous les 2 jours'},
    {'value': 'weekly', 'label': 'Toutes les semaines'},
  ];

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }

  Future<void> loadBesoins({bool forceRefresh = false}) async {
    if (isLoading.value && !forceRefresh) return;
    final status = selectedStatus.value == 'all' ? null : selectedStatus.value;

    if (!forceRefresh) {
      final hiveList = BesoinService.getCachedBesoins(status);
      if (hiveList.isNotEmpty) {
        besoins.value = hiveList;
        isLoading.value = false;
        Future.microtask(() => _refreshBesoinsFromApi(status));
        return;
      }
    }

    isLoading.value = true;
    try {
      final list = await _besoinService.getBesoins(status: status);
      besoins.value = list;
    } catch (e) {
      if (besoins.isEmpty) {
        Get.snackbar('Erreur', 'Impossible de charger les besoins: $e');
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _refreshBesoinsFromApi(String? status) async {
    try {
      final list = await _besoinService.getBesoins(status: status);
      final sameFilter = (status == null && selectedStatus.value == 'all') ||
          (status != null && selectedStatus.value == status);
      if (sameFilter) besoins.value = list;
    } catch (_) {}
  }

  Future<void> createBesoin() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      Get.snackbar('Erreur', 'Le titre est obligatoire');
      return;
    }
    isLoading.value = true;
    try {
      await _besoinService.createBesoin(
        title: title,
        description: descriptionController.text.trim().isEmpty
            ? null
            : descriptionController.text.trim(),
        reminderFrequency: reminderFrequency.value,
      );
      clearForm();
      Get.snackbar('Succès', 'Besoin enregistré. Le patron sera rappelé automatiquement.');
      Get.back();
      loadBesoins(forceRefresh: true);
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markTreated(int id, {String? note}) async {
    isLoading.value = true;
    try {
      await _besoinService.markTreated(id, treatedNote: note);
      Get.snackbar('Succès', 'Besoin marqué comme traité.');
      loadBesoins(forceRefresh: true);
    } catch (e) {
      Get.snackbar('Erreur', e.toString().replaceFirst('Exception: ', ''));
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    reminderFrequency.value = 'weekly';
  }

  void setReminderFrequency(String value) {
    reminderFrequency.value = value;
  }
}
