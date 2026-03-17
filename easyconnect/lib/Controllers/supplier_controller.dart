import 'package:flutter/material.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class SupplierController {
  static final SupplierController _instance = SupplierController._();
  static SupplierController get to => _instance;
  factory SupplierController() => _instance;
  SupplierController._();

  final SupplierService _supplierService = SupplierService.to;

  // Variables
  final List<Supplier> allSuppliers = [];
  final List<Supplier> suppliers = [];
  bool isLoading = false;
  SupplierStats? supplierStats;

  // Variables pour les filtres
  String searchQuery = '';
  String selectedStatus = 'all';

  // Permissions
  bool get canCreateSuppliers => true;
  bool get canApproveSuppliers => true;

  // Contrôleurs de formulaire
  final TextEditingController nomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController telephoneController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController villeController = TextEditingController();
  final TextEditingController paysController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController commentairesController = TextEditingController();

  void ensureInitialized() {
    loadSuppliers();
    loadSupplierStats();
  }

  void dispose() {
    nomController.dispose();
    emailController.dispose();
    telephoneController.dispose();
    adresseController.dispose();
    villeController.dispose();
    paysController.dispose();
    descriptionController.dispose();
    commentairesController.dispose();
  }

  // Charger tous les fournisseurs
  Future<void> loadSuppliers() async {
    const cacheKey = 'suppliers_all';
    try {
      final hiveList = SupplierService.getCachedFournisseurs();
      if (hiveList.isNotEmpty) {
        allSuppliers.clear();
        allSuppliers.addAll(hiveList);
        applyFilters();
        isLoading = false;
        Future.microtask(() => _refreshSuppliersFromApi());
        return;
      }
      final cachedSuppliers = CacheHelper.get<List<Supplier>>(cacheKey);
      if (cachedSuppliers != null && cachedSuppliers.isNotEmpty) {
        allSuppliers.clear();
        allSuppliers.addAll(cachedSuppliers);
        applyFilters();
        isLoading = false;
        Future.microtask(() => _refreshSuppliersFromApi());
        return;
      }
      isLoading = true;

      final loadedSuppliers = await _supplierService.getSuppliers(
        status: null,
        search: null,
      );

      allSuppliers.clear();
      allSuppliers.addAll(loadedSuppliers);
      CacheHelper.set(
        cacheKey,
        loadedSuppliers,
        duration: AppConfig.mediumCacheDuration,
      );
      applyFilters();
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (allSuppliers.isEmpty) {
          const cacheKey = 'suppliers_all';
          final cachedSuppliers = CacheHelper.get<List<Supplier>>(cacheKey);
          if (cachedSuppliers == null || cachedSuppliers.isEmpty) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les fournisseurs',
            );
          } else {
            allSuppliers.clear();
            allSuppliers.addAll(cachedSuppliers);
            applyFilters();
          }
        }
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> _refreshSuppliersFromApi() async {
    try {
      const cacheKey = 'suppliers_all';
      final loadedSuppliers = await _supplierService.getSuppliers(
        status: null,
        search: null,
      );
      allSuppliers.clear();
      allSuppliers.addAll(loadedSuppliers);
      CacheHelper.set(
        cacheKey,
        loadedSuppliers,
        duration: AppConfig.mediumCacheDuration,
      );
      applyFilters();
    } catch (_) {}
  }

  Future<void> loadSupplierStats() async {
    try {
      supplierStats = await _supplierService.getSupplierStats();
    } catch (e) {}
  }

  void applyFilters() {
    List<Supplier> filteredSuppliers = List.from(allSuppliers);

    if (selectedStatus != 'all') {
      filteredSuppliers =
          filteredSuppliers.where((supplier) => supplier.statut == selectedStatus).toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredSuppliers =
          filteredSuppliers.where((supplier) {
            return supplier.nom.toLowerCase().contains(query) ||
                supplier.email.toLowerCase().contains(query) ||
                supplier.telephone.toLowerCase().contains(query) ||
                supplier.ville.toLowerCase().contains(query) ||
                supplier.pays.toLowerCase().contains(query);
          }).toList();
    }

    suppliers.clear();
    suppliers.addAll(filteredSuppliers);
  }

  void searchSuppliers(String query) {
    searchQuery = query;
    applyFilters();
  }

  void filterByStatus(String status) {
    selectedStatus = status;
    applyFilters();
  }

  Future<bool> createSupplier() async {
    try {
      isLoading = true;

      final supplier = Supplier(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
        statut: 'en_attente',
      );

      final createdSupplier = await _supplierService.createSupplier(supplier);

      CacheHelper.clearByPrefix('suppliers_');

      if (createdSupplier.id != null) {
        suppliers.add(createdSupplier);
        allSuppliers.add(createdSupplier);
        NotificationHelper.notifySubmission(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName(
            'supplier',
            createdSupplier,
          ),
          entityId: createdSupplier.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'supplier',
            createdSupplier.id.toString(),
          ),
        );
      }

      await loadSuppliers();
      await loadSupplierStats();
      DashboardRefreshHelper.refreshPatronCounter('supplier');

      errorHelperShowSnackbar?.call(
        'Succès',
        'Fournisseur créé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer le fournisseur: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      isLoading = true;

      final updatedSupplier = supplier.copyWith(
        nom: nomController.text.trim(),
        email: emailController.text.trim(),
        telephone: telephoneController.text.trim(),
        adresse: adresseController.text.trim(),
        ville: villeController.text.trim(),
        pays: paysController.text.trim(),
        description:
            descriptionController.text.trim().isEmpty
                ? null
                : descriptionController.text.trim(),
        commentaires:
            commentairesController.text.trim().isEmpty
                ? null
                : commentairesController.text.trim(),
      );

      await _supplierService.updateSupplier(updatedSupplier);
      await loadSuppliers();
      await loadSupplierStats();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Fournisseur mis à jour avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le fournisseur: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteSupplier(Supplier supplier) async {
    try {
      isLoading = true;

      final success = await _supplierService.deleteSupplier(supplier.id!);
      if (success) {
        await loadSuppliers();
        await loadSupplierStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Fournisseur supprimé avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le fournisseur',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> approveSupplier(
    Supplier supplier, {
    String? validationComment,
  }) async {
    int supplierIndex = -1;
    Supplier? originalSupplier;
    try {
      isLoading = true;

      supplierIndex = allSuppliers.indexWhere((s) => s.id == supplier.id);
      if (supplierIndex != -1) {
        originalSupplier = allSuppliers[supplierIndex];
        if (supplier.isPending) {
          allSuppliers.removeAt(supplierIndex);
        }
      }

      final success = await _supplierService.approveSupplier(
        supplier.id!,
        validationComment: validationComment,
      );

      if (success) {
        CacheHelper.clearByPrefix('suppliers_');
        NotificationHelper.notifyValidation(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName(
            'supplier',
            supplier,
          ),
          entityId: supplier.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'supplier',
            supplier.id.toString(),
          ),
          entity: supplier,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Fournisseur validé avec succès',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Future.microtask(() async {
          await loadSuppliers();
          await loadSupplierStats();
        });
      } else {
        if (originalSupplier != null && supplierIndex != -1) {
          allSuppliers.insert(supplierIndex, originalSupplier);
        }
        errorHelperShowSnackbar?.call(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      if (supplierIndex != -1 && originalSupplier != null) {
        allSuppliers.insert(supplierIndex, originalSupplier);
        applyFilters();
      }

      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('401') &&
          !errorStr.contains('403') &&
          !errorStr.contains('unauthorized') &&
          !errorStr.contains('forbidden')) {
        if (errorStr.contains('validé') ||
            errorStr.contains('approuvé') ||
            errorStr.contains('validated') ||
            errorStr.contains('approved')) {
          CacheHelper.clearByPrefix('suppliers_');
          Future.microtask(() async {
            await loadSuppliers();
            await loadSupplierStats();
          });
          errorHelperShowSnackbar?.call(
            'Succès',
            'Fournisseur validé avec succès',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          errorHelperShowSnackbar?.call(
            'Attention',
            'La validation peut avoir réussi. Veuillez vérifier.',
            duration: const Duration(seconds: 2),
          );
        }
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectSupplier(
    Supplier supplier, {
    required String rejectionReason,
    String? rejectionComment,
  }) async {
    try {
      isLoading = true;

      final success = await _supplierService.rejectSupplier(
        supplier.id!,
        rejectionReason: rejectionReason,
        rejectionComment: rejectionComment,
      );

      if (success) {
        await loadSuppliers();
        await loadSupplierStats();

        NotificationHelper.notifyRejection(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName(
            'supplier',
            supplier,
          ),
          entityId: supplier.id.toString(),
          reason: rejectionReason,
          route: NotificationHelper.getEntityRoute(
            'supplier',
            supplier.id.toString(),
          ),
          entity: supplier,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Fournisseur rejeté',
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception(
          'Erreur lors du rejet - La réponse du serveur indique un échec',
        );
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de rejeter le fournisseur: $errorMessage',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  void fillForm(Supplier supplier) {
    nomController.text = supplier.nom;
    emailController.text = supplier.email;
    telephoneController.text = supplier.telephone;
    adresseController.text = supplier.adresse;
    villeController.text = supplier.ville;
    paysController.text = supplier.pays;
    descriptionController.text = supplier.description ?? '';
    commentairesController.text = supplier.commentaires ?? '';
  }

  void clearForm() {
    nomController.clear();
    emailController.clear();
    telephoneController.clear();
    adresseController.clear();
    villeController.clear();
    paysController.clear();
    descriptionController.clear();
    commentairesController.clear();
  }

  Future<void> rateSupplier(
    Supplier supplier,
    double rating, {
    String? comments,
  }) async {
    try {
      isLoading = true;

      final success = await _supplierService.rateSupplier(
        supplier.id!,
        rating,
        comments: comments,
      );
      if (success) {
        await loadSuppliers();
        await loadSupplierStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Fournisseur évalué avec succès',
        );
      } else {
        throw Exception('Erreur lors de l\'évaluation');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible d\'évaluer le fournisseur',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> submitSupplier(Supplier supplier) async {
    try {
      isLoading = true;

      final success = await _supplierService.submitSupplier(supplier.id!);
      if (success) {
        await loadSuppliers();
        await loadSupplierStats();

        NotificationHelper.notifySubmission(
          entityType: 'supplier',
          entityName: NotificationHelper.getEntityDisplayName(
            'supplier',
            supplier,
          ),
          entityId: supplier.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'supplier',
            supplier.id.toString(),
          ),
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Fournisseur soumis avec succès',
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de soumettre le fournisseur',
      );
    } finally {
      isLoading = false;
    }
  }
}
