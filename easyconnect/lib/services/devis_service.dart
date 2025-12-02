import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/services/api_service.dart';

class DevisService {
  final storage = GetStorage();

  /// Récupérer les devis avec pagination côté serveur
  Future<PaginationResponse<Devis>> getDevisPaginated({
    int? status,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      String url = '${AppConfig.baseUrl}/devis';
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

      AppLogger.httpRequest('GET', url, tag: 'DEVIS_SERVICE');
      AppLogger.info(
        'Paramètres: status=$status, userRole=$userRole, userId=$userId, page=$page, perPage=$perPage',
        tag: 'DEVIS_SERVICE',
      );

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

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Logger le corps de la réponse pour debug
      AppLogger.debug(
        'Réponse brute (premiers 500 caractères): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}',
        tag: 'DEVIS_SERVICE',
      );

      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.debug(
          'Données décodées: ${jsonEncode(data)}',
          tag: 'DEVIS_SERVICE',
        );

        final paginatedResponse = PaginationHelper.parseResponse<Devis>(
          json: data,
          fromJsonT: (json) {
            try {
              return Devis.fromJson(json);
            } catch (e, stackTrace) {
              AppLogger.error(
                'Erreur parsing devis JSON: $e',
                tag: 'DEVIS_SERVICE',
                error: e,
                stackTrace: stackTrace,
              );
              rethrow;
            }
          },
        );
        AppLogger.info(
          'Devis paginés récupérés: ${paginatedResponse.data.length} devis sur ${paginatedResponse.meta.total} total (page ${paginatedResponse.meta.currentPage}/${paginatedResponse.meta.lastPage})',
          tag: 'DEVIS_SERVICE',
        );

        if (paginatedResponse.data.isEmpty) {
          AppLogger.warning(
            'Aucun devis retourné malgré un statut 200. Vérifier les filtres et les données en base.',
            tag: 'DEVIS_SERVICE',
          );
        }

        return paginatedResponse;
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
          tag: 'DEVIS_SERVICE',
        );
        throw Exception(
          'Erreur lors de la récupération paginée des devis: ${response.statusCode}',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur dans getDevisPaginated: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<List<Devis>> getDevis({int? status, bool forceRefresh = false}) async {
    try {
      // OPTIMISATION : Vérifier le cache d'abord (sauf si on force le rafraîchissement)
      final cacheKey = 'devis_${status ?? 'all'}';
      if (!forceRefresh) {
        final cached = CacheHelper.get<List<Devis>>(cacheKey);
        if (cached != null) {
          AppLogger.debug(
            'Using cached devis: ${cached.length} devis',
            tag: 'DEVIS_SERVICE',
          );
          return cached;
        }
      }

      final token = storage.read('token');

      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      var queryParams = <String, String>{};
      if (status != null) {
        // Statuts uniformisés : 1=En attente, 2=Validé, 3=Rejeté
        queryParams['status'] = status.toString();
      }
      // Filtrer par userId pour les commerciaux (role 2)
      if (userRole == 2 && userId != null) {
        queryParams['user_id'] = userId.toString();
      }

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '${AppConfig.baseUrl}/devis-list$queryString';
      AppLogger.httpRequest('GET', url, tag: 'DEVIS_SERVICE');

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

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Logger le corps de la réponse pour debug
      AppLogger.debug(
        'Réponse brute /devis-list (premiers 500 caractères): ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}',
        tag: 'DEVIS_SERVICE',
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      // Utiliser ApiService.parseResponse pour gérer le format standardisé
      final result = ApiService.parseResponse(response);

      AppLogger.debug(
        'Résultat parseResponse: success=${result['success']}, hasData=${result['data'] != null}',
        tag: 'DEVIS_SERVICE',
      );

      if (result['success'] == true) {
        try {
          final responseData = result['data'];

          List<dynamic> data;

          // Gérer différents formats de réponse
          if (responseData is List) {
            data = responseData;
          } else if (responseData != null && responseData is Map) {
            // Si c'est un objet avec un champ 'data', l'extraire
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else {
                data = [responseData['data']];
              }
            } else {
              // Si c'est un objet direct, le convertir en liste
              data = [responseData];
            }
          } else {
            AppLogger.warning(
              'Format de réponse inattendu pour /devis-list: $responseData',
              tag: 'DEVIS_SERVICE',
            );
            return [];
          }

          final List<Devis> devisList =
              data
                  .map((json) {
                    try {
                      return Devis.fromJson(json);
                    } catch (e, stackTrace) {
                      AppLogger.error(
                        'Erreur lors du parsing d\'un devis: $e',
                        tag: 'DEVIS_SERVICE',
                        error: e,
                        stackTrace: stackTrace,
                      );
                      return null;
                    }
                  })
                  .where((devis) => devis != null)
                  .cast<Devis>()
                  .toList();

          // Mettre en cache pour 5 minutes
          CacheHelper.set(
            cacheKey,
            devisList,
            duration: AppConfig.defaultCacheDuration,
          );

          AppLogger.info(
            'Devis chargés via /devis-list: ${devisList.length} devis',
            tag: 'DEVIS_SERVICE',
          );

          return devisList;
        } catch (e) {
          AppLogger.error(
            'Erreur lors du parsing de la réponse: $e',
            tag: 'DEVIS_SERVICE',
            error: e,
          );
          throw Exception('Erreur lors du parsing de la réponse: $e');
        }
      }

      // Si success == false, utiliser le message d'erreur
      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des devis',
      );
    } catch (e) {
      // Gérer les erreurs d'authentification dans les exceptions
      await AuthErrorHandler.handleException(e);

      // Si c'est une erreur d'authentification, ne pas la propager
      if (AuthErrorHandler.shouldIgnoreError(e)) {
        throw Exception('Session expirée');
      }

      throw Exception('Erreur lors de la récupération des devis: $e');
    }
  }

  Future<Devis> createDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final devisData = devis.toJson();
      final url = '${AppConfig.baseUrl}/devis-create';

      AppLogger.httpRequest('POST', url, tag: 'DEVIS_SERVICE');
      AppLogger.debug('Token présent: ${token != null}', tag: 'DEVIS_SERVICE');
      AppLogger.debug(
        'Données: ${json.encode(devisData)}',
        tag: 'DEVIS_SERVICE',
      );

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(devisData),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 201) {
        try {
          final responseData = json.decode(response.body);
          AppLogger.info('Réponse décodée avec succès', tag: 'DEVIS_SERVICE');

          if (responseData['data'] != null) {
            final createdDevis = Devis.fromJson(responseData['data']);
            AppLogger.info(
              'Devis créé avec ID: ${createdDevis.id}',
              tag: 'DEVIS_SERVICE',
            );
            return createdDevis;
          } else {
            AppLogger.error(
              'Pas de champ "data" dans la réponse',
              tag: 'DEVIS_SERVICE',
            );
            throw Exception('Réponse invalide: pas de champ "data"');
          }
        } catch (e) {
          AppLogger.error(
            'Erreur lors du décodage: $e',
            tag: 'DEVIS_SERVICE',
            error: e,
          );
          throw Exception('Erreur lors du décodage de la réponse: $e');
        }
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode}: ${response.body}',
          tag: 'DEVIS_SERVICE',
        );
        throw Exception('Erreur HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la création du devis: $e');
    }
  }

  Future<Devis> updateDevis(Devis devis) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis-update/${devis.id}';
      AppLogger.httpRequest('PUT', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.put(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: json.encode(devis.toJson()),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        return Devis.fromJson(json.decode(response.body)['data']);
      }
      throw Exception('Erreur lors de la mise à jour du devis');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la mise à jour du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      throw Exception('Erreur lors de la mise à jour du devis: $e');
    }
  }

  Future<bool> deleteDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis-delete/$devisId';
      AppLogger.httpRequest('DELETE', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.delete(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la suppression du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<bool> sendDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis/$devisId/send';
      AppLogger.httpRequest('POST', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'envoi du devis: $e',
        tag: 'DEVIS_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  // Soumettre un devis au patron pour validation
  Future<bool> submitDevis(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/devis-submit/$devisId'),
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
      final url = '${AppConfig.baseUrl}/devis-validate/$devisId';

      AppLogger.httpRequest('POST', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Authorization': 'Bearer $token',
              },
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la validation du devis: $e',
        tag: 'DEVIS_SERVICE',
      );
      return false;
    }
  }

  Future<bool> rejectDevis(int devisId, String commentaire) async {
    try {
      final token = storage.read('token');
      final url = '${AppConfig.baseUrl}/devis-reject/$devisId';
      final body = json.encode({'commentaire': commentaire});

      AppLogger.httpRequest('POST', url, tag: 'DEVIS_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
              body: body,
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'DEVIS_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du rejet du devis: $e',
        tag: 'DEVIS_SERVICE',
      );
      return false;
    }
  }

  Future<String> generatePDF(int devisId) async {
    try {
      final token = storage.read('token');
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/devis/$devisId/pdf'),
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
        Uri.parse('${AppConfig.baseUrl}/devis/stats'),
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

  /// Endpoint de debug pour diagnostiquer les problèmes de chargement
  Future<Map<String, dynamic>> getDevisDebug() async {
    try {
      final token = storage.read('token');
      final userRole = storage.read('userRole');
      final userId = storage.read('userId');

      final url = '${AppConfig.baseUrl}/devis-debug';
      AppLogger.httpRequest('GET', url, tag: 'DEVIS_SERVICE_DEBUG');
      AppLogger.info(
        'Debug - User ID: $userId, Role: $userRole',
        tag: 'DEVIS_SERVICE_DEBUG',
      );

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
        tag: 'DEVIS_SERVICE_DEBUG',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        AppLogger.info(
          'Debug response: ${jsonEncode(data)}',
          tag: 'DEVIS_SERVICE_DEBUG',
        );
        return data;
      } else {
        AppLogger.error(
          'Erreur HTTP ${response.statusCode} dans debug: ${response.body}',
          tag: 'DEVIS_SERVICE_DEBUG',
        );
        throw Exception(
          'Erreur lors de la récupération des informations de debug: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getDevisDebug: $e',
        tag: 'DEVIS_SERVICE_DEBUG',
      );
      rethrow;
    }
  }
}
