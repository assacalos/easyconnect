import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class BonCommandeService {
  final storage = GetStorage();

  /// Récupérer les bons de commande avec pagination côté serveur
  Future<PaginationResponse<BonCommande>> getBonCommandesPaginated({
    int? status,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      String url = '${AppConfig.baseUrl}/commandes-entreprise';
      List<String> params = [];

      if (status != null) {
        params.add('status=$status');
      }
      if (userRole == 2 && userId != null) {
        params.add('user_id=$userId');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }
      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'BON_COMMANDE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'BON_COMMANDE_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginationHelper.parseResponse<BonCommande>(
          json: data,
          fromJsonT: (json) => BonCommande.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des bons de commande: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getBonCommandesPaginated: $e',
        tag: 'BON_COMMANDE_SERVICE',
      );
      rethrow;
    }
  }

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
      final url = '${AppConfig.baseUrl}/commandes-entreprise-list$queryString';
      AppLogger.httpRequest('GET', url, tag: 'BON_COMMANDE_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'BON_COMMANDE_SERVICE',
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      // Utiliser ApiService.parseResponse pour gérer le format standardisé
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];

          // Gérer différents formats de réponse (pagination Laravel)
          List<dynamic> data;
          if (responseData is List) {
            // La réponse est directement une liste
            data = responseData;
          } else if (responseData is Map<String, dynamic>) {
            // Format de pagination Laravel: {"current_page": 1, "data": [...]}
            if (responseData.containsKey('data') &&
                responseData['data'] is List) {
              data = responseData['data'];
            } else if (responseData.containsKey('data') &&
                responseData['data'] is Map &&
                responseData['data']['data'] != null &&
                responseData['data']['data'] is List) {
              // Cas où data contient un objet avec une clé 'data' (pagination imbriquée)
              data = responseData['data']['data'];
            } else if (responseData.containsKey('data') &&
                responseData['data'] != null) {
              // Si data n'est pas une liste, essayer de la convertir
              data = [responseData['data']];
            } else {
              return [];
            }
          } else {
            return [];
          }

          final List<BonCommande> bonCommandeList =
              data
                  .map((json) {
                    try {
                      return BonCommande.fromJson(json);
                    } catch (e) {
                      AppLogger.warning(
                        'Erreur lors du parsing d\'un bon de commande: $e',
                        tag: 'BON_COMMANDE_SERVICE',
                      );
                      return null;
                    }
                  })
                  .where((bonCommande) => bonCommande != null)
                  .cast<BonCommande>()
                  .toList();

          return bonCommandeList;
        } catch (e) {
          AppLogger.error(
            'Erreur lors du parsing de la réponse: $e',
            tag: 'BON_COMMANDE_SERVICE',
            error: e,
          );
          print('❌ [BON_COMMANDE] Erreur parsing: $e');
          throw Exception('Erreur lors du parsing de la réponse: $e');
        }
      }

      // Si success == false, utiliser le message d'erreur
      throw Exception(
        result['message'] ??
            'Erreur lors de la récupération des bons de commande',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la récupération des bons de commande: $e',
        tag: 'BON_COMMANDE_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception(
        'Erreur lors de la récupération des bons de commande: $e',
      );
    }
  }

  Future<BonCommande> createBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/commandes-entreprise-create';
      AppLogger.httpRequest('POST', url, tag: 'BON_COMMANDE_SERVICE');

      // Utiliser toJsonForCreate() pour n'envoyer que les champs nécessaires
      final bonCommandeJson = bonCommande.toJsonForCreate();

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(bonCommandeJson),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'BON_COMMANDE_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body);

          // Gérer différents formats de réponse
          Map<String, dynamic> bonCommandeData;
          if (responseData is Map) {
            if (responseData['data'] != null) {
              bonCommandeData =
                  responseData['data'] is Map<String, dynamic>
                      ? responseData['data']
                      : Map<String, dynamic>.from(responseData['data']);
            } else {
              bonCommandeData =
                  responseData is Map<String, dynamic>
                      ? responseData
                      : Map<String, dynamic>.from(responseData);
            }
          } else {
            throw Exception(
              'Format de réponse inattendu: ${responseData.runtimeType}',
            );
          }

          return BonCommande.fromJson(bonCommandeData);
        } catch (parseError) {
          throw Exception('Erreur lors du parsing de la réponse: $parseError');
        }
      } else if (response.statusCode == 403) {
        // Gestion spécifique de l'erreur 403 (Accès refusé)
        try {
          final errorData = json.decode(response.body);
          final message = errorData['message'] ?? 'Accès refusé';
          throw Exception(message);
        } catch (e) {
          throw Exception(
            'Accès refusé (403). Vous n\'avez pas les permissions pour créer un bon de commande.',
          );
        }
      }

      // Si c'est une erreur 401, elle a déjà été gérée
      if (response.statusCode == 401) {
        throw Exception('Session expirée');
      } else if (response.statusCode == 422) {
        // Gestion spécifique de l'erreur 422 (Validation échouée)
        try {
          final errorData = json.decode(response.body);
          String errorMessage = 'Erreur de validation';

          // Laravel renvoie généralement les erreurs dans 'errors' ou 'message'
          if (errorData['errors'] != null) {
            // Format Laravel avec erreurs par champ
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
      } else {
        throw Exception(
          'Erreur lors de la création du bon de commande: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<BonCommande> updateBonCommande(BonCommande bonCommande) async {
    try {
      final token = storage.read('token');
      final response = await http.put(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-update/${bonCommande.id}',
        ),
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
      throw Exception('Erreur lors de la mise à jour du bon de commande');
    }
  }

  Future<bool> deleteBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.delete(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-destroy/$bonCommandeId',
        ),
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

  Future<bool> submitBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-submit/$bonCommandeId',
        ),
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

  Future<bool> approveBonCommande(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-validate/$bonCommandeId',
        ),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Si le status code est 200 ou 201, considérer comme succès
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      // Vérifier le body même si le status code n'est pas 200/201
      try {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return true;
        }
      } catch (e) {
        // Ignorer l'erreur de parsing
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-reject/$bonCommandeId',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'commentaire': commentaire}),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> markAsDelivered(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-mark-delivered/$bonCommandeId',
        ),
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

  Future<bool> generateInvoice(int bonCommandeId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse(
          '${AppConfig.baseUrl}/commandes-entreprise-mark-invoiced/$bonCommandeId',
        ),
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

  Future<Map<String, dynamic>> getBonCommandeStats() async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/bon-commandes/stats'),
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
