import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/tax_model.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class TaxController {
  static final TaxController _instance = TaxController._();
  static TaxController get to => _instance;
  factory TaxController() => _instance;
  TaxController._() {
    _taxService = TaxService();
    _waitForTokenAndLoad();
  }

  late final TaxService _taxService;

  // Variables
  final List<Tax> allTaxes = [];
  final List<Tax> taxes = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  TaxStats? taxStats;

  // Variables pour les filtres
  String selectedStatus = 'all';
  String searchQuery = '';
  String? _currentStatusFilter;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  void dispose() {
    scrollController.dispose();
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
  Future<void> loadTaxes({String? statusFilter, int page = 1, bool forceRefresh = false}) async {
    try {
      _currentStatusFilter =
          statusFilter ??
          (selectedStatus == 'all' ? null : selectedStatus);

      // Vérifier que le token est disponible
      final storage = GetStorage();
      final token = storage.read<String?>('token');
      if (token == null) {
        return;
      }

      final cacheKey = 'taxes_${_currentStatusFilter ?? 'all'}';

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = TaxService.getCachedTaxes();
          if (hiveList.isNotEmpty) {
            allTaxes.clear();
            allTaxes.addAll(hiveList);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshTaxesFromApi(cacheKey));
            return;
          }
          final cachedTaxes = CacheHelper.get<List<Tax>>(cacheKey);
          if (cachedTaxes != null && cachedTaxes.isNotEmpty) {
            allTaxes.clear();
            allTaxes.addAll(cachedTaxes);
            applyFilters();
            isLoading = false;
            Future.microtask(() => _refreshTaxesFromApi(cacheKey));
            return;
          }
        }
        allTaxes.clear();
        isLoading = true;
      } else if (page > 1) {
        isLoadingMore = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _taxService.getTaxesPaginated(
          status: _currentStatusFilter,
          search: searchQuery.isNotEmpty ? searchQuery : null,
          page: page,
          perPage: perPage,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          allTaxes.clear();
          allTaxes.addAll(paginatedResponse.data);
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
          allTaxes.clear();
          allTaxes.addAll(loadedTaxes);
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
          allTaxes.clear();
            allTaxes.addAll(cachedTaxes);
          applyFilters();
          print(
            '✅ [TAX_CONTROLLER] Données chargées depuis le cache (${cachedTaxes.length} taxes)',
          );
          // Ne pas afficher d'erreur si on a des données en cache
          return;
        } else {
          // Vider la liste seulement si aucune donnée n'est disponible
          allTaxes.clear();
          taxes.clear();
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

      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  /// Rafraîchit les taxes depuis l'API (page 1) et met à jour la liste/cache si le filtre est inchangé.
  Future<void> _refreshTaxesFromApi(String cacheKey) async {
    try {
      if (_currentStatusFilter != (selectedStatus == 'all' ? null : selectedStatus)) return;
      final paginatedResponse = await _taxService.getTaxesPaginated(
        status: _currentStatusFilter,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        page: 1,
        perPage: perPage,
      );
      if (_currentStatusFilter != (selectedStatus == 'all' ? null : selectedStatus)) return;
      allTaxes.clear();
          allTaxes.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      applyFilters();
      CacheHelper.set(cacheKey, paginatedResponse.data);
      loadTaxStats().catchError((_) {});
    } catch (_) {}
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadTaxes(
        statusFilter: _currentStatusFilter,
        page: currentPage + 1,
      );
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadTaxes(
        statusFilter: _currentStatusFilter,
        page: currentPage - 1,
      );
    }
  }

  // Charger les statistiques
  Future<void> loadTaxStats() async {
    try {
      final stats = await _taxService.getTaxStats();
      taxStats = stats;
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
    if (selectedStatus != 'all') {
      final beforeCount = filteredTaxes.length;
      filteredTaxes =
          filteredTaxes.where((tax) {
            bool matches = false;
            final statusLower = selectedStatus.toLowerCase();
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
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
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

    taxes.clear();
    taxes.addAll(filteredTaxes);
    // Debug final
    if (taxes.isEmpty) {
      if (allTaxes.isNotEmpty) {
        for (final tax in allTaxes) {}
      }
    }
  }

  // Rechercher
  void searchTaxes(String query) {
    searchQuery = query;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    applyFilters(); // Appliquer les filtres sans recharger depuis l'API
  }

  // Valider une taxe
  Future<void> validateTax(Tax tax, {String? validationComment}) async {
    try {
      isLoading = true;

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

        // Notifier l'utilisateur créateur de la validation
        NotificationHelper.notifyValidation(
          entityType: 'taxe',
          entityName: NotificationHelper.getEntityDisplayName('taxe', tax),
          entityId: tax.id.toString(),
          route: NotificationHelper.getEntityRoute('taxe', tax.id.toString()),
          entity: tax,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Taxe validée avec succès',
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
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de valider la taxe: ${e.toString()}',
      );
    } finally {
      isLoading = false;
    }
  }

  // Rejeter une taxe
  Future<void> rejectTax(
    Tax tax,
    String reason, {
    String? rejectionComment,
  }) async {
    try {
      isLoading = true;

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

        // Notifier l'utilisateur créateur du rejet
        NotificationHelper.notifyRejection(
          entityType: 'taxe',
          entityName: NotificationHelper.getEntityDisplayName('taxe', tax),
          entityId: tax.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute('taxe', tax.id.toString()),
          entity: tax,
        );

        errorHelperShowSnackbar?.call(
          'Succès',
          'Taxe rejetée',
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
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de rejeter la taxe: ${e.toString()}',
      );
    } finally {
      isLoading = false;
    }
  }

  // Marquer une taxe comme payée
  Future<void> markTaxAsPaid(Tax tax) async {
    try {
      isLoading = true;

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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Taxe marquée comme payée avec succès',
        );
      } else {
        throw Exception('Erreur lors du marquage comme payé');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de marquer la taxe comme payée: ${e.toString()}',
      );
    } finally {
      isLoading = false;
    }
  }

  // Supprimer une taxe
  Future<void> deleteTax(Tax tax) async {
    try {
      isLoading = true;

      // Supprimer via l'API
      final success = await _taxService.deleteTax(tax.id!);

      if (success) {
        // Recharger les données
        await loadTaxes();
        await loadTaxStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Taxe supprimée avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer la taxe',
      );
    } finally {
      isLoading = false;
    }
  }
}
