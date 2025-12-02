/// EXEMPLE D'UTILISATION DE LA PAGINATION DANS UN SERVICE
///
/// Ce fichier montre comment adapter un service existant pour utiliser
/// la pagination côté serveur avec PaginationResponse.
///
/// IMPORTANT: Ce fichier est un EXEMPLE. Adaptez vos services existants
/// en suivant ce modèle.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/pagination_response.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/pagination_helper.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';

class ClientServiceExample {
  /// Récupérer les clients avec pagination côté serveur
  ///
  /// Le backend Laravel doit retourner une réponse paginée au format :
  /// {
  ///   "success": true,
  ///   "data": {
  ///     "data": [...],
  ///     "current_page": 1,
  ///     "last_page": 5,
  ///     "per_page": 15,
  ///     "total": 100,
  ///     "next_page_url": "...",
  ///     "prev_page_url": null,
  ///     ...
  ///   }
  /// }
  Future<PaginationResponse<Client>> getClientsPaginated({
    int? status,
    String? search,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      String url = '${AppConfig.baseUrl}/clients';
      List<String> params = [];

      // Ajouter les filtres
      if (status != null) {
        params.add('status=$status');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=$search');
      }

      // Ajouter la pagination
      params.add('page=$page');
      params.add('per_page=$perPage');

      // Construire l'URL
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      AppLogger.httpRequest('GET', url, tag: 'CLIENT_SERVICE');

      final response = await http.get(
        Uri.parse(url),
        headers: ApiService.headers(),
      );

      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Utiliser PaginationHelper pour parser la réponse
        return PaginationHelper.parseResponse<Client>(
          json: data,
          fromJsonT: (json) => Client.fromJson(json),
        );
      } else {
        throw Exception(
          'Erreur lors de la récupération des clients: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération paginée des clients: $e',
        tag: 'CLIENT_SERVICE',
        error: e,
      );
      rethrow;
    }
  }

  /// Méthode legacy pour compatibilité (charge toutes les pages)
  Future<List<Client>> getClients({int? status, String? search}) async {
    try {
      // Charger la première page
      final firstPage = await getClientsPaginated(
        status: status,
        search: search,
        page: 1,
        perPage: 15,
      );

      List<Client> allClients = List.from(firstPage.data);

      // Si il y a d'autres pages, les charger
      if (firstPage.hasNextPage) {
        for (int page = 2; page <= firstPage.meta.lastPage; page++) {
          final nextPage = await getClientsPaginated(
            status: status,
            search: search,
            page: page,
            perPage: 15,
          );
          allClients.addAll(nextPage.data);
        }
      }

      return allClients;
    } catch (e) {
      rethrow;
    }
  }
}

/// EXEMPLE D'UTILISATION DANS UN CONTRÔLEUR
/// 
/// class ClientController extends GetxController {
///   final ClientService _clientService = ClientService();
///   
///   // Métadonnées de pagination
///   final RxInt currentPage = 1.obs;
///   final RxInt totalPages = 1.obs;
///   final RxInt totalItems = 0.obs;
///   final RxBool hasNextPage = false.obs;
///   final RxBool hasPreviousPage = false.obs;
///   final RxInt perPage = 15.obs;
///   
///   final RxList<Client> clients = <Client>[].obs;
///   final RxBool isLoading = false.obs;
///   
///   Future<void> loadClients({int page = 1}) async {
///     try {
///       isLoading.value = true;
///       
///       final paginatedResponse = await _clientService.getClientsPaginated(
///         page: page,
///         perPage: perPage.value,
///       );
///       
///       // Mettre à jour les métadonnées
///       totalPages.value = paginatedResponse.meta.lastPage;
///       totalItems.value = paginatedResponse.meta.total;
///       hasNextPage.value = paginatedResponse.hasNextPage;
///       hasPreviousPage.value = paginatedResponse.hasPreviousPage;
///       currentPage.value = paginatedResponse.meta.currentPage;
///       
///       // Mettre à jour les données
///       if (page == 1) {
///         clients.value = paginatedResponse.data;
///       } else {
///         // Pour scroll infini, ajouter à la liste existante
///         clients.addAll(paginatedResponse.data);
///       }
///     } finally {
///       isLoading.value = false;
///     }
///   }
///   
///   Future<void> loadNextPage() async {
///     if (hasNextPage.value && !isLoading.value) {
///       await loadClients(page: currentPage.value + 1);
///     }
///   }
/// }

