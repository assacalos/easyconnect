import 'package:flutter/material.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

class StockController {
  static final StockController _instance = StockController._();
  static StockController get to => _instance;
  factory StockController() => _instance;
  StockController._();

  final StockService _stockService = StockService.to;

  // Variables
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isCreating = false;
  bool isUpdating = false;
  bool isDeleting = false;
  final List<Stock> allStocks = [];
  final List<Stock> stocks = [];
  final List<StockCategory> categories = [];
  final List<StockAlert> alerts = [];
  StockStats? stockStats;
  Stock? selectedStock;

  // Variables pour la recherche et les filtres
  String searchQuery = '';
  String selectedCategoryFilter = 'all';
  String selectedStatus = 'all';
  String selectedSortBy = 'name';
  bool sortAscending = true;
  String? _currentStatusFilter;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  // Variables pour le formulaire
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController minQuantityController = TextEditingController();
  final TextEditingController maxQuantityController = TextEditingController();
  final TextEditingController reorderPointController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController modelController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();

  String selectedCategoryForm = '';
  String selectedUnit = 'pièce';

  // Variables pour les mouvements de stock
  String selectedMovementType = 'in';
  final TextEditingController movementQuantityController =
      TextEditingController();
  final TextEditingController movementReasonController =
      TextEditingController();
  final TextEditingController movementReferenceController =
      TextEditingController();
  final TextEditingController movementNotesController = TextEditingController();

  final TextEditingController adjustmentQuantityController =
      TextEditingController();
  final TextEditingController adjustmentReasonController =
      TextEditingController();
  final TextEditingController adjustmentNotesController =
      TextEditingController();

  // Listes pour les dropdowns
  final List<Map<String, dynamic>> stockCategories = [
    {'value': 'electronics', 'label': 'Électronique'},
    {'value': 'clothing', 'label': 'Vêtements'},
    {'value': 'food', 'label': 'Alimentation'},
    {'value': 'books', 'label': 'Livres'},
    {'value': 'tools', 'label': 'Outils'},
    {'value': 'furniture', 'label': 'Mobilier'},
    {'value': 'sports', 'label': 'Sport'},
    {'value': 'beauty', 'label': 'Beauté'},
    {'value': 'automotive', 'label': 'Automobile'},
    {'value': 'other', 'label': 'Autre'},
  ];

  final List<Map<String, dynamic>> units = [
    {'value': 'pièce', 'label': 'Pièce'},
    {'value': 'kg', 'label': 'Kilogramme'},
    {'value': 'g', 'label': 'Gramme'},
    {'value': 'l', 'label': 'Litre'},
    {'value': 'ml', 'label': 'Millilitre'},
    {'value': 'm', 'label': 'Mètre'},
    {'value': 'cm', 'label': 'Centimètre'},
    {'value': 'm²', 'label': 'Mètre carré'},
    {'value': 'm³', 'label': 'Mètre cube'},
    {'value': 'paquet', 'label': 'Paquet'},
    {'value': 'boîte', 'label': 'Boîte'},
    {'value': 'carton', 'label': 'Carton'},
  ];

  final List<Map<String, dynamic>> movementTypes = [
    {'value': 'in', 'label': 'Entrée'},
    {'value': 'out', 'label': 'Sortie'},
    {'value': 'adjustment', 'label': 'Ajustement'},
    {'value': 'transfer', 'label': 'Transfert'},
  ];

