import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class ClientController extends GetxController {
  final ClientService _clientService = ClientService();
  final clients = <Client>[].obs;
  final isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  int? _currentStatus;
  bool _isLoadingInProgress = false;
  bool _isRefreshingFromApi = false;

  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();

  Timer? _searchDebounceTimer;

  @override
  void onInit() {
    super.onInit();
    // Debounce recherche : loadClients 500ms après la dernière frappe
    ever(searchQuery, (_) {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        if (!_isLoadingInProgress) {
          AppLogger.debug(
            'Recherche (debounce): rechargement statut=$_currentStatus, query="${searchQuery.value}"',
            tag: 'CLIENT_CONTROLLER',
          );
          loadClients(status: _currentStatus, forceRefresh: true);
        }
      });
    });
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    scrollController.dispose();
    super.onClose();
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
        currentPage.value == page &&
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
      isLoading.value = true;
      final cachedData = ClientService.getCachedClients(status);
      if (cachedData.isNotEmpty) {
        clients.assignAll(cachedData);
        isLoading.value = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} client(s) → affichage instantané',
          tag: 'CLIENT_CONTROLLER',
        );
      } else {
        clients.value = [];
      }
    } else {
      isLoadingMore.value = true;
    }

    try {
      final response = await _clientService.getClientsPaginated(
        status: status,
        page: page,
        perPage: perPage.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug(
          '[API] onglet changé (current=$_currentStatus, response=$status), mise à jour ignorée',
          tag: 'CLIENT_CONTROLLER',
        );
        return;
      }

      if (page == 1) {
        clients.assignAll(response.data);
        CacheHelper.set(entityKey, response.data);
        ClientService.saveClientsToHive(response.data, status);
        currentPage.value = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} client(s), Hive mis à jour',
          tag: 'CLIENT_CONTROLLER',
        );
      } else {
        clients.addAll(response.data);
      }

      totalPages.value = response.meta.lastPage;
      totalItems.value = response.meta.total;
      hasNextPage.value = response.hasNextPage;
      hasPreviousPage.value = response.hasPreviousPage;
      if (page > 1) currentPage.value = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Clients: $e', tag: 'CLIENT_CONTROLLER');
      if (clients.isEmpty) {
        final fallback = ClientService.getCachedClients(status);
        if (fallback.isNotEmpty) {
          clients.assignAll(fallback);
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les clients',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      _isLoadingInProgress = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadNextPage();
    }
  }

  /// Charge les clients pour l’onglet donné (0=En attente, 1=Validés, 2=Rejetés). Appelé par le TabBar.
  Future<void> loadByStatus(int index) async {
    await loadClients(status: index, forceRefresh: false);
  }

  /// Méthode conservée pour compatibilité ; le flux unique est dans loadClients.
  // ignore: unused_element
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
        perPage: perPage.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );
      AppLogger.debug(
        '[Retour API] statut=$status, ${paginatedResponse.data.length} client(s) reçu(s)',
        tag: 'CLIENT_CONTROLLER',
      );
      if (_currentStatus != status) {
        AppLogger.debug(
          '[Retour API] onglet changé (current=$_currentStatus, response=$status), mise à jour ignorée',
          tag: 'CLIENT_CONTROLLER',
        );
        return;
      }
      final newData = paginatedResponse.data;
      clients.value = newData;
      totalPages.value = paginatedResponse.meta.lastPage;
      totalItems.value = paginatedResponse.meta.total;
      hasNextPage.value = paginatedResponse.hasNextPage;
      hasPreviousPage.value = paginatedResponse.hasPreviousPage;
      currentPage.value = 1;
      CacheHelper.set(cacheKey, newData);
      ClientService.saveClientsToHive(newData, status);
      AppLogger.debug(
        '[Mise à jour Cache] liste et Hive mis à jour avec ${newData.length} client(s)',
        tag: 'CLIENT_CONTROLLER',
      );
    } catch (e) {
      // Ne pas effacer les données déjà affichées (Hive/cache)
      AppLogger.warning(
        'Rafraîchissement clients en arrière-plan échoué: $e',
        tag: 'CLIENT_CONTROLLER',
      );
      // Message uniquement si la liste est vide (pas de cache) : erreur de chargement
      if (clients.isEmpty) {
        Get.snackbar(
          'Connexion',
          'Impossible de charger les clients. Vérifiez votre connexion.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      }
      // Si des données en cache sont déjà affichées, ne pas afficher de message (UX)
    } finally {
      isLoading.value = false;
      _isRefreshingFromApi = false;
      _isLoadingInProgress = false;
    }
  }

  /// Rafraîchissement manuel (ex. Pull to refresh). Recharge la liste avec l’API.
  Future<void> refreshData() async {
    await loadClients(status: _currentStatus, forceRefresh: true, page: 1);
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadClients(status: _currentStatus, page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadClients(status: _currentStatus, page: currentPage.value - 1);
    }
  }

  Future<void> createClient(Client client) async {
    try {
      isLoading.value = true;

      final createdClient = await _clientService.createClient(client);

      CacheHelper.clearByPrefix('clients_');

      // Insertion locale uniquement si le statut du nouveau client correspond à l'onglet actuel (ou tous)
      final newStatus = createdClient.status ?? 0;
      final shouldInsert = _currentStatus == null || _currentStatus == newStatus;
      if (shouldInsert) {
        clients.insert(0, createdClient);
        final fullList = clients.toList();
        ClientService.saveClientsToHive(fullList, _currentStatus);
        AppLogger.debug(
          '[Création client] insertion locale + mise à jour Hive (statut=$_currentStatus, ${fullList.length} total)',
          tag: 'CLIENT_CONTROLLER',
        );
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
      // Pas de loadClients(forceRefresh: true) pour ne pas écraser l'insertion par d'anciennes données
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return;
      }

      Get.snackbar(
        'Erreur',
        'Impossible de créer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createClientFromMap(Map<String, dynamic> data) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;

      final client = Client.fromJson(data);
      final createdClient = await _clientService.createClient(client);

      CacheHelper.clearByPrefix('clients_');

      // Insertion locale uniquement si le statut du nouveau client correspond à l'onglet actuel (ou tous)
      final newStatus = createdClient.status ?? 0;
      final shouldInsert = _currentStatus == null || _currentStatus == newStatus;
      if (shouldInsert) {
        clients.insert(0, createdClient);
        final fullList = clients.toList();
        ClientService.saveClientsToHive(fullList, _currentStatus);
        AppLogger.debug(
          '[Création client (Map)] insertion locale + mise à jour Hive (statut=$_currentStatus, ${fullList.length} total)',
          tag: 'CLIENT_CONTROLLER',
        );
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

      Get.snackbar(
        'Succès',
        'Client enregistré avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Rafraîchir les compteurs en arrière-plan (sans recharger la liste pour garder l'affichage instantané)
      DashboardRefreshHelper.refreshPatronCounter('client');
      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      AppLogger.error(
        'Erreur lors de la création du client: $e',
        tag: 'CLIENT_CONTROLLER',
      );
      Get.snackbar(
        'Erreur',
        'Impossible de créer le client: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateClient(Map<String, dynamic> data) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;

      final client = Client.fromJson(data); // ✅ conversion
      await _clientService.updateClient(client);

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Client mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadClients();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le client a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      // Ne pas afficher d'erreur pour les erreurs de parsing qui peuvent survenir après un succès
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        return false;
      }

      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le client',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveClient(int clientId) async {
    try {
      // Invalider le cache avant l'appel API (clients et dashboards)
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      // Mise à jour optimiste de l'UI - retirer immédiatement de la liste si on est sur l'onglet "En attente"
      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        // Si on est sur l'onglet "En attente" (status = 0), retirer le client de la liste
        if (_currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          // Sinon, mettre à jour le statut
          final originalClient = clients[clientIndex];
          final updatedClient = Client(
            id: originalClient.id,
            nomEntreprise: originalClient.nomEntreprise,
            nom: originalClient.nom,
            prenom: originalClient.prenom,
            email: originalClient.email,
            contact: originalClient.contact,
            adresse: originalClient.adresse,
            status: 1, // Validé
            createdAt: originalClient.createdAt,
            updatedAt: originalClient.updatedAt,
          );
          clients[clientIndex] = updatedClient;
        }
      }

      // Appel API en arrière-plan
      final success = await _clientService.approveClient(clientId);
      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('client');

        // Notifier l'utilisateur concerné de la validation
        final client = clients.firstWhereOrNull((c) => c.id == clientId);
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

        Get.snackbar(
          'Succès',
          'Client validé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur
        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: _currentStatus).catchError((e) {});
        });
      } else {
        // En cas d'échec, recharger les données pour restaurer l'état
        await loadClients(status: _currentStatus);
        // Ne pas afficher d'erreur si la validation a peut-être réussi côté serveur
        // (le service peut retourner false même si le status code était 200/201)
        Get.snackbar(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadClients(status: _currentStatus).catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        Get.snackbar(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadClients(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    }
  }

  Future<void> rejectClient(int clientId, String comment) async {
    try {
      // Invalider le cache avant l'appel API (clients et dashboards)
      CacheHelper.clearByPrefix('clients_');
      CacheHelper.clearByPrefix('dashboard_');

      // Mise à jour optimiste de l'UI - retirer immédiatement de la liste si on est sur l'onglet "En attente"
      final clientIndex = clients.indexWhere((c) => c.id == clientId);
      if (clientIndex != -1) {
        // Si on est sur l'onglet "En attente" (status = 0), retirer le client de la liste
        if (_currentStatus == 0) {
          clients.removeAt(clientIndex);
        } else {
          // Sinon, mettre à jour le statut
          final originalClient = clients[clientIndex];
          final updatedClient = Client(
            id: originalClient.id,
            nomEntreprise: originalClient.nomEntreprise,
            nom: originalClient.nom,
            prenom: originalClient.prenom,
            email: originalClient.email,
            contact: originalClient.contact,
            adresse: originalClient.adresse,
            status: 2, // Rejeté
            createdAt: originalClient.createdAt,
            updatedAt: originalClient.updatedAt,
          );
          clients[clientIndex] = updatedClient;
        }
      }

      // Appel API en arrière-plan
      final success = await _clientService.rejectClient(clientId, comment);
      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('client');

        // Notifier l'utilisateur concerné du rejet
        final client = clients.firstWhereOrNull((c) => c.id == clientId);
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

        Get.snackbar(
          'Succès',
          'Client rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadClients(status: _currentStatus).catchError((e) {
            // En cas d'erreur, on garde la mise à jour optimiste
          });
        });
      } else {
        // En cas d'échec, recharger les données pour restaurer l'état
        await loadClients(status: _currentStatus);
        throw Exception('Erreur lors du rejet - Service a retourné false');
      }
    } catch (e) {
      // Vérifier si l'erreur est survenue après un succès
      final errorStr = e.toString().toLowerCase();

      // Ne pas afficher d'erreur pour les erreurs de parsing ou de rechargement
      if (errorStr.contains('parsing') ||
          errorStr.contains('json') ||
          errorStr.contains('type') ||
          errorStr.contains('cast') ||
          errorStr.contains('null')) {
        // Probablement une erreur de parsing après un succès
        loadClients(status: _currentStatus).catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        Get.snackbar(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadClients(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    }
  }

  Future<void> deleteClient(int clientId) async {
    try {
      isLoading.value = true;
      final success = await _clientService.deleteClient(clientId);
      if (success) {
        clients.removeWhere((c) => c.id == clientId); // ✅ mise à jour locale
        Get.snackbar(
          'Succès',
          'Client supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le client',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Réinitialiser le formulaire
  void clearForm() {
    // Cette méthode est vide car les contrôleurs sont dans le formulaire
    // Mais elle peut être utilisée pour d'autres réinitialisations si nécessaire
  }
}
