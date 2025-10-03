import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/stock_model.dart';
import 'package:easyconnect/services/stock_service.dart';

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
  final RxString selectedCategory = 'all'.obs;
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
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController unitController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController supplierController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController imageController = TextEditingController();

  // Variables pour les sélections
  final RxString selectedCategoryForm = ''.obs;
  final RxString selectedUnit = 'pièce'.obs;
  final RxString selectedLocation = ''.obs;
  final RxString selectedSupplier = ''.obs;

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
      print('✅ StockController: StockService trouvé');
    } catch (e) {
      print('❌ StockController: StockService non trouvé: $e');
      // Essayer de créer le service s'il n'existe pas
      _stockService = Get.put(StockService(), permanent: true);
      print('✅ StockController: StockService créé');
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
    unitPriceController.dispose();
    unitController.dispose();
    locationController.dispose();
    supplierController.dispose();
    barcodeController.dispose();
    imageController.dispose();
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
    print('🔄 StockController: loadStocks() appelé');
    try {
      isLoading.value = true;
      print('⏳ StockController: Chargement en cours...');

      // Tester la connectivité d'abord
      print('🧪 StockController: Test de connectivité...');
      final isConnected = await _stockService.testConnection();
      print('🔗 StockController: Connectivité: ${isConnected ? "✅" : "❌"}');

      if (!isConnected) {
        throw Exception('Impossible de se connecter à l\'API Laravel');
      }

      // Charger tous les stocks depuis l'API
      final loadedStocks = await _stockService.getStocks(
        search: null, // Pas de recherche côté serveur
        category: null, // Pas de filtre côté serveur
        status: null, // Pas de filtre côté serveur
      );

      print(
        '📦 StockController: ${loadedStocks.length} stocks reçus du service',
      );

      // Stocker tous les stocks
      allStocks.assignAll(loadedStocks);

      // Appliquer les filtres côté client
      applyFilters();

      print(
        '✅ StockController: Liste mise à jour avec ${stocks.length} stocks filtrés',
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
      print('❌ StockController: Erreur lors du chargement: $e');

      // Vider la liste des stocks en cas d'erreur
      allStocks.value = [];
      stocks.value = [];

      // Message d'erreur spécifique selon le type d'erreur
      String errorMessage;
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection refused')) {
        errorMessage =
            'Impossible de se connecter au serveur. Vérifiez votre connexion internet.';
      } else if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage = 'Session expirée. Veuillez vous reconnecter.';
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
      print('🏁 StockController: Chargement terminé');
    }
  }

  // Charger les catégories
  Future<void> loadCategories() async {
    try {
      print('🔄 StockController: loadCategories() appelé');
      final categoriesList = await _stockService.getStockCategories();
      categories.value = categoriesList;
      print('✅ StockController: ${categoriesList.length} catégories chargées');
    } catch (e) {
      print('❌ StockController: Erreur lors du chargement des catégories: $e');
      // Laisser la liste vide en cas d'erreur
      categories.value = [];
    }
  }

  // Charger les statistiques
  Future<void> loadStockStats() async {
    try {
      print('🔄 StockController: loadStockStats() appelé');
      final stats = await _stockService.getStockStats();
      stockStats.value = stats;
      print('✅ StockController: Statistiques chargées');
    } catch (e) {
      print(
        '❌ StockController: Erreur lors du chargement des statistiques: $e',
      );
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
      print('📊 StockController: Statistiques calculées localement');
    }
  }

  // Charger les alertes
  Future<void> loadStockAlerts() async {
    try {
      print('🔄 StockController: loadStockAlerts() appelé');
      final alertsList = await _stockService.getStockAlerts();
      alerts.value = alertsList;
      print('✅ StockController: ${alertsList.length} alertes chargées');
    } catch (e) {
      print('❌ StockController: Erreur lors du chargement des alertes: $e');
      // Laisser la liste vide en cas d'erreur
      alerts.clear();
    }
  }

  // Appliquer les filtres côté client
  void applyFilters() {
    print('🔍 StockController: applyFilters() appelé');
    print('📊 StockController: Statut sélectionné: ${selectedStatus.value}');
    print(
      '📂 StockController: Catégorie sélectionnée: ${selectedCategory.value}',
    );
    print('🔍 StockController: Recherche: "${searchQuery.value}"');
    print('📦 StockController: Total stocks: ${allStocks.length}');

    List<Stock> filteredStocks = List.from(allStocks);

    // Filtrer par statut
    if (selectedStatus.value != 'all') {
      print('🔍 StockController: Filtrage par statut: ${selectedStatus.value}');
      final beforeCount = filteredStocks.length;
      filteredStocks =
          filteredStocks.where((stock) {
            final matches = stock.stockStatusColor == selectedStatus.value;
            if (!matches) {
              print(
                '❌ StockController: Stock "${stock.name}" rejeté (statut: ${stock.stockStatusColor})',
              );
            }
            return matches;
          }).toList();
      print(
        '📊 StockController: Après filtrage par statut: $beforeCount → ${filteredStocks.length}',
      );
    } else {
      print('📊 StockController: Pas de filtrage par statut (all)');
    }

    // Filtrer par catégorie
    if (selectedCategory.value != 'all') {
      print(
        '📂 StockController: Filtrage par catégorie: ${selectedCategory.value}',
      );
      final beforeCount = filteredStocks.length;
      filteredStocks =
          filteredStocks.where((stock) {
            final matches = stock.category == selectedCategory.value;
            if (!matches) {
              print(
                '❌ StockController: Stock "${stock.name}" rejeté par catégorie (${stock.category})',
              );
            }
            return matches;
          }).toList();
      print(
        '📂 StockController: Après filtrage par catégorie: $beforeCount → ${filteredStocks.length}',
      );
    } else {
      print('📂 StockController: Pas de filtrage par catégorie (all)');
    }

    // Filtrer par recherche
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      print('🔍 StockController: Filtrage par recherche: "$query"');
      final beforeCount = filteredStocks.length;
      filteredStocks =
          filteredStocks.where((stock) {
            final matches =
                stock.name.toLowerCase().contains(query) ||
                stock.sku.toLowerCase().contains(query) ||
                stock.category.toLowerCase().contains(query);
            if (!matches) {
              print(
                '❌ StockController: Stock "${stock.name}" rejeté par recherche',
              );
            }
            return matches;
          }).toList();
      print(
        '🔍 StockController: Après filtrage par recherche: $beforeCount → ${filteredStocks.length}',
      );
    } else {
      print('🔍 StockController: Pas de filtrage par recherche');
    }

    stocks.assignAll(filteredStocks);
    print(
      '✅ StockController: Filtrage terminé - ${stocks.length} stocks affichés',
    );
  }

  // Rechercher des stocks
  void searchStocks(String query) {
    print('🔍 StockController: searchStocks("$query") appelé');
    searchQuery.value = query;
    applyFilters();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategory.value = category;
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
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'updated_at':
          comparison = a.updatedAt.compareTo(b.updatedAt);
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
                    stock.description.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ),
              )
              .toList();
    }

    if (selectedCategory.value != 'all') {
      filtered =
          filtered
              .where((stock) => stock.category == selectedCategory.value)
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
  Future<void> createStock() async {
    try {
      isCreating.value = true;

      await _stockService.createStock(
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm.value,
        sku: skuController.text.trim(),
        quantity: double.parse(quantityController.text),
        minQuantity: double.parse(minQuantityController.text),
        maxQuantity: double.parse(maxQuantityController.text),
        unitPrice: double.parse(unitPriceController.text),
        unit: selectedUnit.value,
        location:
            locationController.text.trim().isNotEmpty
                ? locationController.text.trim()
                : null,
        supplier:
            supplierController.text.trim().isNotEmpty
                ? supplierController.text.trim()
                : null,
        barcode:
            barcodeController.text.trim().isNotEmpty
                ? barcodeController.text.trim()
                : null,
        image:
            imageController.text.trim().isNotEmpty
                ? imageController.text.trim()
                : null,
      );

      Get.snackbar('Succès', 'Stock créé avec succès');
      clearForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la création du stock: $e');
    } finally {
      isCreating.value = false;
    }
  }

  // Mettre à jour un stock
  Future<void> updateStock(Stock stock) async {
    try {
      isUpdating.value = true;

      await _stockService.updateStock(
        id: stock.id!,
        name: nameController.text.trim(),
        description: descriptionController.text.trim(),
        category: selectedCategoryForm.value,
        sku: skuController.text.trim(),
        minQuantity: double.parse(minQuantityController.text),
        maxQuantity: double.parse(maxQuantityController.text),
        unitPrice: double.parse(unitPriceController.text),
        unit: selectedUnit.value,
        location:
            locationController.text.trim().isNotEmpty
                ? locationController.text.trim()
                : null,
        supplier:
            supplierController.text.trim().isNotEmpty
                ? supplierController.text.trim()
                : null,
        barcode:
            barcodeController.text.trim().isNotEmpty
                ? barcodeController.text.trim()
                : null,
        image:
            imageController.text.trim().isNotEmpty
                ? imageController.text.trim()
                : null,
      );

      Get.snackbar('Succès', 'Stock mis à jour avec succès');
      clearForm();
      loadStocks();
      loadStockStats();
    } catch (e) {
      Get.snackbar('Erreur', 'Erreur lors de la mise à jour du stock: $e');
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
    descriptionController.text = stock.description;
    selectedCategoryForm.value = stock.category;
    skuController.text = stock.sku;
    quantityController.text = stock.quantity.toString();
    minQuantityController.text = stock.minQuantity.toString();
    maxQuantityController.text = stock.maxQuantity.toString();
    unitPriceController.text = stock.unitPrice.toString();
    selectedUnit.value = stock.unit;
    locationController.text = stock.location ?? '';
    supplierController.text = stock.supplier ?? '';
    barcodeController.text = stock.barcode ?? '';
    imageController.text = stock.image ?? '';
  }

  // Vider le formulaire
  void clearForm() {
    nameController.clear();
    descriptionController.clear();
    selectedCategoryForm.value = '';
    skuController.clear();
    quantityController.clear();
    minQuantityController.clear();
    maxQuantityController.clear();
    unitPriceController.clear();
    selectedUnit.value = 'pièce';
    locationController.clear();
    supplierController.clear();
    barcodeController.clear();
    imageController.clear();
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

  // Sélectionner une catégorie
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

  // Gestion des statuts d'approbation
  void approveStock(Stock stock) async {
    try {
      isLoading.value = true;
      await _stockService.updateStockStatus(stock.id!, 'approved', null);
      await loadStocks();
      Get.snackbar(
        'Succès',
        'Produit approuvé avec succès',
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

  void rejectStock(Stock stock) async {
    try {
      isLoading.value = true;
      await _stockService.updateStockStatus(stock.id!, 'rejected', null);
      await loadStocks();
      Get.snackbar(
        'Succès',
        'Produit rejeté avec succès',
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

  void resetStockStatus(Stock stock) async {
    try {
      isLoading.value = true;
      await _stockService.updateStockStatus(stock.id!, 'pending', null);
      await loadStocks();
      Get.snackbar(
        'Succès',
        'Statut réinitialisé avec succès',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la réinitialisation: $e',
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

  // Obtenir les stocks par statut d'approbation
  List<Stock> getStocksByApprovalStatus(String status) {
    switch (status) {
      case 'pending':
        return stocks.where((stock) => stock.isPending).toList();
      case 'approved':
        return stocks.where((stock) => stock.isApproved).toList();
      case 'rejected':
        return stocks.where((stock) => stock.isRejected).toList();
      default:
        return stocks;
    }
  }

  // Tester la connectivité à l'API
  Future<bool> testApiConnection() async {
    try {
      print('🧪 StockController: Test de connectivité API...');
      return await _stockService.testConnection();
    } catch (e) {
      print('❌ StockController: Erreur de test de connectivité: $e');
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
