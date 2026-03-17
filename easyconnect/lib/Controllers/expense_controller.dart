import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

ExpenseCategory? _firstWhereExpenseCategory(
  List<ExpenseCategory> list,
  bool Function(ExpenseCategory) test,
) {
  try {
    return list.firstWhere(test);
  } catch (_) {
    return null;
  }
}

class ExpenseController {
  static final ExpenseController _instance = ExpenseController._();
  static ExpenseController get to => _instance;
  factory ExpenseController() => _instance;
  ExpenseController._();

  final ExpenseService _expenseService = ExpenseService();

  // Variables
  final List<Expense> expenses = [];
  final List<Expense> pendingExpenses = [];
  final List<ExpenseCategory> expenseCategories = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  ExpenseStats? expenseStats;

  // Variables pour le formulaire
  String searchQuery = '';
  String selectedStatus = 'all';
  String selectedCategory = 'all';
  Expense? selectedExpense;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  final ScrollController scrollController = ScrollController();

  // Contrôleurs de formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String selectedCategoryForm = 'office_supplies';
  int selectedCategoryId = 0;
  DateTime? selectedExpenseDate;
  String? selectedReceiptPath;
  String currency = 'FCFA';

  /// À appeler au premier affichage pour charger les données.
  void ensureInitialized() {
    loadExpenses();
    loadExpenseStats();
    loadPendingExpenses();
    loadExpenseCategories();
  }

  void dispose() {
    scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
    notesController.dispose();
  }

  // Charger toutes les dépenses
  Future<void> loadExpenses({int page = 1, bool forceRefresh = false}) async {
    try {
      final cacheKey =
          'expenses_${selectedStatus}_${selectedCategory}';
      final statusParam =
          selectedStatus == 'all' ? null : selectedStatus;
      final categoryParam =
          selectedCategory == 'all' ? null : selectedCategory;

      if (page == 1) {
        if (!forceRefresh) {
          final hiveList = ExpenseService.getCachedDepenses(
            statusParam,
            categoryParam,
          );
          if (hiveList.isNotEmpty) {
            expenses.clear();
            expenses.addAll(hiveList);
            isLoading = false;
            Future.microtask(
              () => _refreshExpensesFromApi(cacheKey, statusParam, categoryParam),
            );
            return;
          }
          final cachedExpenses = CacheHelper.get<List<Expense>>(cacheKey);
          if (cachedExpenses != null && cachedExpenses.isNotEmpty) {
            expenses.clear();
            expenses.addAll(cachedExpenses);
            isLoading = false;
            Future.microtask(
              () => _refreshExpensesFromApi(cacheKey, statusParam, categoryParam),
            );
            return;
          }
        }
        expenses.clear();
        isLoading = true;
      } else if (page > 1) {
        isLoadingMore = true;
      }

      try {
        final paginatedResponse = await _expenseService.getExpensesPaginated(
          status: selectedStatus == 'all' ? null : selectedStatus,
          category:
              selectedCategory == 'all' ? null : selectedCategory,
          search: searchQuery.isNotEmpty ? searchQuery : null,
          page: page,
          perPage: perPage,
        );

        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = paginatedResponse.meta.currentPage;

        if (page == 1) {
          expenses.clear();
          expenses.addAll(paginatedResponse.data);
        } else {
          expenses.addAll(paginatedResponse.data);
        }

        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        final loadedExpenses = await _expenseService.getExpenses(
          status: selectedStatus == 'all' ? null : selectedStatus,
          category:
              selectedCategory == 'all' ? null : selectedCategory,
          search: searchQuery.isEmpty ? null : searchQuery,
        );
        if (loadedExpenses.isNotEmpty) {
          if (page == 1) {
            expenses.clear();
            expenses.addAll(loadedExpenses);
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

      if (expenses.isEmpty) {
        final cacheKey =
            'expenses_${selectedStatus == 'all' ? 'all' : selectedStatus}_${selectedCategory == 'all' ? 'all' : selectedCategory}';
        final cachedExpenses = CacheHelper.get<List<Expense>>(cacheKey);
        if (cachedExpenses == null || cachedExpenses.isEmpty) {
          final errorString = e.toString().toLowerCase();
          if (!errorString.contains('session expirée') &&
              !errorString.contains('401') &&
              !errorString.contains('unauthorized')) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les dépenses',
              duration: const Duration(seconds: 3),
            );
          }
        } else {
          expenses.clear();
          expenses.addAll(cachedExpenses);
        }
      } else {
        AppLogger.info(
          'Liste des dépenses conservée (${expenses.length} dépenses) malgré l\'erreur de rechargement',
          tag: 'EXPENSE_CONTROLLER',
        );
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
    }
  }

  Future<void> _refreshExpensesFromApi(
    String cacheKey,
    String? statusParam,
    String? categoryParam,
  ) async {
    try {
      final paginatedResponse = await _expenseService.getExpensesPaginated(
        status: statusParam,
        category: categoryParam,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        page: 1,
        perPage: perPage,
      );
      final sameFilter =
          (statusParam == null && selectedStatus == 'all') ||
          (statusParam != null && selectedStatus == statusParam);
      final sameCategory =
          (categoryParam == null && selectedCategory == 'all') ||
          (categoryParam != null && selectedCategory == categoryParam);
      if (sameFilter && sameCategory) {
        expenses.clear();
        expenses.addAll(paginatedResponse.data);
        totalPages = paginatedResponse.meta.lastPage;
        totalItems = paginatedResponse.meta.total;
        hasNextPage = paginatedResponse.hasNextPage;
        hasPreviousPage = paginatedResponse.hasPreviousPage;
        currentPage = 1;
        CacheHelper.set(cacheKey, paginatedResponse.data);
      }
    } catch (_) {}
    isLoading = false;
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadExpenses(page: currentPage + 1);
    }
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadExpenses(page: currentPage - 1);
    }
  }

