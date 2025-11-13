import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/user_model.dart';
import 'package:easyconnect/utils/constant.dart';

class UserService {
  final storage = GetStorage();

  /// Récupérer tous les utilisateurs
  Future<List<UserModel>> getUsers() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/users-list'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => UserModel.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des utilisateurs: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des utilisateurs: $e');
    }
  }

  /// Récupérer un utilisateur par ID
  Future<UserModel> getUserById(int id) async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/users-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return UserModel.fromJson(data);
      }
      throw Exception(
        'Erreur lors de la récupération de l\'utilisateur: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération de l\'utilisateur: $e');
    }
  }

  /// Créer un nouvel utilisateur
  Future<UserModel> createUser(UserModel user, [String? password]) async {
    try {
      final token = storage.read('token');

      // Préparer les données à envoyer
      final userData = user.toJson();
      if (password != null) {
        userData['password'] = password;
      }
      // S'assurer que is_active est inclus
      userData['is_active'] = user.isActive;

      // Debug: afficher les données envoyées
      final response = await http.post(
        Uri.parse('$baseUrl/users-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(userData),
      );

      // Debug: afficher la réponse de l'API
      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return UserModel.fromJson(data);
      }
      throw Exception(
        'Erreur lors de la création de l\'utilisateur: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de l\'utilisateur: $e');
    }
  }

  /// Mettre à jour un utilisateur
  Future<UserModel> updateUser(UserModel user) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/users-update/${user.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(user.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return UserModel.fromJson(data);
      }
      throw Exception(
        'Erreur lors de la mise à jour de l\'utilisateur: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour de l\'utilisateur: $e');
    }
  }

  /// Supprimer un utilisateur
  Future<bool> deleteUser(int id) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/users-delete/$id'),
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

  /// Activer/Désactiver un utilisateur
  Future<bool> toggleUserStatus(int id, bool isActive) async {
    try {
      final token = storage.read('token');
      final response = await http.patch(
        Uri.parse('$baseUrl/users-status/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'is_active': isActive}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Récupérer les statistiques des utilisateurs
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/users-stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception(
        'Erreur lors de la récupération des statistiques: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }
}
