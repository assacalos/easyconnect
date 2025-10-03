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
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bons-de-commande-list$queryString';

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
        try {
          final responseData = json.decode(response.body);
          print('➡️ Données reçues: $responseData');

          // Gérer différents formats de réponse
          List<dynamic> data;
          if (responseData is List) {
            // La réponse est directement une liste
            data = responseData;
            print('➡️ Réponse directe (liste): ${data.length} éléments');
          } else if (responseData['data'] != null) {
            // La réponse contient une clé 'data'
            if (responseData['data'] is List) {
              data = responseData['data'];
              print(
                '➡️ Données dans responseData.data: ${data.length} éléments',
              );
            } else if (responseData['data']['data'] != null) {
              // Cas où data contient un objet avec une clé 'data' (pagination)
              data = responseData['data']['data'];
              print(
                '➡️ Données dans responseData.data.data: ${data.length} éléments',
              );
            } else {
              // Si data n'est pas une liste, essayer de la convertir
              print(
                '➡️ responseData.data n\'est pas une liste: ${responseData['data']}',
              );
              data = [responseData['data']];
            }
          } else {
            print('➡️ Aucune donnée trouvée dans la réponse');
            return [];
          }

          print('➡️ Nombre de bons de commande: ${data.length}');

          if (data.isNotEmpty) {
            print('➡️ Premier bon de commande: ${data[0]}');
          }

          final List<BonCommande> bonCommandeList =
              data
                  .map((json) {
                    print('➡️ Parsing bon de commande: $json');
                    try {
                      return BonCommande.fromJson(json);
                    } catch (e) {
                      print('➡️ Erreur parsing bon de commande: $e');
                      print('➡️ JSON problématique: $json');
                      return null;
                    }
                  })
                  .where((bonCommande) => bonCommande != null)
                  .cast<BonCommande>()
                  .toList();

          print('➡️ Bons de commande parsés: ${bonCommandeList.length}');
          return bonCommandeList;
        } catch (e) {
          print('❌ BonCommandeService: Erreur de parsing JSON: $e');
          print('📄 BonCommandeService: Body content: ${response.body}');

          // Essayer de nettoyer les caractères invalides
          try {
            String cleanedBody =
                response.body
                    .replaceAll(
                      RegExp(r'[\x00-\x1F\x7F-\x9F]'),
                      '',
                    ) // Supprimer les caractères de contrôle
                    .replaceAll(
                      RegExp(r'\\[^"\\/bfnrt]'),
                      '',
                    ) // Supprimer les échappements invalides
                    .replaceAll(
                      RegExp(r'[^\x20-\x7E]'),
                      '',
                    ) // Supprimer tous les caractères non-ASCII
                    .trim();

            print(
              '🔧 BonCommandeService: Tentative de nettoyage des caractères invalides',
            );

            if (cleanedBody.isEmpty) {
              print('❌ BonCommandeService: JSON vide après nettoyage');
              return [];
            }

            final responseData = jsonDecode(cleanedBody);
            print('✅ BonCommandeService: JSON nettoyé avec succès');

            // Continuer avec le parsing normal
            List<dynamic> data = [];
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data']['data'] != null) {
                data = responseData['data']['data'];
              }
            }

            if (data.isEmpty) {
              print(
                '⚠️ BonCommandeService: Aucune donnée trouvée après nettoyage',
              );
              return [];
            }

            return data.map((json) => BonCommande.fromJson(json)).toList();
          } catch (cleanError) {
            print('❌ BonCommandeService: Échec du nettoyage JSON: $cleanError');
            return [];
          }
        }
      }

      throw Exception(
        'Erreur lors de la récupération des bons de commande: ${response.statusCode}',
      );
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception(
        'Erreur lors de la récupération des bons de commande: $e',
      );
    }
  }

  Future<BonCommande> createBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');

      final response = await http.post(
        Uri.parse('$baseUrl/bons-de-commande-create'),
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
        final responseData = json.decode(response.body);
        // La réponse contient directement les données du bon de commande
        return BonCommande.fromJson(responseData);
      } else if (response.statusCode == 200) {
        // Gérer le cas où l'API retourne 200 au lieu de 201
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return BonCommande.fromJson(responseData['data']);
        } else {
          return BonCommande.fromJson(responseData);
        }
      }
      throw Exception(
        'Erreur lors de la création du bon de commande: ${response.statusCode} - ${response.body}',
      );
    } catch (e) {
      print('Erreur détaillée: $e');
      throw Exception('Erreur lors de la création du bon de commande');
    }
  }

  Future<BonCommande> updateBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bons-de-commande-update/${bonCommande.id}'),
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
        Uri.parse('$baseUrl/bons-de-commande-delete/$bonCommandeId'),
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
        Uri.parse('$baseUrl/bons-de-commande-submit/$bonCommandeId'),
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
        Uri.parse('$baseUrl/bons-de-commande-validate/$bonCommandeId'),
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
        Uri.parse('$baseUrl/bons-de-commande-reject/$bonCommandeId'),
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
