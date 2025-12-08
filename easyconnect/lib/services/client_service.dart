import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/pagination_helper.dart';

class ClientService {
  /// Récupérer les clients avec pagination côté serveur
  Future<PaginationResponse<Client>> getClientsPaginated({
    int? status,
    bool? isPending = false,
    int page = 1,
    int perPage = 15,
    String? search,
  }) async {
    try {
      final userRole = SessionService.getUserRole();
      final userId = SessionService.getUserId();

      String url = '${AppConfig.baseUrl}/clients';
      List<String> params = [];

      if (status != null) {
        params.add('status=$status');
      }
      if (isPending == true) {
        params.add('pending=true');
      }
      if (userRole == 2) {
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

      AppLogger.httpRequest('GET', url, tag: 'CLIENT_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'CLIENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return PaginationHelper.parseResponse<Client>(
          json: data,
          fromJsonT: (json) => Client.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération paginée des clients: ${response.statusCode}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur dans getClientsPaginated: $e',
        tag: 'CLIENT_SERVICE',
      );
      rethrow;
    }
  }

  Future<List<Client>> getClients({
    int? status,
    bool? isPending = false,
    bool forceRefresh = false,
  }) async {
    try {
      // OPTIMISATION : Vérifier le cache d'abord (sauf si forceRefresh)
      if (!forceRefresh) {
        final cacheKey = 'clients_${status ?? 'all'}_${isPending ?? false}';
        final cached = CacheHelper.get<List<Client>>(cacheKey);
        if (cached != null && cached.isNotEmpty) {
          AppLogger.debug(
            'Using cached clients: ${cached.length} clients',
            tag: 'CLIENT_SERVICE',
          );
          // Retourner le cache immédiatement, puis charger en arrière-plan
          _refreshClientsInBackground(status, isPending, cacheKey);
          return cached;
        }
      }

      // Pas de cache ou forceRefresh, charger depuis le serveur
      List<Client> allClients;

      // Si status est null, on veut TOUS les statuts
      // OPTIMISATION : Charger les 3 statuts en parallèle au lieu de séquentiellement
      if (status == null) {
        final results = await Future.wait([
          _fetchClientsByStatus(0, isPending),
          _fetchClientsByStatus(1, isPending),
          _fetchClientsByStatus(2, isPending),
        ], eagerError: false); // Continuer même si une requête échoue

        allClients = results.expand((list) => list).toList();
      } else {
        // Si un statut spécifique est demandé, faire un seul appel
        allClients = await _fetchClientsByStatus(status, isPending);
      }

      // Mettre en cache pour 5 minutes
      final cacheKey = 'clients_${status ?? 'all'}_${isPending ?? false}';
      CacheHelper.set(
        cacheKey,
        allClients,
        duration: AppConfig.defaultCacheDuration,
      );

      return allClients;
    } catch (e) {
      // Si erreur, on laisse l'erreur se propager
      // Le contrôleur gérera l'affichage du cache s'il est disponible
      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  // Charger les données en arrière-plan pour mettre à jour le cache
  void _refreshClientsInBackground(
    int? status,
    bool? isPending,
    String cacheKey,
  ) {
    // Ne pas attendre, charger en arrière-plan
    Future.microtask(() async {
      try {
        List<Client> allClients;
        if (status == null) {
          final results = await Future.wait([
            _fetchClientsByStatus(0, isPending),
            _fetchClientsByStatus(1, isPending),
            _fetchClientsByStatus(2, isPending),
          ], eagerError: false);
          allClients = results.expand((list) => list).toList();
        } else {
          allClients = await _fetchClientsByStatus(status, isPending);
        }

        // Mettre à jour le cache avec les nouvelles données
        CacheHelper.set(
          cacheKey,
          allClients,
          duration: AppConfig.defaultCacheDuration,
        );
        AppLogger.debug(
          'Cache mis à jour en arrière-plan: ${allClients.length} clients',
          tag: 'CLIENT_SERVICE',
        );
      } catch (e) {
        // Ignorer les erreurs en arrière-plan, on a déjà le cache
        AppLogger.debug(
          'Erreur lors de la mise à jour en arrière-plan (ignorée): $e',
          tag: 'CLIENT_SERVICE',
        );
      }
    });
  }

  Future<List<Client>> _fetchClientsByStatus(
    int status,
    bool? isPending,
  ) async {
    try {
      final userRole = SessionService.getUserRole();
      final userId = SessionService.getUserId();

      var queryParams = <String, String>{};
      queryParams['status'] = status.toString();
      if (isPending == true) queryParams['pending'] = 'true';
      if (userRole == 2) queryParams['user_id'] = userId.toString();

      final queryString =
          queryParams.isEmpty
              ? ''
              : '?${Uri(queryParameters: queryParams).query}';

      final url = '${AppConfig.baseUrl}/clients-list$queryString';
      AppLogger.httpRequest('GET', url, tag: 'CLIENT_SERVICE');

      // Vérifier que le token existe
      if (!SessionService.isAuthenticated()) {
        AppLogger.warning(
          'Token d\'authentification manquant',
          tag: 'CLIENT_SERVICE',
        );
        throw Exception(
          'Token d\'authentification manquant. Veuillez vous reconnecter.',
        );
      }

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'CLIENT_SERVICE');

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        try {
          final responseData = result['data'];
          List<dynamic> data = [];

          // Gérer différents formats de réponse de l'API
          if (responseData is List) {
            data = responseData;
          } else if (responseData is Map) {
            if (responseData['data'] != null) {
              if (responseData['data'] is List) {
                data = responseData['data'];
              } else if (responseData['data'] is Map &&
                  responseData['data']['data'] != null) {
                if (responseData['data']['data'] is List) {
                  data = responseData['data']['data'];
                }
              }
            } else if (responseData['clients'] != null) {
              if (responseData['clients'] is List) {
                data = responseData['clients'];
              }
            }
          }

          // Filtrer par statut (double vérification côté client)
          if (data.isNotEmpty) {
            data =
                data.where((item) {
                  if (item is Map) {
                    final itemStatus = item['status'];
                    int? parsedStatus;
                    if (itemStatus is String) {
                      parsedStatus = int.tryParse(itemStatus);
                    } else if (itemStatus is int) {
                      parsedStatus = itemStatus;
                    }
                    return parsedStatus == status;
                  }
                  return true;
                }).toList();
          }

          final clients = data.map((json) => Client.fromJson(json)).toList();
          return clients;
        } catch (e) {
          throw Exception('Erreur de parsing JSON: $e');
        }
      } else if (result['statusCode'] == 403) {
        throw Exception(
          'Accès refusé (403). Vous n\'avez pas les permissions pour accéder aux clients. Vérifiez vos droits d\'accès.',
        );
      }

      // Si c'est une erreur 401, elle a déjà été gérée
      if (response.statusCode == 401) {
        throw Exception('Session expirée');
      }

      throw Exception(
        'Erreur lors de la récupération des clients: ${response.statusCode} - ${response.body}',
      );
    } catch (e, stackTrace) {
      // Gérer les erreurs d'authentification dans les exceptions
      final isAuthError = await AuthErrorHandler.handleError(e);
      if (isAuthError) {
        throw Exception('Session expirée');
      }

      AppLogger.error(
        'Erreur lors de la récupération des clients: $e',
        tag: 'CLIENT_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );

      throw Exception('Erreur lors de la récupération des clients: $e');
    }
  }

  Future<Client> createClient(Client client) async {
    try {
      final userId = SessionService.getUserId();
      final url = '${AppConfig.baseUrl}/clients-create';

      AppLogger.httpRequest('POST', url, tag: 'CLIENT_SERVICE');

      var clientData = client.toJson();
      clientData['user_id'] = userId;
      clientData['status'] = 0; // Toujours en attente à la création

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.post(
              Uri.parse(url),
              headers: ApiService.headers(),
              body: json.encode(clientData),
            ),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(response.statusCode, url, tag: 'CLIENT_SERVICE');
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        final responseData = result['data'];
        if (responseData != null) {
          AppLogger.info('Client créé avec succès', tag: 'CLIENT_SERVICE');
          return Client.fromJson(responseData);
        }
        // Si pas de data mais success true, le client a été créé
        // On retourne le client original
        return client;
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la création du client',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du client: $e',
        tag: 'CLIENT_SERVICE',
        error: e,
        stackTrace: stackTrace,
      );
      // Si c'est déjà une Exception avec un message, la relancer
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Erreur lors de la création du client: $e');
    }
  }

  Future<Client> updateClient(Client client) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/clients-update/${client.id}'),
        headers: ApiService.headers(),
        body: json.encode(client.toJson()),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return Client.fromJson(result['data']);
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la mise à jour du client',
      );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du client');
    }
  }

  Future<bool> approveClient(int clientId) async {
    try {
      final url = '${AppConfig.baseUrl}/clients-validate/$clientId';
      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      // Si le status code est 200 ou 201, considérer comme succès même si le body dit false
      // (le backend peut retourner success:false mais avoir validé quand même)
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Invalider le cache après validation
        CacheHelper.clearByPrefix('clients_');
        return true;
      }

      // Gérer les erreurs d'authentification seulement si ce n'est pas un succès
      await AuthErrorHandler.handleHttpResponse(response);

      // Utiliser ApiService.parseResponse pour gérer le format standardisé
      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        // Invalider le cache après validation
        CacheHelper.clearByPrefix('clients_');
        return true;
      }

      return false;
    } catch (e) {
      // Si le status code était 200/201, considérer comme succès malgré l'exception
      return false;
    }
  }

  Future<bool> rejectClient(int clientId, String comment) async {
    try {
      final url = '${AppConfig.baseUrl}/clients-reject/$clientId';
      final body = json.encode({'commentaire': comment});
      final response = await http.post(
        Uri.parse(url),
        headers: ApiService.headers(),
        body: body,
      );

      // Gérer les erreurs d'authentification
      await AuthErrorHandler.handleHttpResponse(response);

      final result = ApiService.parseResponse(response);
      if (result['success'] == true) {
        // Invalider le cache après rejet
        CacheHelper.clearByPrefix('clients_');
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteClient(int clientId) async {
    try {
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/clients-delete/$clientId'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);
      return result['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getClientStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/clients/stats'),
        headers: ApiService.headers(),
      );

      final result = ApiService.parseResponse(response);

      if (result['success'] == true) {
        return result['data'] ?? {};
      }

      throw Exception(
        result['message'] ?? 'Erreur lors de la récupération des statistiques',
      );
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques');
    }
  }
}