  Future<void> loadPendingExpenses() async {
    try {
      final pending = await _expenseService.getPendingExpenses();
      pendingExpenses.clear();
      pendingExpenses.addAll(pending);
    } catch (e) {}
  }

  Future<void> loadExpenseCategories() async {
    try {
      final categories = await _expenseService.getExpenseCategories();
      expenseCategories.clear();
      expenseCategories.addAll(categories);
    } catch (e) {}
  }

  Future<void> loadExpenseStats() async {
    try {
      final stats = await _expenseService.getExpenseStats();
      expenseStats = stats;
    } catch (e) {}
  }

  // Créer une dépense
  Future<bool> createExpense() async {
    try {
      isLoading = true;

      int? categoryId;
      if (expenseCategories.isNotEmpty) {
        final category = _firstWhereExpenseCategory(
          expenseCategories,
          (cat) =>
              cat.name.toLowerCase() ==
                  selectedCategoryForm.toLowerCase() ||
              cat.id.toString() == selectedCategoryForm,
        );
        categoryId = category?.id;
      }

      if (categoryId == null) {
        categoryId =
            selectedCategoryId > 0 ? selectedCategoryId : null;
        if (categoryId == null) {
          categoryId = int.tryParse(selectedCategoryForm);
        }
      }

      final user = AuthController.to.userAuth;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (titleController.text.trim().isEmpty) {
        throw Exception('Le titre de la dépense est obligatoire');
      }

      final titleValue = titleController.text.trim();

      final expenseData = <String, dynamic>{
        'title': titleValue,
        'description': descriptionController.text.trim(),
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'currency': currency,
        'expense_date':
            (selectedExpenseDate ?? DateTime.now()).toIso8601String(),
        'user_id': user.id,
        'employee_id': user.id,
        'status': 'pending',
      };

      if (selectedCategoryId > 0) {
        expenseData['category'] = selectedCategoryId.toString();
      } else if (categoryId != null && categoryId > 0) {
        expenseData['category'] = categoryId.toString();
      } else {
        expenseData['category'] = selectedCategoryForm;
      }

      if (selectedReceiptPath != null &&
          selectedReceiptPath!.isNotEmpty) {
        expenseData['receipt_path'] = selectedReceiptPath;
      }

      if (notesController.text.trim().isNotEmpty) {
        expenseData['notes'] = notesController.text.trim();
        expenseData['justification'] = notesController.text.trim();
      }

      final createdExpense = await _expenseService.createExpense(expenseData);

      CacheHelper.clearByPrefix('expenses_');

      if (createdExpense.id != null) {
        expenses.add(createdExpense);

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

      errorHelperShowSnackbar?.call(
        'Succès',
        'Dépense créée avec succès',
        duration: const Duration(seconds: 2),
      );

      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter('expense');

        loadExpenses().catchError((e) {
          AppLogger.error(
            'Erreur lors du rechargement après création: $e',
            tag: 'EXPENSE_CONTROLLER',
          );
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
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer la dépense: ${e.toString()}',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  // Mettre à jour une dépense
  Future<bool> updateExpense(Expense expense) async {
    try {
      isLoading = true;

      int? categoryId;
      if (expenseCategories.isNotEmpty) {
        final category = _firstWhereExpenseCategory(
          expenseCategories,
          (cat) =>
              cat.name.toLowerCase() ==
                  selectedCategoryForm.toLowerCase() ||
              cat.id.toString() == selectedCategoryForm,
        );
        categoryId = category?.id;
      }

      if (categoryId == null) {
        categoryId =
            selectedCategoryId > 0 ? selectedCategoryId : null;
        if (categoryId == null) {
          categoryId = int.tryParse(selectedCategoryForm);
        }
      }

      final user = AuthController.to.userAuth;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      if (titleController.text.trim().isEmpty) {
        throw Exception('Le titre de la dépense est obligatoire');
      }

      final expenseData = <String, dynamic>{
        'title': titleController.text.trim(),
        'description': descriptionController.text.trim(),
        'amount': double.tryParse(amountController.text) ?? 0.0,
        'currency': currency,
        'expense_date':
            (selectedExpenseDate ?? expense.expenseDate)
                .toIso8601String(),
        'user_id': user.id,
        'employee_id': user.id,
        'status': expense.status,
      };

      if (selectedCategoryId > 0) {
        expenseData['category'] = selectedCategoryId.toString();
      } else if (categoryId != null && categoryId > 0) {
        expenseData['category'] = categoryId.toString();
      } else {
        expenseData['category'] = selectedCategoryForm;
      }

      if (selectedReceiptPath != null &&
          selectedReceiptPath!.isNotEmpty) {
        expenseData['receipt_path'] = selectedReceiptPath;
      } else if (expense.receiptPath != null) {
        expenseData['receipt_path'] = expense.receiptPath;
      }

      if (notesController.text.trim().isNotEmpty) {
        expenseData['notes'] = notesController.text.trim();
        expenseData['justification'] = notesController.text.trim();
      }

      await _expenseService.updateExpense(expense.id!, expenseData);
      await loadExpenses();
      await loadExpenseStats();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Dépense mise à jour avec succès',
        duration: const Duration(seconds: 2),
      );

      clearForm();
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return false;
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour la dépense: ${e.toString()}',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> submitExpense(Expense expense) async {
    try {
      isLoading = true;

      final success = await _expenseService.submitExpense(expense.id!);

      if (success) {
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Dépense soumise au patron',
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de soumettre la dépense: ${e.toString()}',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> approveExpense(Expense expense) async {
    try {
      isLoading = true;

      final success = await _expenseService.approveExpense(
        expense.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Dépense approuvée',
        );
      } else {
        throw Exception(
          'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
        );
      }
    } catch (e, stackTrace) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible d\'approuver la dépense: $e',
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectExpense(Expense expense, String reason) async {
    try {
      isLoading = true;

      final success = await _expenseService.rejectExpense(
        expense.id!,
        reason: reason,
      );

      if (success) {
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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Dépense rejetée',
        );
      } else {
        throw Exception(
          'Erreur lors du rejet - La réponse du serveur indique un échec',
        );
      }
    } catch (e, stackTrace) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de rejeter la dépense: $e',
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteExpense(Expense expense) async {
    try {
      isLoading = true;

      final success = await _expenseService.deleteExpense(expense.id!);
      if (success) {
        expenses.removeWhere((e) => e.id == expense.id);
        await loadExpenseStats();

        errorHelperShowSnackbar?.call(
          'Succès',
          'Dépense supprimée avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer la dépense',
      );
    } finally {
      isLoading = false;
    }
  }

  void fillForm(Expense expense) {
    titleController.text = expense.title;
    descriptionController.text = expense.description;
    amountController.text = expense.amount.toString();
    selectedCategoryForm = expense.category;
    selectedExpenseDate = expense.expenseDate;
    selectedReceiptPath = expense.receiptPath;
    notesController.text = expense.notes ?? '';
    selectedExpense = expense;
  }

  /// Nécessite [context] pour le dialog.
  Future<void> selectReceipt(BuildContext context) async {
    try {
      final cameraService = CameraService();

      final source = await showDialog<ImageSource>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sélectionner une source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choisir depuis la galerie'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
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
        await cameraService.validateImage(imageFile);

        selectedReceiptPath = imageFile.path;

        errorHelperShowSnackbar?.call(
          'Succès',
          'Justificatif sélectionné',
        );
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        e.toString(),
      );
    }
  }

  void clearForm() {
    titleController.clear();
    descriptionController.clear();
    amountController.clear();
    notesController.clear();
    selectedCategoryForm = 'office_supplies';
    selectedExpenseDate = null;
    selectedReceiptPath = null;
    selectedExpense = null;
    currency = 'FCFA';
  }

  void searchExpenses(String query) {
    searchQuery = query;
    loadExpenses();
  }

  void filterByStatus(String status) {
    selectedStatus = status;
    loadExpenses();
  }

  void filterByCategory(String category) {
    selectedCategory = category;
    loadExpenses();
  }

  Future<void> selectExpenseDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedExpenseDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedExpenseDate = picked;
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
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 3; // Admin, Comptable
  }

  bool get canApproveExpenses {
    final userRole = AuthController.to.userAuth?.role;
    return userRole == 1 || userRole == 4; // Admin, Patron
  }

  bool get canViewExpenses {
    final userRole = AuthController.to.userAuth?.role;
    return userRole != null; // Tous les rôles
  }

  // Obtenir les dépenses par statut
  List<Expense> get expensesByStatus {
    if (selectedStatus == 'all') return expenses;
    return expenses
        .where((expense) => expense.status == selectedStatus)
        .toList();
  }

  // Obtenir les dépenses par catégorie
  List<Expense> get expensesByCategory {
    if (selectedCategory == 'all') return expenses;
    return expenses
        .where((expense) => expense.category == selectedCategory)
        .toList();
  }

  // Obtenir les dépenses filtrées
  List<Expense> get filteredExpenses {
    List<Expense> filtered = expenses;

    if (selectedStatus != 'all') {
      filtered =
          filtered
              .where((expense) => expense.status == selectedStatus)
              .toList();
    }

    if (selectedCategory != 'all') {
      filtered =
          filtered
              .where((expense) => expense.category == selectedCategory)
              .toList();
    }

    if (searchQuery.isNotEmpty) {
      filtered =
          filtered
              .where(
                (expense) =>
                    expense.title.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ) ||
                    expense.description.toLowerCase().contains(
                      searchQuery.toLowerCase(),
                    ),
              )
              .toList();
    }

    return filtered;
  }
}
