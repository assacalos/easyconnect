import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/utils/logger.dart';

class StockController extends GetxController {
  late final StockService _stockService;

  // Variables observables
  final RxBool isLoading = false.obs;
  final RxBool isCreating = false.obs;
  final RxBool isUpdating = false.obs;
  final RxBool isDeleting = false.obs;
  final RxList<Stock> allStocks = <Stock>[].obs; // Tous les stocks
  final RxList<Stock> stocks = <Stock>[].obs; // Stocks filtrés
  final RxList<StockCategory> categories = <StockCategory>[].obs;
  final RxList<StockAlert> alerts = <StockAlert>[].obs;
  final Rx<StockStats?> stockStats = Rx<StockStats?>(null);
  final Rx<Stock?> selectedStock = Rx<Stock?>(null);

  // Variables pour la recherche et les filtres
  final RxString searchQuery = ''.obs;
  final RxString selectedCategoryFilter = 'all'.obs; // Pour filtrer la liste
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedSortBy = 'name'.obs;
  final RxBool sortAscending = true.obs;

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

  // Variables pour les sélections (formulaire)
  final RxString selectedCategoryForm =
      ''.obs; // Catégorie sélectionnée dans le formulaire
  final RxString selectedUnit =
      'pièce'.obs; // Unité sélectionnée dans le formulaire

  // Variables pour les mouvements de stock
  final RxString selectedMovementType = 'in'.obs;
  final TextEditingController movementQuantityController =
      TextEditingController();
  final TextEditingController movementReasonController =
      TextEditingController();
  final TextEditingController movementReferenceController =
      TextEditingController();
  final TextEditingController movementNotesController = TextEditingController();

  // Variables pour l'ajustement de stock
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

  @override
  void onInit() {
    super.onInit();
    try {
      _stockService = Get.find<StockService>();
    } catch (e) {
      // Essayer de créer le service s'il n'existe pas
      _stockService = Get.put(StockService(), permanent: true);
    }
    loadStocks();
    loadCategories();
    loadStockStats();
    loadStockAlerts();
  }

  @override
  void onClose() {
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
    super.onClose();
  }

