import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/utils/constant.dart';

class DevisService {
  final storage = GetStorage();

  Future<List<Devis>> getDevis({int? status}) async {
    try {
      final token = storage.read('token');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/devis$queryString'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Devis.fromJson(json)).toList();
      }
      throw Exception(
        'Erreur lors de la récupération des devis: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la récupération des devis: $e');
    }
  }

  Future<Devis> createDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/devis'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(devis.toJson()),
      );

      if (response.statusCode == 201) {
        return Devis.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la création du devis');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la création du devis');
    }
  }

  Future<Devis> updateDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/devis/${devis.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(devis.toJson()),
      );

      if (response.statusCode == 200) {
        return Devis.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du devis');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise à jour du devis');
    }
  }

  Future<bool> deleteDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/devis/$devisId'),
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

  Future<bool> sendDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/devis/$devisId/send'),
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

  Future<bool> acceptDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/devis/$devisId/accept'),
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

  Future<bool> rejectDevis(int devisId, String commentaire) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/devis/$devisId/reject'),
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

  Future<String> generatePDF(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/devis/$devisId/pdf'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)['url'];
      }
      throw Exception('Erreur lors de la génération du PDF');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la génération du PDF');
    }
  }

  Future<Map<String, dynamic>> getDevisStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/devis/stats'),
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
