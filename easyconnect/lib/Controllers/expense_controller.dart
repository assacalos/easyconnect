import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

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

  // Contrôleurs de formulaire
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final RxString selectedCategoryForm = 'office_supplies'.obs;
  final Rx<DateTime?> selectedExpenseDate = Rx<DateTime?>(null);
  final Rx<String?> selectedReceiptPath = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    loadExpenses();
    loadExpenseStats();
    loadPendingExpenses();
    loadExpenseCategories();
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
  Future<void> loadExpenses() async {
    try {
      isLoading.value = true;
      final loadedExpenses = await _expenseService.getExpenses(
        status: selectedStatus.value == 'all' ? null : selectedStatus.value,
        category:
            selectedCategory.value == 'all' ? null : selectedCategory.value,
        search: searchQuery.value.isEmpty ? null : searchQuery.value,
      );
      expenses.assignAll(loadedExpenses);
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les dépenses',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Charger les dépenses en attente
  Future<void> loadPendingExpenses() async {
    try {
      final pending = await _expenseService.getPendingExpenses();
      pendingExpenses.assignAll(pending);
    } catch (e) {
      print('Erreur lors du chargement des dépenses en attente: $e');
    }
  }

  // Charger les catégories
  Future<void> loadExpenseCategories() async {
    try {
      final categories = await _expenseService.getExpenseCategories();
      expenseCategories.assignAll(categories);
    } catch (e) {
      print('Erreur lors du chargement des catégories: $e');
    }
  }

  // Charger les statistiques
  Future<void> loadExpenseStats() async {
    try {
      final stats = await _expenseService.getExpenseStats();
      expenseStats.value = stats;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
    }
  }

  // Créer une dépense
  Future<void> createExpense() async {
    try {
      isLoading.value = true;

      final expense = Expense(
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        amount: double.tryParse(amountController.text) ?? 0.0,
        category: selectedCategoryForm.value,
        expenseDate: selectedExpenseDate.value ?? DateTime.now(),
        receiptPath: selectedReceiptPath.value,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _expenseService.createExpense(expense);
      await loadExpenses();
      await loadExpenseStats();

      Get.snackbar(
        'Succès',
        'Dépense créée avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer la dépense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Mettre à jour une dépense
  Future<void> updateExpense(Expense expense) async {
    try {
      isLoading.value = true;

      final updatedExpense = Expense(
        id: expense.id,
        title: titleController.text.trim(),
        description: descriptionController.text.trim(),
        amount: double.tryParse(amountController.text) ?? 0.0,
        category: selectedCategoryForm.value,
        status: expense.status,
        expenseDate: selectedExpenseDate.value ?? expense.expenseDate,
        receiptPath: selectedReceiptPath.value ?? expense.receiptPath,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
        createdAt: expense.createdAt,
        updatedAt: DateTime.now(),
        createdBy: expense.createdBy,
        approvedBy: expense.approvedBy,
        rejectionReason: expense.rejectionReason,
        approvedAt: expense.approvedAt,
      );

      await _expenseService.updateExpense(updatedExpense);
      await loadExpenses();
      await loadExpenseStats();

      Get.snackbar(
        'Succès',
        'Dépense mise à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      clearForm();
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour la dépense',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Approuver une dépense
  Future<void> approveExpense(Expense expense) async {
    try {
      isLoading.value = true;

      final success = await _expenseService.approveExpense(
        expense.id!,
        notes:
            notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim(),
      );

      if (success) {
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

        Get.snackbar(
          'Succès',
          'Dépense approuvée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver la dépense',
        snackPosition: SnackPosition.BOTTOM,
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
        await loadExpenses();
        await loadExpenseStats();
        await loadPendingExpenses();

        Get.snackbar(
          'Succès',
          'Dépense rejetée',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du rejet');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter la dépense',
        snackPosition: SnackPosition.BOTTOM,
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
