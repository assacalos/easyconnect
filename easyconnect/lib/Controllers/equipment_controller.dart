import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class EquipmentController extends GetxController {
  final EquipmentService _equipmentService = EquipmentService();
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxList<Equipment> equipments = <Equipment>[].obs;
  final RxList<Equipment> equipmentsNeedingMaintenance = <Equipment>[].obs;
  final RxList<Equipment> equipmentsWithExpiredWarranty = <Equipment>[].obs;
  final RxList<EquipmentCategory> equipmentCategories =
      <EquipmentCategory>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<EquipmentStats?> equipmentStats = Rx<EquipmentStats?>(null);

  // Variables pour le formulaire
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxString selectedCondition = 'all'.obs;
  final Rx<Equipment?> selectedEquipment = Rx<Equipment?>(null);

  // Contrôleurs de formulaire
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController serialNumberController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController assignedToController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController purchasePriceController = TextEditingController();
  final TextEditingController currentValueController = TextEditingController();

  // Variables de sélection
  final RxString selectedCategoryForm = 'computer'.obs;
  final RxString selectedStatusForm = 'active'.obs;
  final RxString selectedConditionForm = 'good'.obs;
  final Rx<DateTime?> selectedPurchaseDate = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedWarrantyExpiry = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedLastMaintenance = Rx<DateTime?>(null);
  final Rx<DateTime?> selectedNextMaintenance = Rx<DateTime?>(null);
  final RxList<String> selectedAttachments = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadEquipments();
    loadEquipmentStats();
    loadEquipmentCategories();
    loadEquipmentsNeedingMaintenance();
    loadEquipmentsWithExpiredWarranty();
  }

  @override
  void onClose() {
    nameController.dispose();
    descriptionController.dispose();
    serialNumberController.dispose();
    modelController.dispose();
    brandController.dispose();
    locationController.dispose();
    departmentController.dispose();
    assignedToController.dispose();
    supplierController.dispose();
    notesController.dispose();
    purchasePriceController.dispose();
    currentValueController.dispose();
    super.onClose();
  }

  // Charger tous les équipements (sans filtre pour permettre le filtrage côté client)
  Future<void> loadEquipments() async {
    try {
      isLoading.value = true;
      // Charger TOUS les équipements sans filtre pour permettre le filtrage par onglet
      final loadedEquipments = await _equipmentService.getEquipments();
      equipments.assignAll(loadedEquipments);
    } catch (e) {
      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (equipments.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'equipments_all';
          final cachedEquipments = CacheHelper.get<List<Equipment>>(cacheKey);
          if (cachedEquipments == null || cachedEquipments.isEmpty) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les équipements: ${e.toString()}',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 5),
            );
          } else {
            // Charger les données du cache si disponibles
            equipments.assignAll(cachedEquipments);
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les équipements nécessitant une maintenance
  Future<void> loadEquipmentsNeedingMaintenance() async {
    try {
      final needingMaintenance =
          await _equipmentService.getEquipmentsNeedingMaintenance();
      equipmentsNeedingMaintenance.assignAll(needingMaintenance);
    } catch (e) {}
  }

  // Charger les équipements avec garantie expirée
  Future<void> loadEquipmentsWithExpiredWarranty() async {
    try {
      final expiredWarranty =
          await _equipmentService.getEquipmentsWithExpiredWarranty();
      equipmentsWithExpiredWarranty.assignAll(expiredWarranty);
    } catch (e) {}
  }

  // Charger les catégories
  Future<void> loadEquipmentCategories() async {
    try {
      final categories = await _equipmentService.getEquipmentCategories();
      equipmentCategories.assignAll(categories);
    } catch (e) {}
  }

  // Charger les statistiques
  Future<void> loadEquipmentStats() async {
    try {
      final stats = await _equipmentService.getEquipmentStats();
      equipmentStats.value = stats;
    } catch (e) {}
  }

  // Créer un équipement
  Future<bool> createEquipment() async {
    try {
      isLoading.value = true;

      final equipment = Equipment(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm.value,
        status: selectedStatusForm.value,
        condition: selectedConditionForm.value,
        serialNumber:
            serialNumberController.text.trim().isEmpty
                ? null
                : serialNumberController.text.trim(),
        model:
            modelController.text.trim().isEmpty
                ? null
                : modelController.text.trim(),
        brand:
            brandController.text.trim().isEmpty
                ? null
                : brandController.text.trim(),
        location:
            locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
        department:
            departmentController.text.trim().isEmpty
                ? null
                : departmentController.text.trim(),
        assignedTo:
            assignedToController.text.trim().isEmpty
                ? null
                : assignedToController.text.trim(),
        supplier:
            supplierController.text.trim().isEmpty
                ? null
                : supplierController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        purchaseDate: selectedPurchaseDate.value,
        warrantyExpiry: selectedWarrantyExpiry.value,
        lastMaintenance: selectedLastMaintenance.value,
        nextMaintenance: selectedNextMaintenance.value,
        purchasePrice: double.tryParse(purchasePriceController.text),
        currentValue: double.tryParse(currentValueController.text),
        attachments: selectedAttachments.isEmpty ? null : selectedAttachments,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final createdEquipment = await _equipmentService.createEquipment(
        equipment,
      );

      // Attendre un peu pour que l'API mette à jour
      await Future.delayed(const Duration(milliseconds: 500));

      await loadEquipments();
      await loadEquipmentStats();

      // Rafraîchir le dashboard technicien en arrière-plan
      DashboardRefreshHelper.refreshTechnicienPending('equipment');

      // Notifier le patron de la soumission
      if (createdEquipment.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'equipment',
          entityName: NotificationHelper.getEntityDisplayName(
            'equipment',
            createdEquipment,
          ),
          entityId: createdEquipment.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'equipment',
            createdEquipment.id.toString(),
          ),
        );
      }

      clearForm();

      Get.snackbar(
        'Succès',
        'Équipement créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer l\'équipement: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour un équipement
  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      isLoading.value = true;

      final updatedEquipment = Equipment(
        id: equipment.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm.value,
        status: selectedStatusForm.value,
        condition: selectedConditionForm.value,
        serialNumber:
            serialNumberController.text.trim().isEmpty
                ? null
                : serialNumberController.text.trim(),
        model:
            modelController.text.trim().isEmpty
                ? null
                : modelController.text.trim(),
        brand:
            brandController.text.trim().isEmpty
                ? null
                : brandController.text.trim(),
        location:
            locationController.text.trim().isEmpty
                ? null
                : locationController.text.trim(),
        department:
            departmentController.text.trim().isEmpty
                ? null
                : departmentController.text.trim(),
        assignedTo:
            assignedToController.text.trim().isEmpty
                ? null
                : assignedToController.text.trim(),
        supplier:
            supplierController.text.trim().isEmpty
                ? null
                : supplierController.text.trim(),
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        purchaseDate: selectedPurchaseDate.value ?? equipment.purchaseDate,
        warrantyExpiry:
            selectedWarrantyExpiry.value ?? equipment.warrantyExpiry,
        lastMaintenance:
            selectedLastMaintenance.value ?? equipment.lastMaintenance,
        nextMaintenance:
            selectedNextMaintenance.value ?? equipment.nextMaintenance,
        purchasePrice:
            double.tryParse(purchasePriceController.text) ??
            equipment.purchasePrice,
        currentValue:
            double.tryParse(currentValueController.text) ??
            equipment.currentValue,
        attachments:
            selectedAttachments.isEmpty
                ? equipment.attachments
                : selectedAttachments,
        createdAt: equipment.createdAt,
        updatedAt: DateTime.now(),
        createdBy: equipment.createdBy,
        updatedBy: _authController.userAuth.value?.id,
      );

      await _equipmentService.updateEquipment(updatedEquipment);
      await loadEquipments();
      await loadEquipmentStats();

      // Rafraîchir le dashboard technicien en arrière-plan
      DashboardRefreshHelper.refreshTechnicienPending('equipment');

      clearForm();

      Get.snackbar(
        'Succès',
        'Équipement mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'équipement',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer un équipement
  Future<void> deleteEquipment(Equipment equipment) async {
    try {
      isLoading.value = true;

      final success = await _equipmentService.deleteEquipment(equipment.id!);
      if (success) {
        equipments.removeWhere((e) => e.id == equipment.id);
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        Get.snackbar(
          'Succès',
          'Équipement supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer l\'équipement',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour le statut d'un équipement
  Future<void> updateEquipmentStatus(Equipment equipment, String status) async {
    try {
      isLoading.value = true;

      final success = await _equipmentService.updateEquipmentStatus(
        equipment.id!,
        status,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        Get.snackbar(
          'Succès',
          'Statut mis à jour avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la mise à jour du statut');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le statut',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<void> updateEquipmentCondition(
    Equipment equipment,
    String condition,
  ) async {
    try {
      isLoading.value = true;

      final success = await _equipmentService.updateEquipmentCondition(
        equipment.id!,
        condition,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        Get.snackbar(
          'Succès',
          'État mis à jour avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'état');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour l\'état',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Assigner un équipement
  Future<void> assignEquipment(Equipment equipment, String assignedTo) async {
    try {
      isLoading.value = true;

      final success = await _equipmentService.assignEquipment(
        equipment.id!,
        assignedTo,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        Get.snackbar(
          'Succès',
          'Équipement assigné avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'assignation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'assigner l\'équipement',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Désassigner un équipement
  Future<void> unassignEquipment(Equipment equipment) async {
    try {
      isLoading.value = true;

      final success = await _equipmentService.unassignEquipment(equipment.id!);
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        Get.snackbar(
          'Succès',
          'Équipement désassigné avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la désassignation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de désassigner l\'équipement',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remplir le formulaire avec les données d'un équipement
  void fillForm(Equipment equipment) {
    nameController.text = equipment.name;
    descriptionController.text = equipment.description;
    selectedCategoryForm.value = equipment.category;
    selectedStatusForm.value = equipment.status;
    selectedConditionForm.value = equipment.condition;
    serialNumberController.text = equipment.serialNumber ?? '';
    modelController.text = equipment.model ?? '';
    brandController.text = equipment.brand ?? '';
    locationController.text = equipment.location ?? '';
    departmentController.text = equipment.department ?? '';
    assignedToController.text = equipment.assignedTo ?? '';
    supplierController.text = equipment.supplier ?? '';
    notesController.text = equipment.notes ?? '';
    purchasePriceController.text = equipment.purchasePrice?.toString() ?? '';
    currentValueController.text = equipment.currentValue?.toString() ?? '';
    selectedPurchaseDate.value = equipment.purchaseDate;
    selectedWarrantyExpiry.value = equipment.warrantyExpiry;
    selectedLastMaintenance.value = equipment.lastMaintenance;
    selectedNextMaintenance.value = equipment.nextMaintenance;
    selectedAttachments.assignAll(equipment.attachments ?? []);
    selectedEquipment.value = equipment;
  }

  // Vider le formulaire
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedCategoryForm.value = 'computer';
    selectedStatusForm.value = 'active';
    selectedConditionForm.value = 'good';
    serialNumberController.clear();
    modelController.clear();
    brandController.clear();
    locationController.clear();
    departmentController.clear();
    assignedToController.clear();
    supplierController.clear();
    notesController.clear();
    purchasePriceController.clear();
    currentValueController.clear();
    selectedPurchaseDate.value = null;
    selectedWarrantyExpiry.value = null;
    selectedLastMaintenance.value = null;
    selectedNextMaintenance.value = null;
    selectedAttachments.clear();
    selectedEquipment.value = null;
  }

  // Rechercher
  void searchEquipments(String query) {
    searchQuery.value = query;
    loadEquipments();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadEquipments();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategory.value = category;
    loadEquipments();
  }

  // Filtrer par état
  void filterByCondition(String condition) {
    selectedCondition.value = condition;
    loadEquipments();
  }

  // Sélectionner la catégorie
  void selectCategory(String category) {
    selectedCategoryForm.value = category;
  }

  // Sélectionner le statut
  void selectStatus(String status) {
    selectedStatusForm.value = status;
  }

  // Sélectionner l'état
  void selectCondition(String condition) {
    selectedConditionForm.value = condition;
  }

  // Sélectionner la date d'achat
  void selectPurchaseDate(DateTime date) {
    selectedPurchaseDate.value = date;
  }

  // Sélectionner la date d'expiration de garantie
  void selectWarrantyExpiry(DateTime date) {
    selectedWarrantyExpiry.value = date;
  }

  // Sélectionner la date de dernière maintenance
  void selectLastMaintenance(DateTime date) {
    selectedLastMaintenance.value = date;
  }

  // Sélectionner la date de prochaine maintenance
  void selectNextMaintenance(DateTime date) {
    selectedNextMaintenance.value = date;
  }

  // Obtenir les catégories d'équipements
  List<Map<String, dynamic>> get equipmentCategoriesList => [
    {
      'value': 'computer',
      'label': 'Ordinateur',
      'icon': Icons.computer,
      'color': Colors.blue,
    },
    {
      'value': 'printer',
      'label': 'Imprimante',
      'icon': Icons.print,
      'color': Colors.green,
    },
    {
      'value': 'network',
      'label': 'Réseau',
      'icon': Icons.router,
      'color': Colors.orange,
    },
    {
      'value': 'server',
      'label': 'Serveur',
      'icon': Icons.dns,
      'color': Colors.purple,
    },
    {
      'value': 'mobile',
      'label': 'Mobile',
      'icon': Icons.phone_android,
      'color': Colors.teal,
    },
    {
      'value': 'tablet',
      'label': 'Tablette',
      'icon': Icons.tablet,
      'color': Colors.indigo,
    },
    {
      'value': 'monitor',
      'label': 'Écran',
      'icon': Icons.monitor,
      'color': Colors.cyan,
    },
    {
      'value': 'other',
      'label': 'Autre',
      'icon': Icons.devices_other,
      'color': Colors.grey,
    },
  ];

  // Obtenir les statuts
  List<Map<String, dynamic>> get statuses => [
    {'value': 'pending', 'label': 'En attente', 'color': Colors.amber},
    {'value': 'active', 'label': 'Actif', 'color': Colors.green},
    {'value': 'inactive', 'label': 'Inactif', 'color': Colors.grey},
    {'value': 'maintenance', 'label': 'En maintenance', 'color': Colors.orange},
    {'value': 'broken', 'label': 'Hors service', 'color': Colors.red},
    {'value': 'retired', 'label': 'Retiré', 'color': Colors.purple},
  ];

  // Obtenir les états
  List<Map<String, dynamic>> get conditions => [
    {'value': 'excellent', 'label': 'Excellent', 'color': Colors.green},
    {'value': 'good', 'label': 'Bon', 'color': Colors.blue},
    {'value': 'fair', 'label': 'Correct', 'color': Colors.orange},
    {'value': 'poor', 'label': 'Mauvais', 'color': Colors.red},
    {'value': 'critical', 'label': 'Critique', 'color': Colors.red[800]!},
  ];

  // Vérifier les permissions
  bool get canManageEquipments {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 6; // Admin, Technicien
  }

  bool get canViewEquipments {
    final userRole = _authController.userAuth.value?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les équipements par statut
  List<Equipment> get equipmentsByStatus {
    if (selectedStatus.value == 'all') return equipments;
    return equipments
        .where((equipment) => equipment.status == selectedStatus.value)
        .toList();
  }

  // Obtenir les équipements par catégorie
  List<Equipment> get equipmentsByCategory {
    if (selectedCategory.value == 'all') return equipments;
    return equipments
        .where((equipment) => equipment.category == selectedCategory.value)
        .toList();
  }

  // Obtenir les équipements filtrés
  List<Equipment> get filteredEquipments {
    List<Equipment> filtered = equipments;

    if (selectedStatus.value != 'all') {
      filtered =
          filtered
              .where((equipment) => equipment.status == selectedStatus.value)
              .toList();
    }

    if (selectedCategory.value != 'all') {
      filtered =
          filtered
              .where(
                (equipment) => equipment.category == selectedCategory.value,
              )
              .toList();
    }

    if (selectedCondition.value != 'all') {
      filtered =
          filtered
              .where(
                (equipment) => equipment.condition == selectedCondition.value,
              )
              .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (equipment) =>
                    equipment.name.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    equipment.description.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    (equipment.serialNumber?.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ) ??
                        false) ||
                    (equipment.model?.toLowerCase().contains(
                          searchQuery.value.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }
}
