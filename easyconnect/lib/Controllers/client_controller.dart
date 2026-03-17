import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

Client? _firstWhereClientById(List<Client> list, int id) {
  try {
    return list.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
}

class ClientController {
  static final ClientController _instance = ClientController._();
  static ClientController get to => _instance;
  factory ClientController() => _instance;
  ClientController._();

  final ClientService _clientService = ClientService();
  final List<Client> clients = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  int? _currentStatus;
  bool _isLoadingInProgress = false;
  bool _isRefreshingFromApi = false;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';
  final ScrollController scrollController = ScrollController();

  Timer? _searchDebounceTimer;

  /// À appeler quand la recherche change (ex. depuis le champ de recherche) pour déclencher le debounce.
  void setSearchQuery(String query) {
    if (searchQuery == query) return;
    searchQuery = query;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!_isLoadingInProgress) {
        AppLogger.debug(
          'Recherche (debounce): rechargement statut=$_currentStatus, query="$searchQuery"',
          tag: 'CLIENT_CONTROLLER',
        );
        loadClients(status: _currentStatus, forceRefresh: true);
      }
    });
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
    scrollController.dispose();
  }

  Future<void> loadClients({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) {
      AppLogger.debug(
        'Chargement déjà en cours, ignore cet appel',
        tag: 'CLIENT_CONTROLLER',
      );
      return;
    }

    if (!forceRefresh &&
        clients.isNotEmpty &&
        _currentStatus == status &&
        currentPage == page &&
        page == 1) {
      AppLogger.debug(
        'Données déjà chargées, pas de rechargement nécessaire',
        tag: 'CLIENT_CONTROLLER',
      );
      return;
    }

    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'clients_${status ?? 'all'}';

    if (page == 1) {
      isLoading = true;
      final cachedData = ClientService.getCachedClients(status);
      if (cachedData.isNotEmpty) {
        clients.clear();
        clients.addAll(cachedData);
        isLoading = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} client(s) → affichage instantané',
          tag: 'CLIENT_CONTROLLER',
        );
      } else {
        clients.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final response = await _clientService.getClientsPaginated(
        status: status,
        page: page,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug(
          '[API] onglet changé (current=$_currentStatus, response=$status), mise à jour ignorée',
          tag: 'CLIENT_CONTROLLER',
        );
        return;
      }

      if (page == 1) {
        clients.clear();
        clients.addAll(response.data);
        CacheHelper.set(entityKey, response.data);
        ClientService.saveClientsToHive(response.data, status);
        currentPage = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} client(s), Hive mis à jour',
          tag: 'CLIENT_CONTROLLER',
        );
      } else {
        clients.addAll(response.data);
      }

      totalPages = response.meta.lastPage;
      totalItems = response.meta.total;
      hasNextPage = response.hasNextPage;
      hasPreviousPage = response.hasPreviousPage;
      if (page > 1) currentPage = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Clients: $e', tag: 'CLIENT_CONTROLLER');
      if (clients.isEmpty) {
        final fallback = ClientService.getCachedClients(status);
        if (fallback.isNotEmpty) {
          clients.clear();
          clients.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les clients',
          );
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingInProgress = false;
    }
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  Future<void> loadByStatus(int index) async {
    await loadClients(status: index, forceRefresh: false);
  }

  Future<void> _refreshClientsFromApi(int? status, String cacheKey) async {
    if (_isRefreshingFromApi) return;
    _isRefreshingFromApi = true;
    try {
      AppLogger.debug(
        '[Retour API] demande en cours statut=$status...',
        tag: 'CLIENT_CONTROLLER',
      );
      final paginatedResponse = await _clientService.getClientsPaginated(
        status: status,
        page: 1,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );
      AppLogger.debug(
        '[Retour API] statut=$status, ${paginatedResponse.data.length} client(s) reçu(s)',
        tag: 'CLIENT_CONTROLLER',
      );
      if (_currentStatus != status) return;
      final newData = paginatedResponse.data;
      clients.clear();
      clients.addAll(newData);
      totalPages = paginatedResponse.meta.lastPage;
      totalItems = paginatedResponse.meta.total;
      hasNextPage = paginatedResponse.hasNextPage;
      hasPreviousPage = paginatedResponse.hasPreviousPage;
      currentPage = 1;
      CacheHelper.set(cacheKey, newData);
      ClientService.saveClientsToHive(newData, status);
    } catch (e) {
      if (clients.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Connexion',
          'Impossible de charger les clients. Vérifiez votre connexion.',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading = false;
      _isRefreshingFromApi = false;
      _isLoadingInProgress = false;
    }
  }

  Future<void> refreshData() async {
    await loadClients(status: _currentStatus, forceRefresh: true, page: 1);
  }

  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadClients(status: _currentStatus, page: currentPage + 1);
    }
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadClients(status: _currentStatus, page: currentPage - 1);
    }
  }

  Future<void> createClient(Client client) async {
    try {
      isLoading = true;

      final createdClient = await _clientService.createClient(client);

      CacheHelper.clearByPrefix('clients_');

      final newStatus = createdClient.status ?? 0;
      final shouldInsert = _currentStatus == null || _currentStatus == newStatus;
      if (shouldInsert) {
        clients.insert(0, createdClient);
        ClientService.saveClientsToHive(List.from(clients), _currentStatus);
      }

      if (createdClient.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'client',
          entityName: NotificationHelper.getEntityDisplayName(
            'client',
            createdClient,
          ),
          entityId: createdClient.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'client',
            createdClient.id.toString(),
          ),
        );
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return;
      }
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer le client',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<bool> createClientFromMap(Map<String, dynamic> data) async {
    if (isLoading) return false;
    try {
      isLoading = true;

      final client = Client.fromJson(data);
      final createdClient = await _clientService.createClient(client);

      CacheHelper.clearByPrefix('clients_');

      final newStatus = createdClient.status ?? 0;
      final shouldInsert = _currentStatus == null || _currentStatus == newStatus;
      if (shouldInsert) {
        clients.insert(0, createdClient);
        ClientService.saveClientsToHive(List.from(clients), _currentStatus);
      }

      if (createdClient.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'client',
          entityName: NotificationHelper.getEntityDisplayName(
            'client',
            createdClient,
          ),
          entityId: createdClient.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'client',
            createdClient.id.toString(),
          ),
        );
      }

      ErrorHelper.showSuccess('Client enregistré avec succès');
      DashboardRefreshHelper.refreshPatronCounter('client');
      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return false;
      }
      AppLogger.error(
        'Erreur lors de la création du client: $e',
        tag: 'CLIENT_CONTROLLER',
      );
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de créer le client: ${e.toString()}',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateClient(Map<String, dynamic> data) async {
    if (isLoading) return false;
    try {
      isLoading = true;

      final client = Client.fromJson(data);
      await _clientService.updateClient(client);

      ErrorHelper.showSuccess('Client mis à jour avec succès');

      try {
        await loadClients();
      } catch (e) {}

      return true;
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        return false;
      }
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le client',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> approveClient(int clientId) async {
    try {
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        if (_currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          final originalClient = clients[clientIndex];
          final updatedClient = Client(
            id: originalClient.id,
            nomEntreprise: originalClient.nomEntreprise,
            nom: originalClient.nom,
            prenom: originalClient.prenom,
            email: originalClient.email,
            contact: originalClient.contact,
            adresse: originalClient.adresse,
            status: 1,
            createdAt: originalClient.createdAt,
            updatedAt: originalClient.updatedAt,
          );
          clients[clientIndex] = updatedClient;
        }
      }

      final success = await _clientService.approveClient(clientId);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('client');

        final client = _firstWhereClientById(clients, clientId);
        if (client != null) {
          NotificationHelper.notifyValidation(
            entityType: 'client',
            entityName: NotificationHelper.getEntityDisplayName(
              'client',
              client,
            ),
            entityId: clientId.toString(),
            route: NotificationHelper.getEntityRoute(
              'client',
              clientId.toString(),
            ),
            entity: client,
          );
        }

        ErrorHelper.showSuccess('Client validé avec succès');
        DashboardRefreshHelper.refreshCommercialDashboard();

        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: _currentStatus).catchError((e) {});
        });
      } else {
        await loadClients(status: _currentStatus);
        errorHelperShowSnackbar?.call(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        loadClients(status: _currentStatus).catchError((e) {});
        return;
      }
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        loadClients(status: _currentStatus).catchError((e) {});
      }
    }
  }

  Future<void> rejectClient(int clientId, String comment) async {
    try {
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        if (_currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          final originalClient = clients[clientIndex];
          final updatedClient = Client(
            id: originalClient.id,
            nomEntreprise: originalClient.nomEntreprise,
            nom: originalClient.nom,
            prenom: originalClient.prenom,
            email: originalClient.email,
            contact: originalClient.contact,
            adresse: originalClient.adresse,
            status: 2,
            createdAt: originalClient.createdAt,
            updatedAt: originalClient.updatedAt,
          );
          clients[clientIndex] = updatedClient;
        }
      }

      final success = await _clientService.rejectClient(clientId, comment);
      if (success) {
        DashboardRefreshHelper.refreshPatronCounter('client');

        final client = _firstWhereClientById(clients, clientId);
        if (client != null) {
          NotificationHelper.notifyRejection(
            entityType: 'client',
            entityName: NotificationHelper.getEntityDisplayName(
              'client',
              client,
            ),
            entityId: clientId.toString(),
            reason: comment,
            route: NotificationHelper.getEntityRoute(
              'client',
              clientId.toString(),
            ),
            entity: client,
          );
        }

        ErrorHelper.showSuccess('Client rejeté avec succès');
        DashboardRefreshHelper.refreshCommercialDashboard();

        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: _currentStatus).catchError((e) {});
        });
      } else {
        await loadClients(status: _currentStatus);
        throw Exception('Erreur lors du rejet - Service a retourné false');
      }
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        loadClients(status: _currentStatus).catchError((e) {});
        return;
      }
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        loadClients(status: _currentStatus).catchError((e) {});
      }
    }
  }

  Future<void> deleteClient(int clientId) async {
    try {
      isLoading = true;
      final success = await _clientService.deleteClient(clientId);
      if (success) {
        clients.removeWhere((c) => c.id == clientId);
        ErrorHelper.showSuccess('Client supprimé avec succès');
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le client',
      );
    } finally {
      isLoading = false;
    }
  }

  void clearForm() {}
}
