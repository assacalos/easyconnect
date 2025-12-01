import 'dart:convert';
import 'package:easyconnect/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:get_storage/get_storage.dart';
import '../models/client_model.dart';

class ClientApi {
  static Future<List<Client>> fetchClients({int? status}) async {
    final token = GetStorage().read("token");
    final response = await http.get(
      Uri.parse(
        "$baseUrl/clients-list${status != null ? '?status=$status' : ''}",
      ),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body)["clients"];
      return data.map((e) => Client.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors du chargement des clients");
    }
  }

  static Future<void> addClient(Map<String, dynamic> data) async {
    final token = GetStorage().read("token");
    await http.post(
      Uri.parse("$baseUrl/clients-create"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
  }

  static Future<void> updateClient(int id, Map<String, dynamic> data) async {
    final token = GetStorage().read("token");
    await http.put(
      Uri.parse("$baseUrl/clients-update/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(data),
    );
  }

  static Future<void> deleteClient(int id) async {
    final token = GetStorage().read("token");
    await http.delete(
      Uri.parse("$baseUrl/clients-delete/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> approveClient(int id) async {
    final token = GetStorage().read("token");
    await http.post(
      Uri.parse("$baseUrl/clients-validate/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
  }

  static Future<void> rejectClient(int id, String commentaire) async {
    final token = GetStorage().read("token");
    await http.post(
      Uri.parse("$baseUrl/clients-reject/$id"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"commentaire": commentaire}),
    );
  }
}
