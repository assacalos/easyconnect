import 'package:get/get.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';

class ClientController extends GetxController {
  final ClientService _clientService = ClientService();
  final clients = <Client>[].obs; // ✅ Utilise bien ton modèle
  final isLoading = false.obs;
  int? _currentStatus; // Mémoriser le statut actuellement chargé
  bool _isLoadingInProgress = false; // Protection contre les appels multiples

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    // Cela évite les erreurs et ralentissements inutiles
    // Les pages appelleront loadClients() quand nécessaire
  }

  Future<void> loadClients({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    // Protection contre les appels multiples simultanés
    if (_isLoadingInProgress) {
      AppLogger.debug(
        'Chargement déjà en cours, ignore cet appel',
        tag: 'CLIENT_CONTROLLER',
      );
      return;
    }

    try {
      // Si on ne force pas le rafraîchissement et que les données sont déjà chargées avec le même statut, ne rien faire
      // MAIS seulement si on a vraiment des données (pas si la liste est vide)
      // ET seulement si le statut a déjà été défini (pas au premier chargement)
      // ET seulement si c'est la même page
      if (!forceRefresh &&
          clients.isNotEmpty &&
          _currentStatus == status &&
          _currentStatus != null &&
          currentPage.value == page &&
          page == 1) {
        AppLogger.debug(
          'Données déjà chargées, pas de rechargement nécessaire',
          tag: 'CLIENT_CONTROLLER',
        );
        return;
      }

      _isLoadingInProgress = true;
      _currentStatus = status; // Mémoriser le statut actuel

      // Afficher IMMÉDIATEMENT les données du cache si disponibles (AVANT isLoading)
      final cacheKey =
          'clients_${status ?? 'all'}_false'; // Utiliser la même clé que le service
      final cachedClients = CacheHelper.get<List<Client>>(cacheKey);
      final hasCache =
          cachedClients != null &&
          cachedClients.isNotEmpty &&
          !forceRefresh &&
          page == 1;

      if (hasCache) {
        // Afficher le cache immédiatement pour que l'utilisateur voie quelque chose tout de suite
        clients.assignAll(cachedClients);
        isLoading.value = false; // Ne pas bloquer l'affichage si on a du cache
        AppLogger.debug(
          'Données chargées depuis le cache: ${cachedClients.length} clients',
          tag: 'CLIENT_CONTROLLER',
        );
      } else {
        // Pas de cache, afficher le loader
        isLoading.value = true;
      }

      // Charger les données avec pagination
      try {
        final paginatedResponse = await _clientService.getClientsPaginated(
          status: status,
          page: page,
          perPage: perPage.value,
          search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
        );

        // Mettre à jour les métadonnées de pagination
        totalPages.value = paginatedResponse.meta.lastPage;
        totalItems.value = paginatedResponse.meta.total;
        hasNextPage.value = paginatedResponse.hasNextPage;
        hasPreviousPage.value = paginatedResponse.hasPreviousPage;
        currentPage.value = paginatedResponse.meta.currentPage;

        // Mettre à jour la liste
        if (page == 1) {
          clients.value = paginatedResponse.data;
        } else {
          // Pour les pages suivantes, ajouter les données
          clients.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e, stackTrace) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        try {
          final loadedClients = await _clientService.getClients(
            status: status,
            isPending: false,
          );
          if (page == 1) {
            clients.value = loadedClients;
          } else {
            clients.addAll(loadedClients);
          }
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedClients);
          }
        } catch (fallbackError) {
          // Si le fallback échoue aussi, vérifier le cache
          if (!hasCache || page > 1) {
            if (clients.isEmpty) {
              final cacheKey = 'clients_${status ?? 'all'}_false';
              final cachedClients = CacheHelper.get<List<Client>>(cacheKey);
              if (cachedClients != null && cachedClients.isNotEmpty) {
                clients.assignAll(cachedClients);
                AppLogger.warning(
                  'Erreur réseau, utilisation du cache: $fallbackError',
                  tag: 'CLIENT_CONTROLLER',
                );
                return; // Ne pas afficher d'erreur si on a du cache
              }
            }
            rethrow; // Relancer l'erreur seulement si on n'avait pas de cache
          }
          AppLogger.warning(
            'Erreur lors du chargement frais, utilisation du cache: $fallbackError',
            tag: 'CLIENT_CONTROLLER',
          );
        }
      }
    } catch (e, stackTrace) {
      // Ne pas afficher de message d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        AppLogger.error(
          'Erreur lors du chargement des clients: $e',
          tag: 'CLIENT_CONTROLLER',
          error: e,
          stackTrace: stackTrace,
        );

        // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
        if (clients.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'clients_${status ?? 'all'}_false';
          final cachedClients = CacheHelper.get<List<Client>>(cacheKey);
          if (cachedClients == null || cachedClients.isEmpty) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les clients',
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            // Charger les données du cache si disponibles
            clients.assignAll(cachedClients);
          }
        }
      }
    } finally {
      isLoading.value = false;
      _isLoadingInProgress = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
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

      // Créer le client
      final createdClient = await _clientService.createClient(client);

      // Invalider le cache
      CacheHelper.clearByPrefix('clients_');

      // Ajouter le nouveau client à la liste localement (mise à jour optimiste)
      clients.insert(0, createdClient);

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadClients(forceRefresh: true);
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le client a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }
    } catch (e) {
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
    try {
      isLoading.value = true;

      // Transformer le Map en objet Client
      final client = Client.fromJson(data);

      // Créer le client
      final createdClient = await _clientService.createClient(client);

      // Invalider le cache pour forcer le rechargement
      CacheHelper.clearByPrefix('clients_');

      // Ajouter le nouveau client à la liste localement (mise à jour optimiste)
      clients.insert(0, createdClient);
      // Le client créé a toujours le status 0 (en attente)
      if (createdClient.id != null) {
        clients.add(createdClient);
      }

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Client enregistré avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Recharger la liste pour synchroniser avec le serveur
      try {
        await loadClients(status: null);

        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('client');
      } catch (e) {
        // Si le rechargement échoue, on garde quand même le client ajouté localement
        AppLogger.warning(
          'Erreur lors du rechargement après création: $e',
          tag: 'CLIENT_CONTROLLER',
        );
      }

      return true;
    } catch (e) {
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
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadClients(status: _currentStatus);
      // Ne pas afficher d'erreur si c'est juste un problème de parsing
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('401') &&
          !errorStr.contains('403') &&
          !errorStr.contains('unauthorized') &&
          !errorStr.contains('forbidden')) {
        Get.snackbar(
          'Erreur',
          'Impossible de valider le client: $e',
          snackPosition: SnackPosition.BOTTOM,
        );
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
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadClients(status: _currentStatus);
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le client: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
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
