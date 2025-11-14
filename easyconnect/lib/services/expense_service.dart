import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
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
        final responseBody = json.decode(response.body);
        // Gérer différents formats de réponse
        final List<dynamic> data = responseBody['data'] ?? responseBody;
        if (data.isEmpty) {
          return [];
        }
        return data.map((json) => Expense.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des dépenses: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
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
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la récupération de la dépense: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Créer une dépense
  Future<Expense> createExpense(Map<String, dynamic> expenseData) async {
    try {
      final token = storage.read('token');
      final jsonBody = json.encode(expenseData);

      final response = await http.post(
        Uri.parse('$baseUrl/expenses-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonBody,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la création de la dépense: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Mettre à jour une dépense
  Future<Expense> updateExpense(
    int id,
    Map<String, dynamic> expenseData,
  ) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/expenses-update/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(expenseData),
      );
      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return Expense.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la mise à jour de la dépense: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Supprimer une dépense
  Future<bool> deleteExpense(int expenseId) async {
    try {
      final token = storage.read('token');

      final response = await http.delete(
        Uri.parse('$baseUrl/expenses-destroy/$expenseId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Soumettre une dépense au patron
  Future<bool> submitExpense(int expenseId) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/expenses-submit/$expenseId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Approuver une dépense
  Future<bool> approveExpense(int expenseId, {String? notes}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/expenses-validate/$expenseId';

      print('🔵 [EXPENSE_SERVICE] Appel POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'notes': notes}),
      );

      print('🔵 [EXPENSE_SERVICE] Réponse status: ${response.statusCode}');
      print('🔵 [EXPENSE_SERVICE] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ??
            'Cette dépense ne peut pas être approuvée';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors de l\'approbation';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e, stackTrace) {
      print('❌ [EXPENSE_SERVICE] Exception approveExpense: $e');
      print('❌ [EXPENSE_SERVICE] Stack trace: $stackTrace');
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Rejeter une dépense
  Future<bool> rejectExpense(int expenseId, {required String reason}) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/expenses-reject/$expenseId';

      print('🔵 [EXPENSE_SERVICE] Appel POST $url');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'reason': reason}),
      );

      print('🔵 [EXPENSE_SERVICE] Réponse status: ${response.statusCode}');
      print('🔵 [EXPENSE_SERVICE] Réponse body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        // Vérifier si la réponse contient success == true
        if (responseData is Map && responseData['success'] == true) {
          return true;
        }
        // Si pas de champ success, considérer 200 comme succès
        return true;
      } else if (response.statusCode == 400) {
        // Erreur 400 : message explicite du backend
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Cette dépense ne peut pas être rejetée';
        throw Exception(message);
      } else if (response.statusCode == 500) {
        // Erreur 500 : problème serveur
        final responseData = json.decode(response.body);
        final message =
            responseData['message'] ?? 'Erreur serveur lors du rejet';
        throw Exception('Erreur serveur: $message');
      }
      return false;
    } catch (e, stackTrace) {
      print('❌ [EXPENSE_SERVICE] Exception rejectExpense: $e');
      print('❌ [EXPENSE_SERVICE] Stack trace: $stackTrace');
      rethrow; // Propager l'exception au lieu de retourner false
    }
  }

  // Récupérer les statistiques des dépenses
  Future<ExpenseStats> getExpenseStats() async {
    try {
      final token = storage.read('token');

      final response = await http.get(
        Uri.parse('$baseUrl/expenses-statistics'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return ExpenseStats.fromJson(responseBody['data'] ?? responseBody);
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Récupérer les dépenses en attente
  Future<List<Expense>> getPendingExpenses() async {
    try {
      return await getExpenses(status: 'pending');
    } catch (e) {
      rethrow;
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
        final responseBody = json.decode(response.body);
        final List<dynamic> data = responseBody['data'] ?? responseBody;
        if (data.isEmpty) {
          return [];
        }
        return data.map((json) => ExpenseCategory.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des catégories: ${response.statusCode}',
      );
    } catch (e) {
      rethrow;
    }
  }
}
