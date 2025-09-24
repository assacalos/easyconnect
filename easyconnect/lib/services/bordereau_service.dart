import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/utils/constant.dart';

class BordereauService {
  final storage = GetStorage();

  Future<List<Bordereau>> getBordereaux({int? status}) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (userRole == 2) queryParams['commercial_id'] = userId.toString();

      final queryString = queryParams.isEmpty ? '' : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bordereaux$queryString';

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
        return data.map((json) => Bordereau.fromJson(json)).toList();
      }

      throw Exception('Erreur lors de la récupération des bordereaux: ${response.statusCode}');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la récupération des bordereaux: $e');
    }
  }

  Future<Bordereau> createBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bordereau.toJson()),
      );

      print('Création bordereau - Status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return Bordereau.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la création du bordereau');
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la création du bordereau');
    }
  }

  Future<Bordereau> updateBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bordereaux/${bordereau.id}'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bordereau.toJson()),
      );

      if (response.statusCode == 200) {
        return Bordereau.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du bordereau');
    } catch (e) {
      print('Erreur: $e');
      throw Exception('Erreur lors de la mise à jour du bordereau');
    }
  }

  Future<bool> deleteBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/bordereaux/$bordereauId'),
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

  Future<bool> submitBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux/$bordereauId/submit'),
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

  Future<bool> approveBordereau(int bordereauId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux/$bordereauId/approve'),
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

  Future<bool> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux/$bordereauId/reject'),
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

  Future<Map<String, dynamic>> getBordereauStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/bordereaux/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Stats bordereaux - Status: ${response.statusCode}');
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
