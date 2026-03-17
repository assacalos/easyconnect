import 'package:flutter/material.dart';
import 'package:easyconnect/Models/equipment_model.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class EquipmentController {
  static final EquipmentController _instance = EquipmentController._();
  static EquipmentController get to => _instance;
  factory EquipmentController() => _instance;
  EquipmentController._();

  final EquipmentService _equipmentService = EquipmentService();

  // Variables
  final List<Equipment> equipments = [];
  final List<Equipment> equipmentsNeedingMaintenance = [];
  final List<Equipment> equipmentsWithExpiredWarranty = [];
  final List<EquipmentCategory> equipmentCategories = [];
  bool isLoading = false;
  EquipmentStats? equipmentStats;

  // Variables pour le formulaire
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedCategory = 'all';
  String selectedCondition = 'all';
  Equipment? selectedEquipment;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;

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
  String selectedCategoryForm = 'computer';
  String selectedStatusForm = 'active';
  String selectedConditionForm = 'good';
  DateTime? selectedPurchaseDate;
  DateTime? selectedWarrantyExpiry;
  DateTime? selectedLastMaintenance;
  DateTime? selectedNextMaintenance;
  final List<String> selectedAttachments = [];

  void dispose() {
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
  }

  bool _isLoadingEquipmentsInProgress = false;

  /// Charge les équipements : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadEquipments({int page = 1, bool forceRefresh = false}) async {
    if (_isLoadingEquipmentsInProgress) return;
    _isLoadingEquipmentsInProgress = true;
    if (page == 1) {
      isLoading = true;
      if (!forceRefresh) {
        final cached = EquipmentService.getCachedEquipments();
        if (cached.isNotEmpty) {
          equipments.clear();
          equipments.addAll(cached);
          isLoading = false;
        } else {
          equipments.clear();
        }
      } else {
        equipments.clear();
      }
    }
    try {
      final loadedEquipments = await _equipmentService.getEquipments(
        status: selectedStatus != 'all' ? selectedStatus : null,
        category:
            selectedCategory != 'all' ? selectedCategory : null,
        condition:
            selectedCondition != 'all' ? selectedCondition : null,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      if (page == 1) {
        equipments.clear();
        equipments.addAll(loadedEquipments);
        EquipmentService.saveEquipmentsToHive(loadedEquipments);
      } else {
        equipments.addAll(loadedEquipments);
      }
      totalPages = 1;
      totalItems = loadedEquipments.length;
      hasNextPage = false;
      hasPreviousPage = false;
      currentPage = 1;
    } catch (e) {
      if (equipments.isEmpty) {
        final fallback = EquipmentService.getCachedEquipments();
        if (fallback.isNotEmpty) {
          equipments.clear();
          equipments.addAll(fallback);
        } else {
          final err = e.toString().toLowerCase();
          if (!err.contains('401') && !err.contains('unauthorized')) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les équipements',
            );
          }
        }
      }
    } finally {
      isLoading = false;
      _isLoadingEquipmentsInProgress = false;
    }
  }

  // Charger les équipements nécessitant une maintenance
  Future<void> loadEquipmentsNeedingMaintenance() async {
    try {
      final needingMaintenance =
          await _equipmentService.getEquipmentsNeedingMaintenance();
      equipmentsNeedingMaintenance.clear();
      equipmentsNeedingMaintenance.addAll(needingMaintenance);
    } catch (e) {}
  }

  // Charger les équipements avec garantie expirée
  Future<void> loadEquipmentsWithExpiredWarranty() async {
    try {
      final expiredWarranty =
          await _equipmentService.getEquipmentsWithExpiredWarranty();
      equipmentsWithExpiredWarranty.clear();
      equipmentsWithExpiredWarranty.addAll(expiredWarranty);
    } catch (e) {}
  }

  // Charger les catégories
  Future<void> loadEquipmentCategories() async {
    try {
      final categories = await _equipmentService.getEquipmentCategories();
      equipmentCategories.clear();
      equipmentCategories.addAll(categories);
    } catch (e) {}
  }

  // Charger les statistiques
  Future<void> loadEquipmentStats() async {
    try {
      final stats = await _equipmentService.getEquipmentStats();
      equipmentStats = stats;
    } catch (e) {}
  }

  // Créer un équipement
  Future<bool> createEquipment() async {
    try {
      isLoading = true;

      final equipment = Equipment(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm,
        status: selectedStatusForm,
        condition: selectedConditionForm,
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
        purchaseDate: selectedPurchaseDate,
        warrantyExpiry: selectedWarrantyExpiry,
        lastMaintenance: selectedLastMaintenance,
        nextMaintenance: selectedNextMaintenance,
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
        isLoading = false;

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
        errorHelperShowSnackbar?.call(
          'Succès',
          'Équipement créé avec succès',
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
      final currentFilter = selectedStatus;
      final shouldInsert =
          currentFilter == 'all' || currentFilter == createdEquipment.status;
      if (shouldInsert) {
        equipments.insert(0, createdEquipment);
        EquipmentService.saveEquipmentsToHive(equipments.toList());
      }

      isLoading = false;
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
      errorHelperShowSnackbar?.call(
        'Succès',
        'Équipement créé avec succès',
        duration: const Duration(seconds: 2),
      );
      // Pas de loadEquipments() pour ne pas écraser l'insertion
      return true;
    } catch (e, stackTrace) {
      print('❌ [EQUIPMENT] ERREUR CAPTURÉE dans createEquipment: $e');
      print('❌ [EQUIPMENT] Stack trace: $stackTrace');

      // S'assurer que le loader est arrêté en cas d'erreur
      isLoading = false;

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      print('❌ [EQUIPMENT] Affichage du message d\'erreur: $errorMessage');
      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        duration: const Duration(seconds: 5),
      );
      print('❌ [EQUIPMENT] Retour de createEquipment: false (ÉCHEC)');
      return false;
    }
  }

  // Mettre à jour un équipement
  Future<bool> updateEquipment(Equipment equipment) async {
    try {
      isLoading = true;

      final updatedEquipment = Equipment(
        id: equipment.id,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm,
        status: selectedStatusForm,
        condition: selectedConditionForm,
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
        purchaseDate: selectedPurchaseDate ?? equipment.purchaseDate,
        warrantyExpiry:
            selectedWarrantyExpiry ?? equipment.warrantyExpiry,
        lastMaintenance:
            selectedLastMaintenance ?? equipment.lastMaintenance,
        nextMaintenance:
            selectedNextMaintenance ?? equipment.nextMaintenance,
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
        updatedBy: AuthController.to.userAuth?.id,
      );

      await _equipmentService.updateEquipment(updatedEquipment);
      await loadEquipments();
      await loadEquipmentStats();

      // Rafraîchir le dashboard technicien en arrière-plan
      DashboardRefreshHelper.refreshTechnicienPending('equipment');

      clearForm();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Équipement mis à jour avec succès',
        duration: const Duration(seconds: 2),
      );

      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour l\'équipement',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Supprimer un équipement
  Future<void> deleteEquipment(Equipment equipment) async {
    try {
      isLoading = true;

      final success = await _equipmentService.deleteEquipment(equipment.id!);
      if (success) {
        equipments.removeWhere((e) => e.id == equipment.id);
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        errorHelperShowSnackbar?.call(
          'Succès',
          'Équipement supprimé avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer l\'équipement',
      );
    } finally {
      isLoading = false;
    }
  }

  // Mettre à jour le statut d'un équipement
  Future<void> updateEquipmentStatus(Equipment equipment, String status) async {
    try {
      isLoading = true;

      final success = await _equipmentService.updateEquipmentStatus(
        equipment.id!,
        status,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        errorHelperShowSnackbar?.call(
          'Succès',
          'Statut mis à jour avec succès',
        );
      } else {
        throw Exception('Erreur lors de la mise à jour du statut');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le statut',
      );
    } finally {
      isLoading = false;
    }
  }

  // Mettre à jour l'état d'un équipement
  Future<void> updateEquipmentCondition(
    Equipment equipment,
    String condition,
  ) async {
    try {
      isLoading = true;

      final success = await _equipmentService.updateEquipmentCondition(
        equipment.id!,
        condition,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        errorHelperShowSnackbar?.call(
          'Succès',
          'État mis à jour avec succès',
        );
      } else {
        throw Exception('Erreur lors de la mise à jour de l\'état');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour l\'état',
      );
    } finally {
      isLoading = false;
    }
  }

  // Assigner un équipement
  Future<void> assignEquipment(Equipment equipment, String assignedTo) async {
    try {
      isLoading = true;

      final success = await _equipmentService.assignEquipment(
        equipment.id!,
        assignedTo,
      );
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        errorHelperShowSnackbar?.call(
          'Succès',
          'Équipement assigné avec succès',
        );
      } else {
        throw Exception('Erreur lors de l\'assignation');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible d\'assigner l\'équipement',
      );
    } finally {
      isLoading = false;
    }
  }

  // Désassigner un équipement
  Future<void> unassignEquipment(Equipment equipment) async {
    try {
      isLoading = true;

      final success = await _equipmentService.unassignEquipment(equipment.id!);
      if (success) {
        await loadEquipments();
        await loadEquipmentStats();

        // Rafraîchir le dashboard technicien en arrière-plan
        DashboardRefreshHelper.refreshTechnicienPending('equipment');

        errorHelperShowSnackbar?.call(
          'Succès',
          'Équipement désassigné avec succès',
        );
      } else {
        throw Exception('Erreur lors de la désassignation');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de désassigner l\'équipement',
      );
    } finally {
      isLoading = false;
    }
  }

  // Remplir le formulaire avec les données d'un équipement
  void fillForm(Equipment equipment) {
    nameController.text = equipment.name;
    descriptionController.text = equipment.description;
    selectedCategoryForm = equipment.category;
    selectedStatusForm = equipment.status;
    selectedConditionForm = equipment.condition;
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
    selectedPurchaseDate = equipment.purchaseDate;
    selectedWarrantyExpiry = equipment.warrantyExpiry;
    selectedLastMaintenance = equipment.lastMaintenance;
    selectedNextMaintenance = equipment.nextMaintenance;
    selectedAttachments.clear();
    selectedAttachments.addAll(equipment.attachments ?? []);
    selectedEquipment = equipment;
  }

  // Vider le formulaire
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedCategoryForm = 'computer';
    selectedStatusForm = 'active';
    selectedConditionForm = 'good';
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
    selectedPurchaseDate = null;
    selectedWarrantyExpiry = null;
    selectedLastMaintenance = null;
    selectedNextMaintenance = null;
    selectedAttachments.clear();
    selectedEquipment = null;
  }

  // Rechercher
  void searchEquipments(String query) {
    searchQuery = query;
    loadEquipments();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadEquipments();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategory = category;
    loadEquipments();
  }

  // Filtrer par état
  void filterByCondition(String condition) {
    selectedCondition = condition;
    loadEquipments();
  }

  // Sélectionner la catégorie
  void selectCategory(String category) {
    selectedCategoryForm = category;
  }

  // Sélectionner le statut
  void selectStatus(String status) {
    selectedStatusForm = status;
  }

  // Sélectionner l'état
  void selectCondition(String condition) {
    selectedConditionForm = condition;
  }

  // Sélectionner la date d'achat
  void selectPurchaseDate(DateTime date) {
    selectedPurchaseDate = date;
  }

  // Sélectionner la date d'expiration de garantie
  void selectWarrantyExpiry(DateTime date) {
    selectedWarrantyExpiry = date;
  }

  // Sélectionner la date de dernière maintenance
  void selectLastMaintenance(DateTime date) {
    selectedLastMaintenance = date;
  }

  // Sélectionner la date de prochaine maintenance
  void selectNextMaintenance(DateTime date) {
    selectedNextMaintenance = date;
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
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 6; // Admin, Technicien
  }

  bool get canViewEquipments {
    final userRole = AuthController.to.userAuth?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les équipements par statut
  List<Equipment> get equipmentsByStatus {
    if (selectedStatus == 'all') return equipments;
    return equipments
        .where((equipment) => equipment.status == selectedStatus)
        .toList();
  }

  // Obtenir les équipements par catégorie
  List<Equipment> get equipmentsByCategory {
    if (selectedCategory == 'all') return equipments;
    return equipments
        .where((equipment) => equipment.category == selectedCategory)
        .toList();
  }

  // Obtenir les équipements filtrés
  List<Equipment> get filteredEquipments {
    List<Equipment> filtered = equipments;

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where((equipment) => equipment.status == selectedStatus)
              .toList();
    }

    if (selectedCategory != 'all') {
      filtered =
          filtered
              .where(
                (equipment) => equipment.category == selectedCategory,
              )
              .toList();
    }

    if (selectedCondition != 'all') {
      filtered =
          filtered
              .where(
                (equipment) => equipment.condition == selectedCondition,
              )
              .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (equipment) =>
                    equipment.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    equipment.description.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    (equipment.serialNumber?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false) ||
                    (equipment.model?.toLowerCase().contains(
                          searchQuery.toLowerCase(),
                        ) ??
                        false),
              )
              .toList();
    }

    return filtered;
  }
}
