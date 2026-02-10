import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class ExpenseController extends GetxController {
  final ExpenseService _expenseService = ExpenseService();
  final AuthController _authController = Get.find<AuthController>();

  // Variables observables
  final RxList<Expense> expenses = <Expense>[].obs;
  final RxList<Expense> pendingExpenses = <Expense>[].obs;
  final RxList<ExpenseCategory> expenseCategories = <ExpenseCategory>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<ExpenseStats?> expenseStats = Rx<ExpenseStats?>(null);

  // Variables pour le formulaire
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedCategory = 'all'.obs;
  final Rx<Expense?> selectedExpense = Rx<Expense?>(null);

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;

  // Contrôleurs de formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxString selectedCategoryForm = 'office_supplies'.obs;
  final RxInt selectedCategoryId = 0.obs;
  final Rx<DateTime?> selectedExpenseDate = Rx<DateTime?>(null);
  final Rx<String?> selectedReceiptPath = Rx<String?>(null);
  final RxString currency = 'FCFA'.obs;

  @override
  void onInit() {
    super.onInit();
    // Charger les données de manière asynchrone pour ne pas bloquer l'UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadExpenses();
      loadExpenseStats();
      loadPendingExpenses();
      loadExpenseCategories();
    });
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.onClose();
  }

  // Charger toutes les dépenses
  Future<void> loadExpenses({int page = 1}) async {
    try {
      // Afficher immédiatement les données du cache si disponibles (seulement page 1)
      final cacheKey =
          'expenses_${selectedStatus.value}_${selectedCategory.value}';
      final cachedExpenses = CacheHelper.get<List<Expense>>(cacheKey);
      if (cachedExpenses != null && cachedExpenses.isNotEmpty && page == 1) {
        expenses.assignAll(cachedExpenses);
        isLoading.value = false; // Permettre l'affichage immédiat
      } else {
        isLoading.value = true;
      }

      try {
        // Utiliser la méthode paginée
        final paginatedResponse = await _expenseService.getExpensesPaginated(
          status: selectedStatus.value == 'all' ? null : selectedStatus.value,
          category:
              selectedCategory.value == 'all' ? null : selectedCategory.value,
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
          expenses.value = paginatedResponse.data;
        } else {
          // Pour les pages suivantes, ajouter les données
          expenses.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        final loadedExpenses = await _expenseService.getExpenses(
          status: selectedStatus.value == 'all' ? null : selectedStatus.value,
          category:
              selectedCategory.value == 'all' ? null : selectedCategory.value,
          search: searchQuery.value.isEmpty ? null : searchQuery.value,
        );
        if (loadedExpenses.isNotEmpty) {
          if (page == 1) {
            expenses.value = loadedExpenses;
          } else {
            expenses.addAll(loadedExpenses);
          }
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedExpenses);
          }
        } else if (expenses.isEmpty) {
          expenses.clear();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des dépenses: $e',
        tag: 'EXPENSE_CONTROLLER',
      );

      // Ne pas afficher d'erreur si la liste n'est pas vide (données du cache disponibles)
      // Cela évite d'afficher une erreur après une création réussie
      // Ne pas vider la liste si elle contient déjà des données
      if (expenses.isEmpty) {
        // Vérifier une dernière fois le cache avant d'afficher l'erreur
        final cacheKey =
            'expenses_${selectedStatus.value == 'all' ? 'all' : selectedStatus.value}_${selectedCategory.value == 'all' ? 'all' : selectedCategory.value}';
        final cachedExpenses = CacheHelper.get<List<Expense>>(cacheKey);
        if (cachedExpenses == null || cachedExpenses.isEmpty) {
          // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
          final errorString = e.toString().toLowerCase();
          if (!errorString.contains('session expirée') &&
              !errorString.contains('401') &&
              !errorString.contains('unauthorized')) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les dépenses',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.orange,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
            );
          }
        } else {
          // Charger les données du cache si disponibles
          expenses.assignAll(cachedExpenses);
        }
      } else {
        // Si la liste contient des données, on garde ce qu'on a
        // Cela permet d'afficher la dépense créée même si le rechargement échoue
        AppLogger.info(
          'Liste des dépenses conservée (${expenses.length} dépenses) malgré l\'erreur de rechargement',
          tag: 'EXPENSE_CONTROLLER',
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
      loadExpenses(page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadExpenses(page: currentPage.value - 1);
    }
  }

  // Charger les dépenses en attente
  Future<void> loadPendingExpenses() async {
    try {
      final pending = await _expenseService.getPendingExpenses();
      pendingExpenses.assignAll(pending);
    } catch (e) {}
  }

  // Charger les catégories
  Future<void> loadExpenseCategories() async {
    try {
      final categories = await _expenseService.getExpenseCategories();
      expenseCategories.assignAll(categories);
    } catch (e) {}
  }

  // Charger les statistiques
  Future<void> loadExpenseStats() async {
    try {
      final stats = await _expenseService.getExpenseStats();
      expenseStats.value = stats;
    } catch (e) {}
  }

  // Créer une dépense
  Future<bool> createExpense() async {
    try {
      isLoading.value = true;

      // Trouver l'ID de la catégorie depuis la liste chargée
      int? categoryId;
      if (expenseCategories.isNotEmpty) {
        // Chercher la catégorie par son nom/slug
        final category = expenseCategories.firstWhereOrNull(
          (cat) =>
              cat.name.toLowerCase() ==
                  selectedCategoryForm.value.toLowerCase() ||
              cat.id.toString() == selectedCategoryForm.value,
        );
        categoryId = category?.id;
      }

      // Si aucune catégorie trouvée, utiliser selectedCategoryId ou essayer de parser
      if (categoryId == null) {
        categoryId =
            selectedCategoryId.value > 0 ? selectedCategoryId.value : null;
        // Si toujours null, essayer de parser selectedCategoryForm comme ID
        if (categoryId == null) {
          categoryId = int.tryParse(selectedCategoryForm.value);
        }
      }

      // Récupérer l'utilisateur connecté
      final user = _authController.userAuth.value;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Validation - s'assurer que title n'est pas vide
      if (titleController.text.trim().isEmpty) {
        throw Exception('Le titre de la dépense est obligatoire');
      }

      // Préparer les données selon ce que le backend Laravel attend
      // Le backend transforme 'category' en 'expense_category_id' via relation
      final titleValue = titleController.text.trim();

      final expenseData = <String, dynamic>{
        'title': titleValue,
        'description': descriptionController.text.trim(),
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'currency': currency.value,
        'expense_date':
            (selectedExpenseDate.value ?? DateTime.now()).toIso8601String(),
        'user_id': user.id, // Ajouter l'ID de l'utilisateur connecté
        'employee_id': user.id, // Peut aussi être utilisé par le backend
        'status':
            'pending', // Statut valide : pending, approved, rejected (pas 'draft')
      };

      // Envoyer l'ID de catégorie si on l'a trouvé depuis les catégories de l'API
      // Le backend transforme probablement 'category' en 'expense_category_id'
      if (selectedCategoryId.value > 0) {
        expenseData['category'] = selectedCategoryId.value.toString();
      } else if (categoryId != null && categoryId > 0) {
        expenseData['category'] = categoryId.toString();
      } else {
        expenseData['category'] = selectedCategoryForm.value;
      }

      // Ajouter les champs optionnels seulement s'ils ne sont pas null ou vides
      if (selectedReceiptPath.value != null &&
          selectedReceiptPath.value!.isNotEmpty) {
        expenseData['receipt_path'] = selectedReceiptPath.value;
      }

      // Notes peut être utilisé comme justification
      if (notesController.text.trim().isNotEmpty) {
        expenseData['notes'] = notesController.text.trim();
        expenseData['justification'] = notesController.text.trim();
      }

      final createdExpense = await _expenseService.createExpense(expenseData);

      // Invalider le cache
      CacheHelper.clearByPrefix('expenses_');

      // Ajouter la dépense créée à la liste localement (mise à jour optimiste)
      // S'assurer que la dépense est ajoutée avant de naviguer
      if (createdExpense.id != null) {
        expenses.add(createdExpense);
        // Appliquer les filtres si nécessaire pour que la dépense apparaisse dans la liste filtrée
        // La liste filtrée sera mise à jour automatiquement grâce à Obx

        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName(
            'expense',
            createdExpense,
          ),
          entityId: createdExpense.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'expense',
            createdExpense.id.toString(),
          ),
        );
      }

      // Afficher le message de succès immédiatement
      Get.snackbar(
        'Succès',
        'Dépense créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      // Rafraîchir les compteurs et recharger en arrière-plan (non-bloquant)
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter('expense');

        // Recharger les données en arrière-plan sans bloquer l'UI
        loadExpenses().catchError((e) {
          AppLogger.error(
            'Erreur lors du rechargement après création: $e',
            tag: 'EXPENSE_CONTROLLER',
          );
          // Ne pas afficher d'erreur à l'utilisateur car la création a réussi
        });

        loadExpenseStats().catchError((e) {
          AppLogger.error(
            'Erreur lors du rechargement des stats: $e',
            tag: 'EXPENSE_CONTROLLER',
          );
        });
      });

      clearForm();
      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la dépense: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour une dépense
  Future<bool> updateExpense(Expense expense) async {
    try {
      isLoading.value = true;

      // Trouver l'ID de la catégorie depuis la liste chargée
      int? categoryId;
      if (expenseCategories.isNotEmpty) {
        // Chercher la catégorie par son nom/slug
        final category = expenseCategories.firstWhereOrNull(
          (cat) =>
              cat.name.toLowerCase() ==
                  selectedCategoryForm.value.toLowerCase() ||
              cat.id.toString() == selectedCategoryForm.value,
        );
        categoryId = category?.id;
      }

      // Si aucune catégorie trouvée, utiliser selectedCategoryId ou essayer de parser
      if (categoryId == null) {
        categoryId =
            selectedCategoryId.value > 0 ? selectedCategoryId.value : null;
        // Si toujours null, essayer de parser selectedCategoryForm comme ID
        if (categoryId == null) {
          categoryId = int.tryParse(selectedCategoryForm.value);
        }
      }

      // Récupérer l'utilisateur connecté
      final user = _authController.userAuth.value;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Validation - s'assurer que title n'est pas vide
      if (titleController.text.trim().isEmpty) {
        throw Exception('Le titre de la dépense est obligatoire');
      }

      // Préparer les données selon ce que le backend Laravel attend
      final expenseData = <String, dynamic>{
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'currency': currency.value,
        'expense_date':
            (selectedExpenseDate.value ?? expense.expenseDate)
                .toIso8601String(),
        'user_id': user.id, // Ajouter l'ID de l'utilisateur connecté
        'employee_id': user.id, // Peut aussi être utilisé par le backend
        'status':
            expense
                .status, // Conserver le statut existant lors de la mise à jour
      };

      // Envoyer l'ID de catégorie si on l'a trouvé depuis les catégories de l'API
      if (selectedCategoryId.value > 0) {
        expenseData['category'] = selectedCategoryId.value.toString();
      } else if (categoryId != null && categoryId > 0) {
        expenseData['category'] = categoryId.toString();
      } else {
        expenseData['category'] = selectedCategoryForm.value;
      }

      // Ajouter les champs optionnels seulement s'ils ne sont pas null ou vides
      if (selectedReceiptPath.value != null &&
          selectedReceiptPath.value!.isNotEmpty) {
        expenseData['receipt_path'] = selectedReceiptPath.value;
      } else if (expense.receiptPath != null) {
        expenseData['receipt_path'] = expense.receiptPath;
      }

      // Notes peut être utilisé comme justification
      if (notesController.text.trim().isNotEmpty) {
        expenseData['notes'] = notesController.text.trim();
        expenseData['justification'] = notesController.text.trim();
      }

      await _expenseService.updateExpense(expense.id!, expenseData);
      await loadExpenses();
      await loadExpenseStats();

      Get.snackbar(
        'Succès',
        'Dépense mise à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la dépense: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Soumettre une dépense au patron
  Future<void> submitExpense(Expense expense) async {
    try {
      isLoading.value = true;

      final success = await _expenseService.submitExpense(expense.id!);

      if (success) {
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

        // Notifier le patron de la soumission
        NotificationHelper.notifySubmission(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName(
            'expense',
            expense,
          ),
          entityId: expense.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'expense',
            expense.id.toString(),
          ),
        );

        Get.snackbar(
          'Succès',
          'Dépense soumise au patron',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre la dépense: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver une dépense
  Future<void> approveExpense(Expense expense) async {
    try {
      print(
        '🔵 [EXPENSE_CONTROLLER] approveExpense() appelé pour expenseId: ${expense.id}',
      );
      isLoading.value = true;

      final success = await _expenseService.approveExpense(
        expense.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        // Notifier l'utilisateur concerné de la validation
        NotificationHelper.notifyValidation(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName(
            'expense',
            expense,
          ),
          entityId: expense.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'expense',
            expense.id.toString(),
          ),
          entity: expense,
        );

        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

        Get.snackbar(
          'Succès',
          'Dépense approuvée',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception(
          'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
        );
      }
    } catch (e, stackTrace) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver la dépense: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Rejeter une dépense
  Future<void> rejectExpense(Expense expense, String reason) async {
    try {
      isLoading.value = true;

      final success = await _expenseService.rejectExpense(
        expense.id!,
        reason: reason,
      );

      if (success) {
        // Notifier l'utilisateur concerné du rejet
        NotificationHelper.notifyRejection(
          entityType: 'expense',
          entityName: NotificationHelper.getEntityDisplayName(
            'expense',
            expense,
          ),
          entityId: expense.id.toString(),
          reason: reason,
          route: NotificationHelper.getEntityRoute(
            'expense',
            expense.id.toString(),
          ),
          entity: expense,
        );

        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

        Get.snackbar(
          'Succès',
          'Dépense rejetée',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
      } else {
        throw Exception(
          'Erreur lors du rejet - La réponse du serveur indique un échec',
        );
      }
    } catch (e, stackTrace) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la dépense: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Supprimer une dépense
  Future<void> deleteExpense(Expense expense) async {
    try {
      isLoading.value = true;

      final success = await _expenseService.deleteExpense(expense.id!);
      if (success) {
        expenses.removeWhere((e) => e.id == expense.id);
        await loadExpenseStats();

        Get.snackbar(
          'Succès',
          'Dépense supprimée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer la dépense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Remplir le formulaire avec les données d'une dépense
  void fillForm(Expense expense) {
    titleController.text = expense.title;
    descriptionController.text = expense.description;
    amountController.text = expense.amount.toString();
    selectedCategoryForm.value = expense.category;
    selectedExpenseDate.value = expense.expenseDate;
    selectedReceiptPath.value = expense.receiptPath;
    notesController.text = expense.notes ?? '';
    selectedExpense.value = expense;
    // La devise sera définie par défaut à FCFA si non présente
  }

  // Sélectionner un justificatif (photo)
  Future<void> selectReceipt() async {
    try {
      final cameraService = CameraService();

      // Proposer à l'utilisateur de choisir la source
      final source = await Get.dialog<ImageSource>(
        AlertDialog(
          title: const Text('Sélectionner une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Get.back(result: ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Get.back(result: ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      File? imageFile;
      if (source == ImageSource.camera) {
        imageFile = await cameraService.takePicture();
      } else {
        imageFile = await cameraService.pickImageFromGallery();
      }

      if (imageFile != null) {
        // Valider l'image
        await cameraService.validateImage(imageFile);

        // Stocker le chemin de l'image
        selectedReceiptPath.value = imageFile.path;

        Get.snackbar(
          'Succès',
          'Justificatif sélectionné',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Vider le formulaire
  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    amountController.clear();
    notesController.clear();
    selectedCategoryForm.value = 'office_supplies';
    selectedExpenseDate.value = null;
    selectedReceiptPath.value = null;
    selectedExpense.value = null;
    currency.value = 'FCFA';
  }

  // Rechercher
  void searchExpenses(String query) {
    searchQuery.value = query;
    loadExpenses();
  }

  // Filtrer par statut
  void filterByStatus(String status) {
    selectedStatus.value = status;
    loadExpenses();
  }

  // Filtrer par catégorie
  void filterByCategory(String category) {
    selectedCategory.value = category;
    loadExpenses();
  }

  // Sélectionner la date de dépense
  Future<void> selectExpenseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedExpenseDate.value ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedExpenseDate.value = picked;
    }
  }

  // Obtenir les catégories de dépenses
  List<Map<String, dynamic>> get expenseCategoriesList => [
    {
      'value': 'office_supplies',
      'label': 'Fournitures de bureau',
      'color': Colors.blue,
    },
    {'value': 'travel', 'label': 'Voyage', 'color': Colors.purple},
    {'value': 'meals', 'label': 'Repas', 'color': Colors.orange},
    {'value': 'transport', 'label': 'Transport', 'color': Colors.green},
    {'value': 'utilities', 'label': 'Services publics', 'color': Colors.red},
    {'value': 'marketing', 'label': 'Marketing', 'color': Colors.pink},
    {'value': 'equipment', 'label': 'Équipement', 'color': Colors.indigo},
    {'value': 'other', 'label': 'Autre', 'color': Colors.grey},
  ];

  // Vérifier les permissions
  bool get canManageExpenses {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 3; // Admin, Comptable
  }

  bool get canApproveExpenses {
    final userRole = _authController.userAuth.value?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewExpenses {
    final userRole = _authController.userAuth.value?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les dépenses par statut
  List<Expense> get expensesByStatus {
    if (selectedStatus.value == 'all') return expenses;
    return expenses
        .where((expense) => expense.status == selectedStatus.value)
        .toList();
  }

  // Obtenir les dépenses par catégorie
  List<Expense> get expensesByCategory {
    if (selectedCategory.value == 'all') return expenses;
    return expenses
        .where((expense) => expense.category == selectedCategory.value)
        .toList();
  }

  // Obtenir les dépenses filtrées
  List<Expense> get filteredExpenses {
    List<Expense> filtered = expenses;

    if (selectedStatus.value != 'all') {
      filtered =
          filtered
              .where((expense) => expense.status == selectedStatus.value)
              .toList();
    }

    if (selectedCategory.value != 'all') {
      filtered =
          filtered
              .where((expense) => expense.category == selectedCategory.value)
              .toList();
    }

    if (searchQuery.value.isNotEmpty) {
      filtered =
          filtered
              .where(
                (expense) =>
                    expense.title.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ) ||
                    expense.description.toLowerCase().contains(
                      searchQuery.value.toLowerCase(),
                    ),
              )
              .toList();
    }

    return filtered;
  }
}