  final List<Map<String, dynamic>> stockStatuses = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'normal', 'label': 'Normal'},
    {'value': 'low_stock', 'label': 'Stock faible'},
    {'value': 'out_of_stock', 'label': 'Rupture'},
    {'value': 'overstocked', 'label': 'Surstock'},
  ];

  final List<Map<String, dynamic>> approvalStatuses = [
    {'value': 'all', 'label': 'Tous'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'approved', 'label': 'Approuvés'},
    {'value': 'rejected', 'label': 'Rejetés'},
  ];

  final List<Map<String, dynamic>> sortOptions = [
    {'value': 'name', 'label': 'Nom'},
    {'value': 'quantity', 'label': 'Quantité'},
    {'value': 'value', 'label': 'Valeur'},
    {'value': 'created_at', 'label': 'Date de création'},
    {'value': 'updated_at', 'label': 'Dernière modification'},
  ];

  void ensureInitialized() {
    loadStocks();
    loadCategories();
    loadStockStats();
    loadStockAlerts();
  }

  void dispose() {
    scrollController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    skuController.dispose();
    quantityController.dispose();
    minQuantityController.dispose();
    maxQuantityController.dispose();
    reorderPointController.dispose();
    unitPriceController.dispose();
    sellingPriceController.dispose();
    brandController.dispose();
    modelController.dispose();
    notesController.dispose();
    unitController.dispose();
    locationController.dispose();
    supplierController.dispose();
    barcodeController.dispose();
    movementQuantityController.dispose();
    movementReasonController.dispose();
    movementReferenceController.dispose();
    movementNotesController.dispose();
    adjustmentQuantityController.dispose();
    adjustmentReasonController.dispose();
    adjustmentNotesController.dispose();
  }

  // Charger les stocks
  Future<void> loadStocks({String? statusFilter, int page = 1, bool forceRefresh = false}) async {
    try {
      _currentStatusFilter = statusFilter;
      AppLogger.info(
        'Chargement des stocks - Page $page',
        tag: 'STOCK_CONTROLLER',
      );

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = StockService.getCachedStocks();
          if (hiveList.isNotEmpty) {
            allStocks.clear();
            allStocks.addAll(hiveList);
            stocks.clear();
            stocks.addAll(hiveList);
            isLoading = false;
            Future.microtask(() => _refreshStocksFromApi());
            return;
          }
        }
        allStocks.clear();
        stocks.clear();
        isLoading = true;
      }
      if (page > 1) {
        isLoadingMore = true;
      }

      try {
        final paginatedResponse = await _stockService.getStocksPaginated(
          search: searchQuery.isNotEmpty ? searchQuery : null,
          category:
              selectedCategoryFilter != 'all'
                  ? selectedCategoryFilter
                  : null,
          status:
              statusFilter != null && statusFilter != 'all'
                  ? statusFilter
                  : null,
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
          allStocks.clear();
          allStocks.addAll(paginatedResponse.data);
          stocks.clear();
          stocks.addAll(paginatedResponse.data);
        } else {
          // Pour les pages suivantes, ajouter les données
          allStocks.addAll(paginatedResponse.data);
          stocks.addAll(paginatedResponse.data);
        }

        AppLogger.info(
          '${paginatedResponse.data.length} stocks chargés (Page $page/${paginatedResponse.meta.lastPage})',
          tag: 'STOCK_CONTROLLER',
        );

        // Afficher un message de succès si des stocks sont trouvés (seulement page 1)
        if (paginatedResponse.data.isNotEmpty && page == 1) {
          errorHelperShowSnackbar?.call(
            'Succès',
            '${paginatedResponse.data.length} stocks chargés avec succès',
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 2),
          );
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        AppLogger.warning(
          'Erreur avec pagination, fallback vers méthode classique: $e',
          tag: 'STOCK_CONTROLLER',
        );
        final loadedStocks = await _stockService.getStocks(
          search: null,
          category: null,
          status: null,
        );
        allStocks.clear();
        allStocks.addAll(loadedStocks);
        stocks.clear();
        stocks.addAll(loadedStocks);
      }
    } catch (e) {
      // Ne pas vider la liste si des données sont déjà affichées (Hive/cache)
      isLoading = false;
      isLoadingMore = false;
      if (allStocks.isEmpty && stocks.isEmpty) {
        final hiveList = StockService.getCachedStocks();
        if (hiveList.isNotEmpty) {
          allStocks.clear();
          allStocks.addAll(hiveList);
          stocks.clear();
          stocks.addAll(hiveList);
        } else {
          allStocks.clear();
          stocks.clear();
        }
      }

      // Ne pas afficher de message d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('session expirée') ||
          errorString.contains('401') ||
          errorString.contains('unauthorized')) {
        // Erreur d'authentification déjà gérée, ne rien afficher
        AppLogger.warning(
          'Erreur d\'authentification lors du chargement des stocks',
          tag: 'STOCK_CONTROLLER',
        );
        return;
      }

      AppLogger.error(
        'Erreur lors du chargement des stocks: $e',
        tag: 'STOCK_CONTROLLER',
        error: e,
      );

      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      if (allStocks.isEmpty) {
        // Vérifier une dernière fois le cache avant d'afficher l'erreur
        final cacheKey = 'stocks_all';
        final cachedStocks = CacheHelper.get<List<Stock>>(cacheKey);
        if (cachedStocks == null || cachedStocks.isEmpty) {
          // Message d'erreur spécifique selon le type d'erreur
          String errorMessage;
          if (errorString.contains('socketexception') ||
              errorString.contains('connection refused')) {
            errorMessage =
                'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
          } else if (errorString.contains('500')) {
            errorMessage = 'Erreur serveur. Veuillez réessayer plus tard.';
          } else if (errorString.contains('formatexception') ||
              errorString.contains('unexpected end of input')) {
            errorMessage =
                'Erreur de format des données. Contactez l\'administrateur.';
          } else if (errorString.contains('null') ||
              errorString.contains('not a subtype')) {
            errorMessage =
                'Erreur de format des données. Contactez l\'administrateur.';
          } else {
            errorMessage = 'Erreur lors du chargement des stocks: $e';
          }

          errorHelperShowSnackbar?.call(
            'Erreur',
            errorMessage,
            backgroundColor: Colors.red,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
        } else {
          // Charger les données du cache si disponibles
          allStocks.clear();
          allStocks.addAll(cachedStocks);
          stocks.clear();
          stocks.addAll(cachedStocks);
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  /// Rafraîchit les stocks depuis l'API (page 1) et met à jour la liste si le filtre est inchangé.
  Future<void> _refreshStocksFromApi() async {
    try {
      final paginatedResponse = await _stockService.getStocksPaginated(
        search: searchQuery.isNotEmpty ? searchQuery : null,
        category:
            selectedCategoryFilter != 'all'
                ? selectedCategoryFilter
                : null,
        status:
            _currentStatusFilter != null && _currentStatusFilter != 'all'
                ? _currentStatusFilter
                : null,
        page: 1,
        perPage: perPage,
      );
      allStocks.clear();
      allStocks.addAll(paginatedResponse.data);
      stocks.clear();
      stocks.addAll(paginatedResponse.data);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
    } catch (_) {}
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
      loadStocks(
        statusFilter: _currentStatusFilter,
        page: currentPage + 1,
      );
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading && !isLoadingMore) {
      loadStocks(
        statusFilter: _currentStatusFilter,
        page: currentPage - 1,
      );
    }
  }

  // Charger les catégories
  Future<void> loadCategories() async {
    try {
      final categoriesList = await _stockService.getStockCategories();
      categories.clear();
      categories.addAll(categoriesList);
    } catch (e) {
      // Laisser la liste vide en cas d'erreur
      categories.clear();
    }
  }

  // Charger les statistiques
  Future<void> loadStockStats() async {
    try {
      final stats = await _stockService.getStockStats();
      stockStats = stats;
    } catch (e) {
      // Calculer les statistiques à partir des stocks chargés
      final totalValue = allStocks.fold(
        0.0,
        (sum, stock) => sum + stock.totalValue,
      );
      stockStats = StockStats(
        totalProducts: allStocks.length,
        activeProducts: allStocks.where((s) => s.isActive).length,
        lowStockProducts: allStocks.where((s) => s.isLowStock).length,
        outOfStockProducts: allStocks.where((s) => s.isOutOfStock).length,
        overstockedProducts: allStocks.where((s) => s.isOverstocked).length,
        totalValue: totalValue,
        averageValue:
            allStocks.isNotEmpty ? totalValue / allStocks.length : 0.0,
        totalMovements: 0,
        movementsThisMonth: 0,
        topCategories: [],
        topProducts: [],
      );
    }
  }

  // Charger les alertes
  Future<void> loadStockAlerts() async {
    try {
      final alertsList = await _stockService.getStockAlerts();
      alerts.clear();
      alerts.addAll(alertsList);
    } catch (e) {
      // Laisser la liste vide en cas d'erreur
      alerts.clear();
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Stock> filteredStocks = List.from(allStocks);

    // Filtrer par statut
    if (selectedStatus != 'all') {
      filteredStocks =
          filteredStocks.where((stock) {
            // Comparer avec le statut réel du stock
            final stockStatus = stock.status.toLowerCase();
            final matches =
                stockStatus == selectedStatus.toLowerCase() ||
                (selectedStatus == 'en_attente' &&
                    stockStatus == 'pending') ||
                (selectedStatus == 'valide' &&
                    stockStatus == 'approved') ||
                (selectedStatus == 'rejete' && stockStatus == 'rejected');
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    // Filtrer par catégorie
    if (selectedCategoryFilter != 'all') {
      filteredStocks =
          filteredStocks.where((stock) {
            final matches = stock.category == selectedCategoryFilter;
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    // Filtrer par recherche
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filteredStocks =
          filteredStocks.where((stock) {
            final matches =
                stock.name.toLowerCase().contains(query) ||
                stock.sku.toLowerCase().contains(query) ||
                stock.category.toLowerCase().contains(query);
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    stocks.clear();
    stocks.addAll(filteredStocks);
  }

  // Rechercher des stocks
  void searchStocks(String query) {
    searchQuery = query;
    applyFilters();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategoryFilter = category;
    loadStocks();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus = status;
    loadStocks();
  }

  // Trier les stocks
  void sortStocks(String sortBy) {
    if (selectedSortBy == sortBy) {
      sortAscending = !sortAscending;
    } else {
      selectedSortBy = sortBy;
      sortAscending = true;
    }
    _applySorting();
  }

  // Appliquer le tri
  void _applySorting() {
    stocks.sort((a, b) {
      int comparison = 0;
      switch (selectedSortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'quantity':
          comparison = a.quantity.compareTo(b.quantity);
          break;
        case 'value':
          comparison = a.totalValue.compareTo(b.totalValue);
          break;
        case 'created_at':
          comparison = (a.createdAt ?? DateTime(1970)).compareTo(
            b.createdAt ?? DateTime(1970),
          );
          break;
        case 'updated_at':
          comparison = (a.updatedAt ?? DateTime(1970)).compareTo(
            b.updatedAt ?? DateTime(1970),
          );
          break;
      }
      return sortAscending ? comparison : -comparison;
    });
  }

  // Obtenir les stocks filtrés
  List<Stock> get filteredStocks {
    List<Stock> filtered = stocks;

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (stock) =>
                    stock.name.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    stock.sku.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    (stock.description?.toLowerCase() ?? '').contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (selectedCategoryFilter != 'all') {
      filtered =
          filtered
              .where((stock) => stock.category == selectedCategoryFilter)
              .toList();
    }

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where((stock) => stock.stockStatus == selectedStatus)
              .toList();
    }

    return filtered;
  }

  // Créer un nouveau stock
  Future<bool> createStock() async {
    try {
      isCreating = true;

      // Valider que category est fourni
      if (selectedCategoryForm.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner une catégorie',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Valider que le nom n'est pas vide
      if (nameController.text.trim().isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez saisir un nom pour le produit',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Valider que le SKU n'est pas vide
      if (skuController.text.trim().isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez saisir un SKU pour le produit',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final stock = Stock(
        category: selectedCategoryForm,
        name: nameController.text.trim(),
        description:
            descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null,
        sku: skuController.text.trim(),
        unit:
            'pièce', // Valeur par défaut car le champ unit n'est plus dans le formulaire
        quantity: double.tryParse(quantityController.text) ?? 0.0,
        minQuantity: double.tryParse(minQuantityController.text) ?? 0.0,
        maxQuantity: double.tryParse(maxQuantityController.text) ?? 0.0,
        unitPrice: double.tryParse(unitPriceController.text) ?? 0.0,
        commentaire:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
        status: 'en_attente',
      );

      final createdStock = await _stockService.createStock(stock);

      // Invalider le cache
      CacheHelper.clearByPrefix('stocks_');

      // Ajouter le stock à la liste localement (mise à jour optimiste)
      if (createdStock.id != null) {
        allStocks.add(createdStock);
        stocks.add(createdStock);

        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'stock',
          entityName: NotificationHelper.getEntityDisplayName(
            'stock',
            createdStock,
          ),
          entityId: createdStock.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'stock',
            createdStock.id.toString(),
          ),
        );
      }

      errorHelperShowSnackbar?.call(
        'Succès',
        'Stock créé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      clearForm();
      loadStocks();
      loadStockStats();

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('stock');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la suppression du stock: $e',
        tag: 'STOCK_CONTROLLER',
        error: e,
        stackTrace: stackTrace,
      );
      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la création du stock: $errorMessage',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isCreating = false;
    }
  }

  // Mettre à jour un stock
  Future<bool> updateStock(Stock stock) async {
    try {
      isUpdating = true;

      // Valider que category est fourni
      if (selectedCategoryForm.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner une catégorie',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final updatedStock = stock.copyWith(
        category: selectedCategoryForm,
        name: nameController.text.trim(),
        description:
            descriptionController.text.trim().isNotEmpty
                ? descriptionController.text.trim()
                : null,
        sku: skuController.text.trim(),
        // unit n'est pas modifié car il n'existe pas dans le backend
        quantity: double.tryParse(quantityController.text) ?? stock.quantity,
        minQuantity:
            double.tryParse(minQuantityController.text) ?? stock.minQuantity,
        maxQuantity:
            double.tryParse(maxQuantityController.text) ?? stock.maxQuantity,
        unitPrice: double.tryParse(unitPriceController.text) ?? stock.unitPrice,
        commentaire:
            notesController.text.trim().isNotEmpty
                ? notesController.text.trim()
                : null,
      );

      await _stockService.updateStock(updatedStock);

      errorHelperShowSnackbar?.call(
        'Succès',
        'Stock mis à jour avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      clearForm();
      loadStocks();
      loadStockStats();
      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la mise à jour du stock: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isUpdating = false;
    }
  }

  // Supprimer un stock
  Future<void> deleteStock(Stock stock) async {
    try {
      isDeleting = true;

      await _stockService.deleteStock(stock.id!);

      errorHelperShowSnackbar?.call('Succès', 'Stock supprimé avec succès');
      loadStocks();
      loadStockStats();
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de la suppression du stock: $e');
    } finally {
      isDeleting = false;
    }
  }

  // Remplir le formulaire pour l'édition
  void fillForm(Stock stock) {
    nameController.text = stock.name;
    descriptionController.text = stock.description ?? '';
    selectedCategoryForm = stock.category;
    skuController.text = stock.sku;
    // unit n'est plus dans le formulaire
    quantityController.text = stock.quantity.toString();
    minQuantityController.text = stock.minQuantity.toString();
    maxQuantityController.text = stock.maxQuantity.toString();
    unitPriceController.text = stock.unitPrice.toString();
    notesController.text = stock.commentaire ?? '';
  }

  // Vider le formulaire
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedCategoryForm = '';
    selectedUnit = 'pièce';
    skuController.clear();
    quantityController.clear();
    minQuantityController.clear();
    maxQuantityController.clear();
    unitPriceController.clear();
    notesController.clear();
  }

  // Ajouter un mouvement de stock
  Future<void> addStockMovement(Stock stock) async {
    try {
      await _stockService.addStockMovement(
        stockId: stock.id!,
        type: selectedMovementType,
        quantity: double.parse(movementQuantityController.text),
        reason:
            movementReasonController.text.trim().isNotEmpty
                ? movementReasonController.text.trim()
                : null,
        reference:
            movementReferenceController.text.trim().isNotEmpty
                ? movementReferenceController.text.trim()
                : null,
        notes:
            movementNotesController.text.trim().isNotEmpty
                ? movementNotesController.text.trim()
                : null,
      );

      errorHelperShowSnackbar?.call('Succès', 'Mouvement de stock ajouté');
      clearMovementForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'ajout du mouvement: $e');
    }
  }

  // Ajuster le stock
  Future<void> adjustStock(Stock stock) async {
    try {
      await _stockService.adjustStock(
        stockId: stock.id!,
        newQuantity: double.parse(adjustmentQuantityController.text),
        reason: adjustmentReasonController.text.trim(),
        notes:
            adjustmentNotesController.text.trim().isNotEmpty
                ? adjustmentNotesController.text.trim()
                : null,
      );

      errorHelperShowSnackbar?.call('Succès', 'Stock ajusté avec succès');
      clearAdjustmentForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      errorHelperShowSnackbar?.call('Erreur', 'Erreur lors de l\'ajustement du stock: $e');
    }
  }

  // Vider le formulaire de mouvement
  void clearMovementForm() {
    selectedMovementType = 'in';
    movementQuantityController.clear();
    movementReasonController.clear();
    movementReferenceController.clear();
    movementNotesController.clear();
  }

  // Vider le formulaire d'ajustement
  void clearAdjustmentForm() {
    adjustmentQuantityController.clear();
    adjustmentReasonController.clear();
    adjustmentNotesController.clear();
  }

  // Sélectionner une catégorie (pour le formulaire)
  void selectCategory(String category) {
    selectedCategoryForm = category;
  }

  // Sélectionner une unité
  void selectUnit(String unit) {
    selectedUnit = unit;
  }

  // Sélectionner un type de mouvement
  void selectMovementType(String type) {
    selectedMovementType = type;
  }

  // Sélectionner un stock
  void selectStock(Stock stock) {
    selectedStock = stock;
  }

  // Approuver/Valider un stock
  Future<void> approveStock(Stock stock, {String? validationComment}) async {
    try {
      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('stocks_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final stockIndex = stocks.indexWhere((s) => s.id == stock.id);
      final allStockIndex = allStocks.indexWhere((s) => s.id == stock.id);

      if (stockIndex != -1 || allStockIndex != -1) {
        final originalStock =
            stockIndex != -1 ? stocks[stockIndex] : allStocks[allStockIndex];
        final updatedStock = Stock(
          id: originalStock.id,
          category: originalStock.category,
          name: originalStock.name,
          description: originalStock.description,
          sku: originalStock.sku,
          unit: originalStock.unit,
          quantity: originalStock.quantity,
          minQuantity: originalStock.minQuantity,
          maxQuantity: originalStock.maxQuantity,
          unitPrice: originalStock.unitPrice,
          commentaire: originalStock.commentaire,
          status: 'valide', // Validé
          createdAt: originalStock.createdAt,
          updatedAt: originalStock.updatedAt,
          movements: originalStock.movements,
        );

        if (stockIndex != -1) {
          stocks[stockIndex] = updatedStock;
        }
        if (allStockIndex != -1) {
          allStocks[allStockIndex] = updatedStock;
        }
      }

      // Appel API en arrière-plan
      await _stockService.approveStock(
        stockId: stock.id!,
        validationComment: validationComment,
      );

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('stock');

      // Notifier l'utilisateur concerné de la validation
      NotificationHelper.notifyValidation(
        entityType: 'stock',
        entityName: NotificationHelper.getEntityDisplayName('stock', stock),
        entityId: stock.id.toString(),
        route: NotificationHelper.getEntityRoute('stock', stock.id.toString()),
        entity: stock,
      );

      errorHelperShowSnackbar?.call(
        'Succès',
        'Stock approuvé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Recharger les données en arrière-plan avec le filtre actuel
      // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
      Future.delayed(const Duration(milliseconds: 500), () {
        loadStocks(statusFilter: _currentStatusFilter).catchError((e) {
          // En cas d'erreur, on garde la mise à jour optimiste
        });
      });
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadStocks(statusFilter: _currentStatusFilter);
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de l\'approbation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Rejeter un stock (selon la doc API)
  void rejectStock(Stock stock, {String? commentaire}) async {
    try {
      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('stocks_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final stockIndex = stocks.indexWhere((s) => s.id == stock.id);
      final allStockIndex = allStocks.indexWhere((s) => s.id == stock.id);

      if (stockIndex != -1 || allStockIndex != -1) {
        final originalStock =
            stockIndex != -1 ? stocks[stockIndex] : allStocks[allStockIndex];
        final updatedStock = Stock(
          id: originalStock.id,
          category: originalStock.category,
          name: originalStock.name,
          description: originalStock.description,
          sku: originalStock.sku,
          unit: originalStock.unit,
          quantity: originalStock.quantity,
          minQuantity: originalStock.minQuantity,
          maxQuantity: originalStock.maxQuantity,
          unitPrice: originalStock.unitPrice,
          commentaire: commentaire ?? originalStock.commentaire,
          status: 'rejete', // Rejeté
          createdAt: originalStock.createdAt,
          updatedAt: originalStock.updatedAt,
          movements: originalStock.movements,
        );

        if (stockIndex != -1) {
          stocks[stockIndex] = updatedStock;
        }
        if (allStockIndex != -1) {
          allStocks[allStockIndex] = updatedStock;
        }
      }

      // Appel API en arrière-plan
      await _stockService.rejectStock(
        stockId: stock.id!,
        commentaire: commentaire ?? 'Rejeté par le patron',
      );

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('stock');

      // Notifier l'utilisateur concerné du rejet
      NotificationHelper.notifyRejection(
        entityType: 'stock',
        entityName: NotificationHelper.getEntityDisplayName('stock', stock),
        entityId: stock.id.toString(),
        reason: commentaire ?? 'Rejeté par le patron',
        route: NotificationHelper.getEntityRoute('stock', stock.id.toString()),
        entity: stock,
      );

      errorHelperShowSnackbar?.call(
        'Succès',
        'Stock rejeté avec succès',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );

      // Recharger les données en arrière-plan avec le filtre actuel
      // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
      Future.delayed(const Duration(milliseconds: 500), () {
        loadStocks(statusFilter: _currentStatusFilter).catchError((e) {
          // En cas d'erreur, on garde la mise à jour optimiste
        });
      });
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadStocks(statusFilter: _currentStatusFilter);
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Filtrage par statut d'approbation
  void filterByApprovalStatus(String status) {
    selectedStatus = status;
    applyFilters();
  }

  // Obtenir les stocks par statut (active, inactive, discontinued)
  List<Stock> getStocksByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return stocks.where((stock) => stock.isActive).toList();
      case 'inactive':
        return stocks.where((stock) => stock.isInactive).toList();
      case 'discontinued':
        return stocks.where((stock) => stock.isDiscontinued).toList();
      default:
        return stocks;
    }
  }

  // Tester la connectivité à l'API
  Future<bool> testApiConnection() async {
    try {
      return await _stockService.testConnection();
    } catch (e) {
      return false;
    }
  }

  // Vérifier les permissions
  bool get canManageStocks =>
      true; // TODO: Implémenter la vérification des permissions
  bool get canViewStocks =>
      true; // TODO: Implémenter la vérification des permissions
  bool get canManageStockMovements =>
      true; // TODO: Implémenter la vérification des permissions
}
