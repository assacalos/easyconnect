import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/utils/constant.dart';

class ClientService {
  final storage = GetStorage();

  Future<List<Client>> getClients({
    int? status,
    bool? isPending = false,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (isPending == true) queryParams['pending'] = 'true';
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/clients-list$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Client.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des clients: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  Future<Client> createClient(Client client) async {
    try {
      final token = storage.read('token');
      final userId = storage.read('userId');

      var clientData = client.toJson();
      clientData['user_id'] = userId;
      clientData['status'] = 0; // Toujours en attente à la création

      print('➡️ Données envoyées: $clientData');
      print('➡️ User ID: $userId');

      final response = await http.post(
        Uri.parse('$baseUrl/clients-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(clientData),
      );
      print(
        '➡️ Réponse API createClient: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 201) {
        return Client.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la création du client');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la création du client');
    }
  }

  Future<Client> updateClient(Client client) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/clients-update/${client.id}'),
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
      print('🔍 ClientService.approveClient - Début');
      print(
        '📊 Paramètres: clientId=$clientId, token=${token?.substring(0, 10)}...',
      );

      final url = '$baseUrl/clients-validate/$clientId';
      print('🌐 URL de requête: $url');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('📡 Réponse reçue: ${response.statusCode}');
      print('📄 Contenu de la réponse: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ ClientService.approveClient - Succès');
        return true;
      } else {
        print('❌ ClientService.approveClient - Échec: ${response.statusCode}');
        print('📄 Détails de l\'erreur: ${response.body}');
        print('🔍 ClientService.approveClient - Analyse de l\'erreur:');
        print('   - Code de statut: ${response.statusCode}');
        print('   - URL appelée: $url');
        print('   - Token présent: ${token != null}');
        print('   - Client ID: $clientId');
        return false;
      }
    } catch (e) {
      print('❌ ClientService.approveClient - Erreur: $e');
      return false;
    }
  }

  Future<bool> rejectClient(int clientId, String comment) async {
    try {
      final token = storage.read('token');
      print('🔍 ClientService.rejectClient - Début');
      print('📊 Paramètres: clientId=$clientId, comment=$comment');

      final url = '$baseUrl/clients-reject/$clientId';
      print('🌐 URL de requête: $url');

      final body = json.encode({'commentaire': comment});
      print('📦 Corps de la requête: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      print('📡 Réponse reçue: ${response.statusCode}');
      print('📄 Contenu de la réponse: ${response.body}');

      // Log spécial pour les erreurs 500
      if (response.statusCode == 500) {
        print('🚨 ERREUR 500 - Erreur serveur Laravel');
        print('📄 Détails complets de l\'erreur:');
        print('   ${response.body}');
        print('🔍 Vérifiez les logs Laravel: storage/logs/laravel.log');
      }

      if (response.statusCode == 200) {
        print('✅ ClientService.rejectClient - Succès');
        return true;
      } else {
        print('❌ ClientService.rejectClient - Échec: ${response.statusCode}');
        print('📄 Détails de l\'erreur: ${response.body}');
        print('🔍 ClientService.rejectClient - Analyse de l\'erreur:');
        print('   - Code de statut: ${response.statusCode}');
        print('   - URL appelée: $url');
        print('   - Token présent: ${token != null}');
        print('   - Commentaire envoyé: $comment');
        return false;
      }
    } catch (e) {
      print('❌ ClientService.rejectClient - Erreur: $e');
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/clients-delete/$clientId'),
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

      if (response.statusCode == 200) {
        return json.decode(response.body)['data'];
      }
      throw Exception('Erreur lors de la récupération des statistiques');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
