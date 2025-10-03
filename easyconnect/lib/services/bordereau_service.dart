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
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bordereaux-list$queryString';

      print('➡️ URL de requête bordereaux: $url');
      print('➡️ Token: ${token != null ? "Présent" : "Absent"}');
      print('➡️ User ID: $userId');
      print('➡️ User Role: $userRole');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('➡️ Status code: ${response.statusCode}');
      print('➡️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('➡️ Données reçues: $responseData');

        // Gérer le cas où les données sont directement dans un tableau
        List<dynamic> data;
        if (responseData is List) {
          data = responseData;
        } else if (responseData['data'] != null) {
          data = responseData['data'];
        } else {
          print('➡️ Aucune donnée dans la réponse');
          return [];
        }

        print('➡️ Nombre de bordereaux: ${data.length}');

        if (data.isNotEmpty) {
          print('➡️ Premier bordereau: ${data[0]}');
        }

        final List<Bordereau> bordereauList =
            data
                .map((json) {
                  print('➡️ Parsing bordereau: $json');
                  try {
                    return Bordereau.fromJson(json);
                  } catch (e) {
                    print('➡️ Erreur parsing bordereau: $e');
                    print('➡️ JSON problématique: $json');
                    return null;
                  }
                })
                .where((bordereau) => bordereau != null)
                .cast<Bordereau>()
                .toList();

        print('➡️ Bordereaux parsés: ${bordereauList.length}');
        return bordereauList;
      }

      throw Exception(
        'Erreur lors de la récupération des bordereaux: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la récupération des bordereaux: $e');
    }
  }

  Future<Bordereau> createBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/bordereaux-create'),
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
        final responseData = json.decode(response.body);
        // La réponse contient directement les données du bordereau
        return Bordereau.fromJson(responseData);
      } else if (response.statusCode == 200) {
        // Gérer le cas où l'API retourne 200 au lieu de 201
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return Bordereau.fromJson(responseData['data']);
        } else {
          return Bordereau.fromJson(responseData);
        }
      }
      throw Exception(
        'Erreur lors de la création du bordereau: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la création du bordereau');
    }
  }

  Future<Bordereau> updateBordereau(Bordereau bordereau) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bordereaux-update/${bordereau.id}'),
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
        Uri.parse('$baseUrl/bordereaux-delete/$bordereauId'),
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
      final url = '$baseUrl/bordereaux-validate/$bordereauId';

      print('🔍 BordereauService.approveBordereau - Début');
      print('📊 Paramètres: bordereauId=$bordereauId');
      print('➡️ URL: $url');
      print('➡️ Token: ${token != null ? "Présent" : "Absent"}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('➡️ Status code: ${response.statusCode}');
      print('➡️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Bordereau approuvé avec succès');
          return true;
        } else {
          print('❌ Échec de l\'approbation: ${responseData['message']}');
          return false;
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur détaillée: $e');
      return false;
    }
  }

  Future<bool> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/bordereaux-reject/$bordereauId';
      final body = {'commentaire': commentaire};

      print('🔍 BordereauService.rejectBordereau - Début');
      print(
        '📊 Paramètres: bordereauId=$bordereauId, commentaire=$commentaire',
      );
      print('➡️ URL: $url');
      print('➡️ Token: ${token != null ? "Présent" : "Absent"}');
      print('➡️ Body: $body');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('➡️ Status code: ${response.statusCode}');
      print('➡️ Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          print('✅ Bordereau rejeté avec succès');
          return true;
        } else {
          print('❌ Échec du rejet: ${responseData['message']}');
          return false;
        }
      } else {
        print('❌ Erreur HTTP ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Erreur détaillée: $e');
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
