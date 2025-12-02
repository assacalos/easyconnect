import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';

class TaxController extends GetxController {
  late final TaxService _taxService;

  // Variables observables
  final RxList<Tax> allTaxes = <Tax>[].obs; // Toutes les taxes
  final RxList<Tax> taxes = <Tax>[].obs; // Taxes filtrées
  final RxBool isLoading = false.obs;
  final Rx<TaxStats?> taxStats = Rx<TaxStats?>(null);

  // Variables pour les filtres
  final RxString selectedStatus = 'all'.obs;
  final RxString searchQuery = ''.obs;
  String? _currentStatusFilter; // Mémoriser le filtre de statut actuel

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

  @override
  void onInit() {
    super.onInit();

    try {
      _taxService = Get.find<TaxService>();
    } catch (e) {}

    // Attendre que le token soit disponible avant de charger
    _waitForTokenAndLoad();
  }

  Future<void> _waitForTokenAndLoad() async {
    // Attendre jusqu'à 3 secondes que le token soit disponible
    final storage = GetStorage();
    for (int i = 0; i < 30; i++) {
      final token = storage.read<String?>('token');
      if (token != null) {
        loadTaxes();
        loadTaxStats();
        return;
      }
      // Attendre 100ms avant de réessayer
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Si le token n'est toujours pas disponible après 3 secondes, essayer quand même
    loadTaxes();
    loadTaxStats();
  }

  // Charger toutes les taxes
  Future<void> loadTaxes({String? statusFilter, int page = 1}) async {
    try {
      isLoading.value = true;
      _currentStatusFilter =
          statusFilter ??
          (selectedStatus.value == 'all' ? null : selectedStatus.value);

      // Vérifier que le token est disponible
      final storage = GetStorage();
      final token = storage.read<String?>('token');
      if (token == null) {
        // Ne pas afficher d'erreur si le token n'est pas disponible, juste attendre
        return;
      }

      // Afficher immédiatement les données du cache si disponibles (seulement page 1)
      final cacheKey = 'taxes_${_currentStatusFilter ?? 'all'}';
      final cachedTaxes = CacheHelper.get<List<Tax>>(cacheKey);
      if (cachedTaxes != null && cachedTaxes.isNotEmpty && page == 1) {
        allTaxes.assignAll(cachedTaxes);
        applyFilters();
        isLoading.value = false; // Permettre l'affichage immédiat
      } else {
        isLoading.value = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _taxService.getTaxesPaginated(
          status: _currentStatusFilter,
          search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
          page: page,
          perPage: perPage.value,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          allTaxes.value = paginatedResponse.data;
        } else {
          // Pour les pages suivantes, ajouter les données
          allTaxes.addAll(paginatedResponse.data);
        }
        applyFilters();

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        AppLogger.warning(
          'Erreur avec pagination, fallback vers méthode classique: $e',
          tag: 'TAX_CONTROLLER',
        );
        final loadedTaxes = await _taxService.getTaxes(
          status: null,
          search: null,
        );
        if (loadedTaxes.isNotEmpty) {
          allTaxes.assignAll(loadedTaxes);
          applyFilters();
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedTaxes);
          }
        } else if (allTaxes.isEmpty) {
          allTaxes.clear();
          taxes.clear();
        }
      }

      // Ne pas afficher de message de succès à chaque chargement automatique
      // Seulement si l'utilisateur recharge manuellement
    } catch (e) {
      print('⚠️ [TAX_CONTROLLER] Erreur lors du chargement des taxes: $e');

      // Vérifier le cache en cas d'erreur réseau (si la liste est vide)
      if (allTaxes.isEmpty) {
        final cacheKey = 'taxes_${_currentStatusFilter ?? 'all'}';
        final cachedTaxes = CacheHelper.get<List<Tax>>(cacheKey);
        if (cachedTaxes != null && cachedTaxes.isNotEmpty) {
          // Charger les données du cache si disponibles
          allTaxes.assignAll(cachedTaxes);
          applyFilters();
          print(
            '✅ [TAX_CONTROLLER] Données chargées depuis le cache (${cachedTaxes.length} taxes)',
          );
          // Ne pas afficher d'erreur si on a des données en cache
          return;
        } else {
          // Vider la liste seulement si aucune donnée n'est disponible
          allTaxes.value = [];
          taxes.value = [];
        }
      } else {
        // Si la liste contient des données, on garde ce qu'on a
        // Cela permet d'afficher la taxe créée même si le rechargement échoue
        print(
          '✅ [TAX_CONTROLLER] Liste des taxes conservée (${allTaxes.length} taxes) malgré l\'erreur de rechargement',
        );
      }

      // Message d'erreur spécifique selon le type d'erreur
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('TimeoutException')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        // Ne pas afficher d'erreur pour les erreurs 401, elles sont gérées par AuthErrorHandler
        return;
      } else if (e.toString().contains('404') ||
          e.toString().contains('Not Found')) {
        // L'endpoint n'existe peut-être pas encore, ne pas afficher d'erreur
        return;
      } else if (e.toString().contains('500')) {
        errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
      } else if (e.toString().contains('FormatException') ||
          e.toString().contains('Unexpected end of input')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else if (e.toString().contains('Null') ||
          e.toString().contains('not a subtype')) {
        errorMessage =
            'Erreur de format des données. Contactez l\'administrateur.';
      } else {
        // Ne pas afficher d'erreur générique pour éviter de spammer l'utilisateur
        // Logger l'erreur silencieusement
        return;
      }

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
      loadTaxes(
        statusFilter: _currentStatusFilter,
        page: currentPage.value + 1,
      );
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadTaxes(
        statusFilter: _currentStatusFilter,
        page: currentPage.value - 1,
      );
    }
  }

  // Charger les statistiques
  Future<void> loadTaxStats() async {
    try {
      final stats = await _taxService.getTaxStats();
      taxStats.value = stats;
    } catch (e) {}
  }

  // Tester la connectivité à l'API
  Future<bool> testTaxConnection() async {
    try {
      return await _taxService.testTaxConnection();
    } catch (e) {
      return false;
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Tax> filteredTaxes = List.from(allTaxes);
    // Filtrer par statut (normalisation vers les 4 statuts)
    if (selectedStatus.value != 'all') {
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            bool matches = false;
            final statusLower = selectedStatus.value.toLowerCase();
            if (statusLower == 'en_attente') {
              matches = tax.isPending;
            } else if (statusLower == 'valide') {
              matches = tax.isValidated;
            } else if (statusLower == 'rejete') {
              matches = tax.isRejected;
            } else if (statusLower == 'paid') {
              matches = tax.isPaid;
            }
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            final matches =
                tax.name.toLowerCase().contains(query) ||
                (tax.description?.toLowerCase().contains(query) ?? false);
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    taxes.assignAll(filteredTaxes);
    // Debug final
    if (taxes.isEmpty) {
      if (allTaxes.isNotEmpty) {
        for (final tax in allTaxes) {}
      }
    }
  }

  // Rechercher
  void searchTaxes(String query) {
    searchQuery.value = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Valider une taxe
  Future<void> validateTax(Tax tax, {String? validationComment}) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('taxes_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final taxIndex = taxes.indexWhere((t) => t.id == tax.id);
      final allTaxIndex = allTaxes.indexWhere((t) => t.id == tax.id);

      if (taxIndex != -1 || allTaxIndex != -1) {
        final originalTax =
            taxIndex != -1 ? taxes[taxIndex] : allTaxes[allTaxIndex];
        final updatedTax = Tax(
          id: originalTax.id,
          category: originalTax.category,
          comptableId: originalTax.comptableId,
          comptable: originalTax.comptable,
          reference: originalTax.reference,
          period: originalTax.period,
          periodStart: originalTax.periodStart,
          periodEnd: originalTax.periodEnd,
          dueDate: originalTax.dueDate,
          baseAmount: originalTax.baseAmount,
          taxRate: originalTax.taxRate,
          taxAmount: originalTax.taxAmount,
          totalAmount: originalTax.totalAmount,
          status: 'validated', // Validée
          statusLibelle: originalTax.statusLibelle,
          description: originalTax.description,
          notes: originalTax.notes,
          calculationDetails: originalTax.calculationDetails,
          createdAt: originalTax.createdAt,
          updatedAt: originalTax.updatedAt,
        );

        if (taxIndex != -1) {
          taxes[taxIndex] = updatedTax;
        }
        if (allTaxIndex != -1) {
          allTaxes[allTaxIndex] = updatedTax;
        }
      }

      // Utiliser l'endpoint dédié pour la validation
      final success = await _taxService.approveTax(
        tax.id!,
        notes: validationComment,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('tax');

        Get.snackbar(
          'Succès',
          'Taxe validée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadTaxes(statusFilter: _currentStatusFilter).catchError((e) {});
          loadTaxStats().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadTaxes(statusFilter: _currentStatusFilter);
        await loadTaxStats();
        throw Exception('Erreur lors de la validation');
      }
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadTaxes(statusFilter: _currentStatusFilter);
      await loadTaxStats();
      Get.snackbar(
        'Erreur',
        'Impossible de valider la taxe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter une taxe
  Future<void> rejectTax(
    Tax tax,
    String reason, {
    String? rejectionComment,
  }) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('taxes_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final taxIndex = taxes.indexWhere((t) => t.id == tax.id);
      final allTaxIndex = allTaxes.indexWhere((t) => t.id == tax.id);

      if (taxIndex != -1 || allTaxIndex != -1) {
        final originalTax =
            taxIndex != -1 ? taxes[taxIndex] : allTaxes[allTaxIndex];
        final updatedTax = Tax(
          id: originalTax.id,
          category: originalTax.category,
          comptableId: originalTax.comptableId,
          comptable: originalTax.comptable,
          reference: originalTax.reference,
          period: originalTax.period,
          periodStart: originalTax.periodStart,
          periodEnd: originalTax.periodEnd,
          dueDate: originalTax.dueDate,
          baseAmount: originalTax.baseAmount,
          taxRate: originalTax.taxRate,
          taxAmount: originalTax.taxAmount,
          totalAmount: originalTax.totalAmount,
          status: 'rejected', // Rejetée
          statusLibelle: originalTax.statusLibelle,
          description: originalTax.description,
          notes: originalTax.notes,
          calculationDetails: originalTax.calculationDetails,
          createdAt: originalTax.createdAt,
          updatedAt: originalTax.updatedAt,
        );

        if (taxIndex != -1) {
          taxes[taxIndex] = updatedTax;
        }
        if (allTaxIndex != -1) {
          allTaxes[allTaxIndex] = updatedTax;
        }
      }

      // Utiliser l'endpoint dédié pour le rejet
      final success = await _taxService.rejectTax(
        tax.id!,
        reason: reason,
        notes: rejectionComment,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('tax');

        Get.snackbar(
          'Succès',
          'Taxe rejetée',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le filtre actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadTaxes(statusFilter: _currentStatusFilter).catchError((e) {});
          loadTaxStats().catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadTaxes(statusFilter: _currentStatusFilter);
        await loadTaxStats();
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadTaxes(statusFilter: _currentStatusFilter);
      await loadTaxStats();
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la taxe: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Marquer une taxe comme payée
  Future<void> markTaxAsPaid(Tax tax) async {
    try {
      isLoading.value = true;

      // Utiliser le service pour marquer comme payé
      final success = await _taxService.markTaxAsPaid(
        tax.id!,
        paymentMethod: 'manual',
        notes: 'Marqué comme payé depuis l\'application',
      );

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe marquée comme payée avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors du marquage comme payé');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer la taxe comme payée: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer une taxe
  Future<void> deleteTax(Tax tax) async {
    try {
      isLoading.value = true;

      // Supprimer via l'API
      final success = await _taxService.deleteTax(tax.id!);

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        Get.snackbar(
          'Succès',
          'Taxe supprimée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la taxe',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
