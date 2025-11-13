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

      var queryParams = <String, String>{};
      if (status != null) {
        // Statuts uniformisés : 1=En attente, 2=Validé, 3=Rejeté
        queryParams['status'] = status.toString();
      }
      // Ne pas envoyer user_id car le contrôleur Laravel le gère automatiquement

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final response = await http.get(
        Uri.parse('$baseUrl/devis-list$queryString'),

        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final url = '$baseUrl/devis-list$queryString';
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        List<dynamic> data;

        // Gérer différents formats de réponse
        if (responseData is List) {
          data = responseData;
        } else if (responseData['data'] != null) {
          if (responseData['data'] is List) {
            data = responseData['data'];
          } else {
            data = [responseData['data']];
          }
        } else {
          return [];
        }

        final List<Devis> devisList =
            data
                .map((json) {
                  try {
                    return Devis.fromJson(json);
                  } catch (e) {
                    return null;
                  }
                })
                .where((devis) => devis != null)
                .cast<Devis>()
                .toList();
        return devisList;
      }
      throw Exception(
        'Erreur lors de la récupération des devis: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des devis: $e');
    }
  }

  Future<Devis> createDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final devisData = devis.toJson();

      final response = await http.post(
        Uri.parse('$baseUrl/devis-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(devisData),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return Devis.fromJson(responseData['data']);
      }
      throw Exception('Erreur lors de la création du devis');
    } catch (e) {
      throw Exception('Erreur lors de la création du devis');
    }
  }

  Future<Devis> updateDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/devis-update/${devis.id}'),
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
      throw Exception('Erreur lors de la mise à jour du devis');
    }
  }

  Future<bool> deleteDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/devis-delete/$devisId'),
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
      return false;
    }
  }

  // Soumettre un devis au patron pour validation
  Future<bool> submitDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/devis-submit/$devisId'),
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

  Future<bool> acceptDevis(int devisId) async {
    try {
      final token = storage.read('token');

      final url = '$baseUrl/devis-validate/$devisId';
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      // Log spécial pour les erreurs 500
      if (response.statusCode == 500) {
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectDevis(int devisId, String commentaire) async {
    try {
      final token = storage.read('token');
      final url = '$baseUrl/devis-reject/$devisId';
      final body = json.encode({'commentaire': commentaire});
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );
      // Log spécial pour les erreurs 500
      if (response.statusCode == 500) {
      }

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
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
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
