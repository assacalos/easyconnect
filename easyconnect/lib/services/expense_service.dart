import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/expense_model.dart';
import 'package:easyconnect/utils/constant.dart';

class ExpenseService {
  final storage = GetStorage();

  // Récupérer toutes les dépenses
  Future<List<Expense>> getExpenses({
    String? status,
    String? category,
    String? search,
  }) async {
    try {
      final token = storage.read('token');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      if (category != null) queryParams['category'] = category;
      if (search != null) queryParams['search'] = search;

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/expenses-list$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        if (data.isEmpty) {
          print('⚠️ API a retourné 0 dépenses, utilisation de données mockées');
          return getMockExpenses();
        }
        return data.map((json) => Expense.fromJson(json)).toList();
      }
      print(
        '⚠️ Erreur API (${response.statusCode}), utilisation de données mockées',
      );
      return getMockExpenses();
    } catch (e) {
      print('Erreur ExpenseService.getExpenses: $e');
      print('⚠️ Utilisation de données mockées après erreur');
      return getMockExpenses();
    }
  }

  // Récupérer une dépense par ID
  Future<Expense> getExpenseById(int id) async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/expenses-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération de la dépense: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.getExpenseById: $e');
      throw Exception('Erreur lors de la récupération de la dépense: $e');
    }
  }

  // Créer une dépense
  Future<Expense> createExpense(Expense expense) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/expenses-store'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 201) {
        return Expense.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de la dépense: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.createExpense: $e');
      throw Exception('Erreur lors de la création de la dépense: $e');
    }
  }

  // Mettre à jour une dépense
  Future<Expense> updateExpense(Expense expense) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/expenses-update/${expense.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expense.toJson()),
      );

      if (response.statusCode == 200) {
        return Expense.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de la dépense: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.updateExpense: $e');
      throw Exception('Erreur lors de la mise à jour de la dépense: $e');
    }
  }

  // Approuver une dépense
  Future<bool> approveExpense(int expenseId, {String? notes}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/expenses-validate/$expenseId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur ExpenseService.approveExpense: $e');
      return false;
    }
  }

  // Rejeter une dépense
  Future<bool> rejectExpense(int expenseId, {required String reason}) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/expenses-reject/$expenseId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur ExpenseService.rejectExpense: $e');
      return false;
    }
  }

  // Supprimer une dépense
  Future<bool> deleteExpense(int expenseId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/expenses-delete/$expenseId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur ExpenseService.deleteExpense: $e');
      return false;
    }
  }

  // Récupérer les statistiques des dépenses
  Future<ExpenseStats> getExpenseStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/expenses-reports'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return ExpenseStats.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.getExpenseStats: $e');
      print('⚠️ Utilisation de données mockées après erreur');
      return getMockExpenseStats();
    }
  }

  // Récupérer les dépenses en attente
  Future<List<Expense>> getPendingExpenses() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/expenses-list?status=pending'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        if (data.isEmpty) {
          print(
            '⚠️ API a retourné 0 dépenses en attente, utilisation de données mockées',
          );
          return getMockExpenses().where((e) => e.status == 'pending').toList();
        }
        return data.map((json) => Expense.fromJson(json)).toList();
      }
      print(
        '⚠️ Erreur API (${response.statusCode}), utilisation de données mockées',
      );
      return getMockExpenses().where((e) => e.status == 'pending').toList();
    } catch (e) {
      print('Erreur ExpenseService.getPendingExpenses: $e');
      print('⚠️ Utilisation de données mockées après erreur');
      return getMockExpenses().where((e) => e.status == 'pending').toList();
    }
  }

  // Récupérer les catégories de dépenses
  Future<List<ExpenseCategory>> getExpenseCategories() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/expense-categories'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        if (data.isEmpty) {
          print(
            '⚠️ API a retourné 0 catégories, utilisation de données mockées',
          );
          return getMockExpenseCategories();
        }
        return data.map((json) => ExpenseCategory.fromJson(json)).toList();
      }
      print(
        '⚠️ Erreur API (${response.statusCode}), utilisation de données mockées',
      );
      return getMockExpenseCategories();
    } catch (e) {
      print('Erreur ExpenseService.getExpenseCategories: $e');
      print('⚠️ Utilisation de données mockées après erreur');
      return getMockExpenseCategories();
    }
  }

  // Créer une catégorie de dépense
  Future<ExpenseCategory> createExpenseCategory(
    ExpenseCategory category,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/expense-categories'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 201) {
        return ExpenseCategory.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la création de la catégorie: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.createExpenseCategory: $e');
      throw Exception('Erreur lors de la création de la catégorie: $e');
    }
  }

  // Mettre à jour une catégorie de dépense
  Future<ExpenseCategory> updateExpenseCategory(
    ExpenseCategory category,
  ) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/expense-categories/${category.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(category.toJson()),
      );

      if (response.statusCode == 200) {
        return ExpenseCategory.fromJson(json.decode(response.body)['data']);
      }
      throw Exception(
        'Erreur lors de la mise à jour de la catégorie: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur ExpenseService.updateExpenseCategory: $e');
      throw Exception('Erreur lors de la mise à jour de la catégorie: $e');
    }
  }

  // Supprimer une catégorie de dépense
  Future<bool> deleteExpenseCategory(int categoryId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/expense-categories/$categoryId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur ExpenseService.deleteExpenseCategory: $e');
      return false;
    }
  }

  // Méthode pour générer des données mockées
  List<Expense> getMockExpenses() {
    print('🎭 getMockExpenses - Génération des données mockées');
    return [
      Expense(
        id: 1,
        title: 'Fournitures de bureau',
        description: 'Achat de stylos, cahiers et autres fournitures',
        amount: 150.0,
        category: 'office_supplies',
        status: 'approved',
        expenseDate: DateTime.now().subtract(const Duration(days: 5)),
        receiptPath: null,
        notes: 'Fournitures pour le bureau',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
        approvedBy: 3,
        approvedAt:
            DateTime.now().subtract(const Duration(days: 4)).toIso8601String(),
      ),
      Expense(
        id: 2,
        title: 'Repas d\'affaires',
        description: 'Déjeuner avec un client important',
        amount: 85.0,
        category: 'meals',
        status: 'pending',
        expenseDate: DateTime.now().subtract(const Duration(days: 2)),
        receiptPath: null,
        notes: 'Repas avec client pour négociation',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        approvedBy: null,
        approvedAt: null,
      ),
      Expense(
        id: 3,
        title: 'Transport',
        description: 'Taxi pour rendez-vous client',
        amount: 25.0,
        category: 'transport',
        status: 'rejected',
        expenseDate: DateTime.now().subtract(const Duration(days: 7)),
        receiptPath: null,
        notes: 'Transport rejeté - pas de justificatif',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 6)),
        approvedBy: 3,
        approvedAt:
            DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
      ),
      Expense(
        id: 4,
        title: 'Équipement informatique',
        description: 'Achat d\'un nouveau clavier et souris',
        amount: 120.0,
        category: 'equipment',
        status: 'pending',
        expenseDate: DateTime.now().subtract(const Duration(days: 1)),
        receiptPath: null,
        notes: 'Équipement pour améliorer le confort de travail',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        approvedBy: null,
        approvedAt: null,
      ),
    ];
  }

  // Méthode pour générer des catégories mockées
  List<ExpenseCategory> getMockExpenseCategories() {
    print('🎭 getMockExpenseCategories - Génération des catégories mockées');
    return [
      ExpenseCategory(
        id: 1,
        name: 'Fournitures de bureau',
        description: 'Stylos, papiers, etc.',
        color: Colors.blue.value.toRadixString(16),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ExpenseCategory(
        id: 2,
        name: 'Repas',
        description: 'Repas d\'affaires et déjeuners',
        color: Colors.green.value.toRadixString(16),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ExpenseCategory(
        id: 3,
        name: 'Transport',
        description: 'Taxi, bus, train',
        color: Colors.orange.value.toRadixString(16),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ExpenseCategory(
        id: 4,
        name: 'Équipement',
        description: 'Matériel informatique et bureau',
        color: Colors.purple.value.toRadixString(16),
        isActive: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
    ];
  }

  // Méthode pour générer des statistiques mockées
  ExpenseStats getMockExpenseStats() {
    print('🎭 getMockExpenseStats - Génération des statistiques mockées');
    return ExpenseStats(
      totalAmount: 380.0,
      pendingAmount: 205.0,
      approvedAmount: 150.0,
      rejectedAmount: 25.0,
      totalExpenses: 4,
      pendingExpenses: 2,
      approvedExpenses: 1,
      rejectedExpenses: 1,
      amountByCategory: {
        'office_supplies': 150.0,
        'meals': 85.0,
        'transport': 25.0,
        'equipment': 120.0,
      },
      countByCategory: {
        'office_supplies': 1,
        'meals': 1,
        'transport': 1,
        'equipment': 1,
      },
    );
  }
}
