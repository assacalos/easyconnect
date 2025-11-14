import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/utils/constant.dart';

class BonDeCommandeFournisseurService {
  final storage = GetStorage();

  Future<List<BonDeCommande>> getBonDeCommandes({
    int? status,
    int? clientId,
    int? fournisseurId,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status.toString();
      if (clientId != null) queryParams['client_id'] = clientId.toString();
      if (fournisseurId != null)
        queryParams['fournisseur_id'] = fournisseurId.toString();
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';
      final url = '$baseUrl/bons-de-commande-list$queryString';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          print(
            '📥 Réponse getBonDeCommandes: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );

          // Gérer différents formats de réponse
          List<dynamic> data;
          if (responseData is List) {
            data = responseData;
          } else if (responseData['data'] != null) {
            if (responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData['data']['data'] != null) {
              data = responseData['data']['data'];
            } else {
              data = [responseData['data']];
            }
          } else if (responseData['bon_de_commandes'] != null) {
            if (responseData['bon_de_commandes'] is List) {
              data = responseData['bon_de_commandes'];
            } else {
              data = [responseData['bon_de_commandes']];
            }
          } else if (responseData['bon_de_commande'] != null) {
            data = [responseData['bon_de_commande']];
          } else {
            print('⚠️ Aucune donnée trouvée dans la réponse');
            return [];
          }

          print('📊 ${data.length} bons de commande trouvés');

          final List<BonDeCommande> bonDeCommandeList =
              data
                  .map((json) {
                    try {
                      return BonDeCommande.fromJson(json);
                    } catch (e, stackTrace) {
                      print(
                        '❌ Erreur lors du parsing d\'un bon de commande: $e',
                      );
                      print('📋 JSON: $json');
                      print('Stack trace: $stackTrace');
                      return null;
                    }
                  })
                  .where((bonDeCommande) => bonDeCommande != null)
                  .cast<BonDeCommande>()
                  .toList();

          print(
            '✅ ${bonDeCommandeList.length} bons de commande parsés avec succès',
          );
          return bonDeCommandeList;
        } catch (e, stackTrace) {
          print('❌ Erreur lors du parsing de la réponse: $e');
          print('Stack trace: $stackTrace');
          return [];
        }
      }

      throw Exception(
        'Erreur lors de la récupération des bons de commande: ${response.statusCode}',
      );
    } catch (e) {
      throw Exception(
        'Erreur lors de la récupération des bons de commande: $e',
      );
    }
  }

  Future<BonDeCommande> createBonDeCommande(BonDeCommande bonDeCommande) async {
    try {
      final token = storage.read('token');

      final bonDeCommandeJson = bonDeCommande.toJsonForCreate();

      // Log pour déboguer
      print('📤 JSON envoyé au backend:');
      print(json.encode(bonDeCommandeJson));

      final response = await http.post(
        Uri.parse('$baseUrl/bons-de-commande-create'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonDeCommandeJson),
      );

      // Log de la réponse
      print('📥 Réponse du backend (${response.statusCode}):');
      print(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Gérer différents formats de réponse
          Map<String, dynamic> bonDeCommandeData;
          if (responseData is Map) {
            if (responseData['bon_de_commande'] != null) {
              bonDeCommandeData =
                  responseData['bon_de_commande'] is Map<String, dynamic>
                      ? responseData['bon_de_commande']
                      : Map<String, dynamic>.from(
                        responseData['bon_de_commande'],
                      );
            } else if (responseData['data'] != null) {
              bonDeCommandeData =
                  responseData['data'] is Map<String, dynamic>
                      ? responseData['data']
                      : Map<String, dynamic>.from(responseData['data']);
            } else {
              bonDeCommandeData =
                  responseData is Map<String, dynamic>
                      ? responseData
                      : Map<String, dynamic>.from(responseData);
            }
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }

          return BonDeCommande.fromJson(bonDeCommandeData);
        } catch (parseError) {
          throw Exception('Erreur lors du parsing de la réponse: $parseError');
        }
      } else if (response.statusCode == 403) {
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Accès refusé';
          throw Exception(message);
        } catch (e) {
          throw Exception(
            'Accès refusé (403). Vous n\'avez pas les permissions pour créer un bon de commande.',
          );
        }
      } else if (response.statusCode == 401) {
        throw Exception(
          'Non autorisé (401). Votre session a peut-être expiré. Veuillez vous reconnecter.',
        );
      } else if (response.statusCode == 422) {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur de validation';

          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final errorMessages = <String>[];

            errors.forEach((field, messages) {
              if (messages is List) {
                errorMessages.addAll(messages.map((m) => '$field: $m'));
              } else {
                errorMessages.add('$field: $messages');
              }
            });

            errorMessage = errorMessages.join('\n');
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          }

          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('Erreur de validation')) {
            rethrow;
          }
          throw Exception(
            'Erreur de validation (422). Veuillez vérifier les données saisies.',
          );
        }
      } else if (response.statusCode == 500) {
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur serveur (500)';

          if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['errors'] != null) {
            if (errorData['errors'] is Map) {
              final errors = errorData['errors'] as Map<String, dynamic>;
              errorMessage = errors.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
            } else {
              errorMessage = errorData['errors'].toString();
            }
          }

          print('❌ Erreur 500 détaillée: $errorMessage');
          print('📋 Corps de la réponse: ${response.body}');

          throw Exception('Erreur serveur: $errorMessage');
        } catch (e) {
          if (e is Exception && e.toString().contains('Erreur serveur')) {
            rethrow;
          }
          throw Exception('Erreur serveur (500). Détails: ${response.body}');
        }
      } else {
        throw Exception(
          'Erreur lors de la création du bon de commande: ${response.statusCode}\nRéponse: ${response.body}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<BonDeCommande> updateBonDeCommande(
    int id,
    BonDeCommande bonDeCommande,
  ) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse('$baseUrl/bons-de-commande-update/$id'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(bonDeCommande.toJsonForCreate()),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Map<String, dynamic> bonDeCommandeData;

        if (responseData['bon_de_commande'] != null) {
          bonDeCommandeData =
              responseData['bon_de_commande'] is Map<String, dynamic>
                  ? responseData['bon_de_commande']
                  : Map<String, dynamic>.from(responseData['bon_de_commande']);
        } else if (responseData['data'] != null) {
          bonDeCommandeData =
              responseData['data'] is Map<String, dynamic>
                  ? responseData['data']
                  : Map<String, dynamic>.from(responseData['data']);
        } else {
          bonDeCommandeData =
              responseData is Map<String, dynamic>
                  ? responseData
                  : Map<String, dynamic>.from(responseData);
        }

        return BonDeCommande.fromJson(bonDeCommandeData);
      }
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    }
  }

  Future<bool> deleteBonDeCommande(int bonDeCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/bons-de-commande-destroy/$bonDeCommandeId'),
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

  Future<BonDeCommande> getBonDeCommande(int id) async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('$baseUrl/bons-de-commande-show/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        Map<String, dynamic> bonDeCommandeData;

        if (responseData['bon_de_commande'] != null) {
          bonDeCommandeData =
              responseData['bon_de_commande'] is Map<String, dynamic>
                  ? responseData['bon_de_commande']
                  : Map<String, dynamic>.from(responseData['bon_de_commande']);
        } else if (responseData['data'] != null) {
          bonDeCommandeData =
              responseData['data'] is Map<String, dynamic>
                  ? responseData['data']
                  : Map<String, dynamic>.from(responseData['data']);
        } else {
          bonDeCommandeData =
              responseData is Map<String, dynamic>
                  ? responseData
                  : Map<String, dynamic>.from(responseData);
        }

        return BonDeCommande.fromJson(bonDeCommandeData);
      }
      throw Exception('Erreur lors de la récupération du bon de commande');
    } catch (e) {
      throw Exception('Erreur lors de la récupération du bon de commande: $e');
    }
  }

  // Valider/Approuver un bon de commande
  Future<bool> validateBonDeCommande(int bonDeCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bons-de-commande-validate/$bonDeCommandeId'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Rejeter un bon de commande
  Future<bool> rejectBonDeCommande(
    int bonDeCommandeId,
    String commentaire,
  ) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('$baseUrl/bons-de-commande-reject/$bonDeCommandeId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commentaire': commentaire}),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['success'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
