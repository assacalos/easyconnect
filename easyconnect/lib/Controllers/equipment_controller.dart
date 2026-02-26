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

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

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
    // Chargement différé : les données sont chargées par la page (equipment_list)
    // au premier affichage pour éviter une avalanche d'appels API au binding.
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

  bool _isLoadingEquipmentsInProgress = false;

  /// Charge les équipements : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadEquipments({int page = 1}) async {
    if (_isLoadingEquipmentsInProgress) return;
    _isLoadingEquipmentsInProgress = true;
    if (page == 1) {
      isLoading.value = true;
      final cached = EquipmentService.getCachedEquipments();
      if (cached.isNotEmpty) {
        equipments.assignAll(cached);
        isLoading.value = false;
      } else {
        equipments.value = [];
      }
    }
    try {
      final loadedEquipments = await _equipmentService.getEquipments(
        status: selectedStatus.value != 'all' ? selectedStatus.value : null,
        category:
            selectedCategory.value != 'all' ? selectedCategory.value : null,
        condition:
            selectedCondition.value != 'all' ? selectedCondition.value : null,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );
      if (page == 1) {
        equipments.assignAll(loadedEquipments);
        EquipmentService.saveEquipmentsToHive(loadedEquipments);
      } else {
        equipments.addAll(loadedEquipments);
      }
      totalPages.value = 1;
      totalItems.value = loadedEquipments.length;
      hasNextPage.value = false;
      hasPreviousPage.value = false;
      currentPage.value = 1;
    } catch (e) {
      if (equipments.isEmpty) {
        final fallback = EquipmentService.getCachedEquipments();
        if (fallback.isNotEmpty) {
          equipments.assignAll(fallback);
        } else {
          final err = e.toString().toLowerCase();
          if (!err.contains('401') && !err.contains('unauthorized')) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les équipements',
              snackPosition: SnackPosition.BOTTOM,
            );
          }
        }
      }
    } finally {
      isLoading.value = false;
      _isLoadingEquipmentsInProgress = false;
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

      print('🔵 [EQUIPMENT] Début de createEquipment');
      print('📤 [EQUIPMENT] Appel du service pour créer: ${equipment.name}');

      final createdEquipment = await _equipmentService.createEquipment(
        equipment,
      );

      print(
        '📥 [EQUIPMENT] Réponse du service reçue - ID: ${createdEquipment.id}, Nom: ${createdEquipment.name}, Status: ${createdEquipment.status}',
      );

      // Vérifier que la création a vraiment réussi (l'entité a un ID)
      if (createdEquipment.id == null) {
        print('❌ [EQUIPMENT] ERREUR: Équipement créé mais sans ID');
        throw Exception(
          'L\'équipement a été créé mais sans ID. Veuillez réessayer.',
        );
      }

      // S'assurer que le statut est correct (si le backend retourne "pending", le changer en "active")
      if (createdEquipment.status.toLowerCase() == 'pending' ||
          createdEquipment.status.toLowerCase() == 'en_attente') {
        print(
          '⚠️ [EQUIPMENT] Statut "pending" détecté, changement en "active"',
        );
        final correctedEquipment = Equipment(
          id: createdEquipment.id,
          name: createdEquipment.name,
          description: createdEquipment.description,
          category: createdEquipment.category,
          status: 'active', // Forcer le statut à "active"
          condition: createdEquipment.condition,
          serialNumber: createdEquipment.serialNumber,
          model: createdEquipment.model,
          brand: createdEquipment.brand,
          location: createdEquipment.location,
          department: createdEquipment.department,
          assignedTo: createdEquipment.assignedTo,
          purchaseDate: createdEquipment.purchaseDate,
          warrantyExpiry: createdEquipment.warrantyExpiry,
          lastMaintenance: createdEquipment.lastMaintenance,
          nextMaintenance: createdEquipment.nextMaintenance,
          purchasePrice: createdEquipment.purchasePrice,
          currentValue: createdEquipment.currentValue,
          supplier: createdEquipment.supplier,
          notes: createdEquipment.notes,
          attachments: createdEquipment.attachments,
          createdAt: createdEquipment.createdAt,
          updatedAt: createdEquipment.updatedAt,
          createdBy: createdEquipment.createdBy,
          updatedBy: createdEquipment.updatedBy,
        );
        print(
          '✅ [EQUIPMENT] Équipement créé avec succès: ID ${correctedEquipment.id}, Status corrigé: ${correctedEquipment.status}',
        );

        // Utiliser l'équipement corrigé
        final equipmentToAdd = correctedEquipment;

        // Invalider le cache
        CacheHelper.clearByPrefix('equipments_');

        // Ajouter l'équipement à la liste localement (mise à jour optimiste)
        print(
          '📋 [EQUIPMENT] Ajout de l\'équipement à la liste (avant: ${equipments.length} éléments)',
        );
        equipments.insert(0, equipmentToAdd);
        print(
          '📋 [EQUIPMENT] Équipement ajouté à la liste (après: ${equipments.length} éléments), Status: ${equipmentToAdd.status}',
        );

        // Arrêter le loader immédiatement pour permettre la fermeture du formulaire
        print('⏸️ [EQUIPMENT] Arrêt du loader');
        isLoading.value = false;

        // Rafraîchir le dashboard technicien en arrière-plan
        Future.microtask(() {
          DashboardRefreshHelper.refreshTechnicienPending('equipment');
        });

        // Notifier le patron de la soumission en arrière-plan
        if (equipmentToAdd.id != null) {
          Future.microtask(() {
            NotificationHelper.notifySubmission(
              entityType: 'equipment',
              entityName: NotificationHelper.getEntityDisplayName(
                'equipment',
                equipmentToAdd,
              ),
              entityId: equipmentToAdd.id.toString(),
              route: NotificationHelper.getEntityRoute(
                'equipment',
                equipmentToAdd.id.toString(),
              ),
            );
          });
        }

        // Effacer le formulaire avant d'afficher le message de succès
        print('🧹 [EQUIPMENT] Effacement du formulaire');
        clearForm();

        // Afficher le message de succès
        print('✅ [EQUIPMENT] Affichage du message de succès');
        Get.snackbar(
          'Succès',
          'Équipement créé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );

        // Recharger la liste en arrière-plan après un court délai pour synchroniser avec le serveur
        Future.microtask(() async {
          await Future.delayed(const Duration(milliseconds: 300));
          try {
            print('🔄 [EQUIPMENT] Rechargement de la liste en arrière-plan...');
            await loadEquipments();
            await loadEquipmentStats();

            // Vérifier que l'équipement créé est toujours dans la liste après rechargement
            if (equipmentToAdd.id != null) {
              final equipmentExists = equipments.any(
                (e) => e.id == equipmentToAdd.id,
              );
              print(
                '🔍 [EQUIPMENT] Équipement ID ${equipmentToAdd.id} existe dans la liste: $equipmentExists',
              );
              if (!equipmentExists) {
                // Si l'équipement n'est pas dans la liste après rechargement, le rajouter
                print(
                  '⚠️ [EQUIPMENT] Équipement créé non trouvé après rechargement, réajout à la liste',
                );
                equipments.insert(0, equipmentToAdd);
                print(
                  '✅ [EQUIPMENT] Équipement réajouté - Liste contient maintenant ${equipments.length} éléments',
                );
              }
            }

            print('✅ [EQUIPMENT] Liste rechargée avec succès');
          } catch (e) {
            print('⚠️ [EQUIPMENT] Erreur lors du rechargement (ignorée): $e');
            print(
              '⚠️ [EQUIPMENT] Liste actuelle contient ${equipments.length} éléments',
            );
          }
        });

        print('✅ [EQUIPMENT] Retour de createEquipment: true (SUCCÈS)');
        return true;
      }

      print(
        '✅ [EQUIPMENT] Équipement créé avec succès: ID ${createdEquipment.id}, Status: ${createdEquipment.status}',
      );

      CacheHelper.clearByPrefix('equipments_');

      // Insertion locale uniquement si le filtre actuel affiche ce statut (ou "tous")
      final currentFilter = selectedStatus.value;
      final shouldInsert =
          currentFilter == 'all' || currentFilter == createdEquipment.status;
      if (shouldInsert) {
        equipments.insert(0, createdEquipment);
        EquipmentService.saveEquipmentsToHive(equipments.toList());
      }

      isLoading.value = false;
      Future.microtask(() {
        DashboardRefreshHelper.refreshTechnicienPending('equipment');
      });
      if (createdEquipment.id != null) {
        Future.microtask(() {
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
        });
      }
      clearForm();
      Get.snackbar(
        'Succès',
        'Équipement créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      // Pas de loadEquipments() pour ne pas écraser l'insertion
      return true;
    } catch (e, stackTrace) {
      print('❌ [EQUIPMENT] ERREUR CAPTURÉE dans createEquipment: $e');
      print('❌ [EQUIPMENT] Stack trace: $stackTrace');

      // S'assurer que le loader est arrêté en cas d'erreur
      isLoading.value = false;

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      print('❌ [EQUIPMENT] Affichage du message d\'erreur: $errorMessage');
      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
      print('❌ [EQUIPMENT] Retour de createEquipment: false (ÉCHEC)');
      return false;
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
