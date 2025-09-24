import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/utils/constant.dart';

class BonCommandeService {
  final storage = GetStorage();

  Future<List<BonCommande>> getBonCommandes({int? status}) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (userRole == 2) queryParams['commercial_id'] = userId.toString();

      final queryString = queryParams.isEmpty ? '' : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bon-commandes$queryString';

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
        return data.map((json) => BonCommande.fromJson(json)).toList();
      }

      throw Exception('Erreur lors de la récupération des bons de commande: ${response.statusCode}');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la récupération des bons de commande: $e');
    }
  }

  Future<BonCommande> createBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonCommande.toJson()),
      );

      print('Création bon de commande - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return BonCommande.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la création du bon de commande');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la création du bon de commande');
    }
  }

  Future<BonCommande> updateBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bon-commandes/${bonCommande.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonCommande.toJson()),
      );

      if (response.statusCode == 200) {
        return BonCommande.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    }
  }

  Future<bool> deleteBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId'),
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

  Future<bool> submitBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId/submit'),
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

  Future<bool> approveBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId/approve'),
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

  Future<bool> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId/reject'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commentaire': commentaire}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur: $e');
      return false;
    }
  }

  Future<bool> markAsDelivered(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId/deliver'),
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

  Future<bool> generateInvoice(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bon-commandes/$bonCommandeId/invoice'),
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

  Future<Map<String, dynamic>> getBonCommandeStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/bon-commandes/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Stats bon de commande - Status: ${response.statusCode}');
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