  // Charger les stocks
  Future<void> loadStocks() async {
    try {
      isLoading.value = true;
      AppLogger.info('Chargement des stocks', tag: 'STOCK_CONTROLLER');

      // Charger tous les stocks depuis l'API directement
      // (on ne teste plus la connectivité car ça peut échouer même si l'API fonctionne)
      final loadedStocks = await _stockService.getStocks(
        search: null, // Pas de recherche côté serveur
        category: null, // Pas de filtre côté serveur
        status: null, // Pas de filtre côté serveur
      );
      // Stocker tous les stocks
      allStocks.assignAll(loadedStocks);

      // Copier tous les stocks dans la liste filtrée par défaut
      // Le filtrage par onglet se fait dans la vue
      stocks.assignAll(loadedStocks);

      AppLogger.info(
        '${loadedStocks.length} stocks chargés avec succès',
        tag: 'STOCK_CONTROLLER',
      );

      // Afficher un message de succès si des stocks sont trouvés
      if (loadedStocks.isNotEmpty) {
        Get.snackbar(
          'Succès',
          '${loadedStocks.length} stocks chargés avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Vider la liste des stocks en cas d'erreur
      allStocks.value = [];
      stocks.value = [];

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

  // Charger les catégories
  Future<void> loadCategories() async {
    try {
      final categoriesList = await _stockService.getStockCategories();
      categories.value = categoriesList;
    } catch (e) {
      // Laisser la liste vide en cas d'erreur
      categories.value = [];
    }
  }

  // Charger les statistiques
  Future<void> loadStockStats() async {
    try {
      final stats = await _stockService.getStockStats();
      stockStats.value = stats;
    } catch (e) {
      // Calculer les statistiques à partir des stocks chargés
      final totalValue = allStocks.fold(
        0.0,
        (sum, stock) => sum + stock.totalValue,
      );
      stockStats.value = StockStats(
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
      alerts.value = alertsList;
    } catch (e) {
      // Laisser la liste vide en cas d'erreur
      alerts.clear();
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    List<Stock> filteredStocks = List.from(allStocks);

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      filteredStocks =
          filteredStocks.where((stock) {
            // Comparer avec le statut réel du stock
            final stockStatus = stock.status.toLowerCase();
            final matches =
                stockStatus == selectedStatus.value.toLowerCase() ||
                (selectedStatus.value == 'en_attente' &&
                    stockStatus == 'pending') ||
                (selectedStatus.value == 'valide' &&
                    stockStatus == 'approved') ||
                (selectedStatus.value == 'rejete' && stockStatus == 'rejected');
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    // Filtrer par catégorie
    if (selectedCategoryFilter.value != 'all') {
      filteredStocks =
          filteredStocks.where((stock) {
            final matches = stock.category == selectedCategoryFilter.value;
            if (!matches) {}
            return matches;
          }).toList();
    } else {}

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
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

    stocks.assignAll(filteredStocks);
  }

  // Rechercher des stocks
  void searchStocks(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategoryFilter.value = category;
    loadStocks();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadStocks();
  }

  // Trier les stocks
  void sortStocks(String sortBy) {
    if (selectedSortBy.value == sortBy) {
      sortAscending.value = !sortAscending.value;
    } else {
      selectedSortBy.value = sortBy;
      sortAscending.value = true;
    }
    _applySorting();
  }

  // Appliquer le tri
  void _applySorting() {
    stocks.sort((a, b) {
      int comparison = 0;
      switch (selectedSortBy.value) {
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
      return sortAscending.value ? comparison : -comparison;
    });
  }

  // Obtenir les stocks filtrés
  List<Stock> get filteredStocks {
    List<Stock> filtered = stocks;

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (stock) =>
                    stock.name.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    stock.sku.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    (stock.description?.toLowerCase() ?? '').contains(
                      searchQuery.value.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (selectedCategoryFilter.value != 'all') {
      filtered =
          filtered
              .where((stock) => stock.category == selectedCategoryFilter.value)
              .toList();
    }

    if (selectedStatus.value != 'all') {
      filtered =
          filtered
              .where((stock) => stock.stockStatus == selectedStatus.value)
              .toList();
    }

    return filtered;
  }

  // Créer un nouveau stock
  Future<bool> createStock() async {
    try {
      isCreating.value = true;

      // Valider que category est fourni
      if (selectedCategoryForm.value.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner une catégorie',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Valider que le nom n'est pas vide
      if (nameController.text.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez saisir un nom pour le produit',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // Valider que le SKU n'est pas vide
      if (skuController.text.trim().isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez saisir un SKU pour le produit',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final stock = Stock(
        category: selectedCategoryForm.value,
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

      await _stockService.createStock(stock);

      Get.snackbar(
        'Succès',
        'Stock créé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
      clearForm();
      loadStocks();
      loadStockStats();
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

      Get.snackbar(
        'Erreur',
        'Erreur lors de la création du stock: $errorMessage',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
      return false;
    } finally {
      isCreating.value = false;
    }
  }

  // Mettre à jour un stock
  Future<bool> updateStock(Stock stock) async {
    try {
      isUpdating.value = true;

      // Valider que category est fourni
      if (selectedCategoryForm.value.isEmpty) {
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner une catégorie',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      final updatedStock = stock.copyWith(
        category: selectedCategoryForm.value,
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

      Get.snackbar(
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
      Get.snackbar(
        'Erreur',
        'Erreur lors de la mise à jour du stock: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      isUpdating.value = false;
    }
  }

  // Supprimer un stock
  Future<void> deleteStock(Stock stock) async {
    try {
      isDeleting.value = true;

      await _stockService.deleteStock(stock.id!);

      Get.snackbar('Succès', 'Stock supprimé avec succès');
      loadStocks();
      loadStockStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la suppression du stock: $e');
    } finally {
      isDeleting.value = false;
    }
  }

  // Remplir le formulaire pour l'édition
  void fillForm(Stock stock) {
    nameController.text = stock.name;
    descriptionController.text = stock.description ?? '';
    selectedCategoryForm.value = stock.category;
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
    selectedCategoryForm.value = '';
    selectedUnit.value = 'pièce';
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
        type: selectedMovementType.value,
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

      Get.snackbar('Succès', 'Mouvement de stock ajouté');
      clearMovementForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'ajout du mouvement: $e');
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

      Get.snackbar('Succès', 'Stock ajusté avec succès');
      clearAdjustmentForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de l\'ajustement du stock: $e');
    }
  }

  // Vider le formulaire de mouvement
  void clearMovementForm() {
    selectedMovementType.value = 'in';
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
    selectedCategoryForm.value = category;
  }

  // Sélectionner une unité
  void selectUnit(String unit) {
    selectedUnit.value = unit;
  }

  // Sélectionner un type de mouvement
  void selectMovementType(String type) {
    selectedMovementType.value = type;
  }

  // Sélectionner un stock
  void selectStock(Stock stock) {
    selectedStock.value = stock;
  }

  // Approuver/Valider un stock
  Future<void> approveStock(Stock stock, {String? validationComment}) async {
    try {
      isLoading.value = true;
      await _stockService.approveStock(
        stockId: stock.id!,
        validationComment: validationComment,
      );
      await loadStocks();
      Get.snackbar(
        'Succès',
        'Stock approuvé avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de l\'approbation: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter un stock (selon la doc API)
  void rejectStock(Stock stock, {String? commentaire}) async {
    try {
      isLoading.value = true;
      await _stockService.rejectStock(
        stockId: stock.id!,
        commentaire: commentaire ?? 'Rejeté par le patron',
      );
      await loadStocks();
      Get.snackbar(
        'Succès',
        'Stock rejeté avec succès',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors du rejet: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Filtrage par statut d'approbation
  void filterByApprovalStatus(String status) {
    selectedStatus.value = status;
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
