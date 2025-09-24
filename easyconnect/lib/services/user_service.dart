import 'dart:convert';
import 'package:easyconnect/Models/user_model.dart';
import 'package:http/http.dart' as http;
import '../utils/constant.dart';

class UserService {
  Future<List<UserModel>> getUsers() async {
    final response = await http.get(Uri.parse("$baseUrl/users"));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => UserModel.fromJson(json)).toList();
    } else {
      throw Exception("Erreur lors du chargement des utilisateurs");
    }
  }

  Future<UserModel> createUser(UserModel user, String password) async {
    final response = await http.post(
      Uri.parse("$baseUrl/users"),
      headers: {"Content-Type": "application/json"},
      body: json.encode({...user.toJson(), "password": password}),
    );
    if (response.statusCode == 201) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Erreur lors de la création de l'utilisateur");
    }
  }

  Future<UserModel> updateUser(UserModel user) async {
    final response = await http.put(
      Uri.parse("$baseUrl/users/${user.id}"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(user.toJson()),
    );
    if (response.statusCode == 200) {
      return UserModel.fromJson(json.decode(response.body));
    } else {
      throw Exception("Erreur lors de la mise à jour");
    }
  }

  Future<void> deleteUser(String id) async {
    final response = await http.delete(Uri.parse("$baseUrl/users/$id"));
    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression");
    }
  }
}
