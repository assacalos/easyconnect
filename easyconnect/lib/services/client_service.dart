import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/utils/constant.dart';

class ClientService {
  final storage = GetStorage();

  Future<List<Client>> getClients({int? status}) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      print('Récupération des clients - Role: $userRole, UserId: $userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/clients$queryString';

      print('URL de requête: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Client.fromJson(json)).toList();
      }

      throw Exception(
        'Erreur lors de la récupération des clients: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  Future<Client> createClient(Client client) async {
    try {
      final token = storage.read('token');

      var clientData = client.toJson();
      clientData['status'] = 0; // Toujours en attente à la création

      final response = await http.post(
        Uri.parse('$baseUrl/clients'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(clientData),
      );

      print('Création client - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return Client.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la création du client');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la création du client');
    }
  }

  Future<Client> updateClient(Client client) async {
    try {
      final token = storage.read('token');

      final response = await http.put(
        Uri.parse('$baseUrl/clients/${client.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(client.toJson()),
      );

      if (response.statusCode == 200) {
        return Client.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du client');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise à jour du client');
    }
  }

  Future<bool> approveClient(int clientId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/clients/$clientId/approve'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  Future<bool> rejectClient(int clientId, String comment) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/clients/$clientId/reject'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commentaire': comment}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/clients/$clientId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/clients/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Stats clients - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
