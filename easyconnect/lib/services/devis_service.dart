import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';

class DevisService {
  final storage = GetStorage();

  Future<List<Devis>> getDevis({int? status}) async {
    try {
      // OPTIMISATION : Vérifier le cache d'abord
      final cacheKey = 'devis_${status ?? 'all'}';
      final cached = CacheHelper.get<List<Devis>>(cacheKey);
      if (cached != null) {
        AppLogger.debug('Using cached devis', tag: 'DEVIS_SERVICE');
        return cached;
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

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

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

        // Mettre en cache pour 5 minutes
        CacheHelper.set(
          cacheKey,
          devisList,
          duration: AppConfig.defaultCacheDuration,
        );

        return devisList;
      }

      // Si c'est une erreur 401, elle a déjà été gérée
      if (response.statusCode == 401) {
        throw Exception('Session expirée');
      }

      throw Exception(
        'Erreur lors de la récupération des devis: ${response.statusCode}',
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
}
