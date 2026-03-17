import 'dart:async';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/error_helper.dart';

class DevisController {
  static final DevisController _instance = DevisController._();
  static DevisController get to => _instance;
  factory DevisController() => _instance;
  DevisController._();

  int get userId => int.parse(
    AuthController.to.userAuth?.id.toString() ?? '0',
  );

  final DevisService _devisService = DevisService();
  final ClientService _clientService = ClientService();

  final List<Devis> devis = [];
  Client? selectedClient;
  bool isLoading = false;
  Devis? currentDevis;
  final List<DevisItem> items = [];
  bool isLoadingMore = false;
  int? _currentStatus;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  int totalDevis = 0;
  int devisEnvoyes = 0;
  int devisAcceptes = 0;
  int devisRefuses = 0;
  double tauxConversion = 0.0;
  double montantTotal = 0.0;

  final List<Client> clients = [];
  bool isLoadingClients = false;

  String generatedReference = '';

  void setSearchQuery(String q) {
    if (searchQuery == q) return;
    searchQuery = q;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      AppLogger.debug(
        'Devis recherche (debounce): rechargement statut=$_currentStatus, query="$searchQuery"',
        tag: 'DEVIS_CONTROLLER',
      );
      loadDevis(status: _currentStatus, forceRefresh: true);
    });
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
  }

  /// Appeler l'endpoint de debug pour diagnostiquer les problèmes
  Future<void> debugDevis() async {
    try {
      AppLogger.info('Démarrage du debug des devis', tag: 'DEVIS_CONTROLLER');
      final debugInfo = await _devisService.getDevisDebug();
      AppLogger.info(
        'Informations de debug reçues: ${debugInfo.toString()}',
        tag: 'DEVIS_CONTROLLER',
      );

      // Afficher les informations de debug à l'utilisateur
      if (debugInfo['success'] == true && debugInfo['debug'] != null) {
        final debug = debugInfo['debug'];
        final stats = debug['statistics'];
        errorHelperShowSnackbar?.call(
          'Debug Devis',
          'Total: ${stats['total_devis']}, Par statut: ${stats['devis_by_status']}, Par user: ${stats['devis_by_user']}',
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      AppLogger.error('Erreur lors du debug: $e', tag: 'DEVIS_CONTROLLER');
      errorHelperShowSnackbar?.call(
        'Erreur Debug',
        'Impossible de récupérer les informations de debug: $e',
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> loadDevis({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) {
      AppLogger.debug(
        'Chargement déjà en cours, ignore',
        tag: 'DEVIS_CONTROLLER',
      );
      return;
    }
    if (!forceRefresh &&
        devis.isNotEmpty &&
        _currentStatus == status &&
        currentPage == page &&
        page == 1) {
      AppLogger.debug('Données déjà chargées', tag: 'DEVIS_CONTROLLER');
      return;
    }
    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'devis_${status ?? 'all'}';

    if (page == 1) {
      isLoading = true;
      if (!forceRefresh) {
        final cachedData = DevisService.getCachedDevis(status);
        if (cachedData.isNotEmpty) {
          devis.clear();
          devis.addAll(cachedData);
          isLoading = false;
          AppLogger.debug(
            '[Hive] statut=$status, ${cachedData.length} devis → affichage instantané',
            tag: 'DEVIS_CONTROLLER',
          );
        } else {
          devis.clear();
        }
      } else {
        devis.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final response = await _devisService.getDevisPaginated(
        status: status,
        page: page,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug(
          '[API] onglet changé, mise à jour ignorée',
          tag: 'DEVIS_CONTROLLER',
        );
        return;
      }

      if (page == 1) {
        devis.clear();
        devis.addAll(response.data);
        CacheHelper.set(entityKey, response.data);
        DevisService.saveDevisToHive(response.data, status);
        currentPage = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} devis, Hive mis à jour',
          tag: 'DEVIS_CONTROLLER',
        );
      } else {
        devis.addAll(response.data);
      }

      totalPages = response.meta.lastPage;
      totalItems = response.meta.total;
      hasNextPage = response.hasNextPage;
      hasPreviousPage = response.hasPreviousPage;
      if (page > 1) currentPage = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Devis: $e', tag: 'DEVIS_CONTROLLER');
      if (devis.isEmpty) {
        final fallback = DevisService.getCachedDevis(status);
        if (fallback.isNotEmpty) {
          devis.clear();
          devis.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les devis',
            backgroundColor: Colors.red,
            colorText: Colors.white,
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

  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadDevis(status: _currentStatus, page: currentPage + 1);
    }
  }

  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadDevis(status: _currentStatus, page: currentPage - 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _devisService.getDevisStats();
      totalDevis = stats['total'] ?? 0;
      devisEnvoyes = stats['envoyes'] ?? 0;
      devisAcceptes = stats['acceptes'] ?? 0;
      devisRefuses = stats['refuses'] ?? 0;
      tauxConversion = stats['taux_conversion'] ?? 0.0;
      montantTotal = stats['montant_total'] ?? 0.0;
    } catch (e) {}
  }

  Future<bool> createDevis(Map<String, dynamic> data) async {
    if (isLoading) return false;
    try {
      isLoading = true;

      if (selectedClient == null || selectedClient!.id == null) {
        AppLogger.error(
          'Client non sélectionné ou ID manquant',
          tag: 'DEVIS_CONTROLLER',
        );
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez sélectionner un client valide',
        );
        return false;
      }

      if (items.isEmpty) {
        AppLogger.error('Aucun article dans le devis', tag: 'DEVIS_CONTROLLER');
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Veuillez ajouter au moins un article',
        );
        return false;
      }

      AppLogger.info(
        'Création du devis avec référence: ${data['reference']}',
        tag: 'DEVIS_CONTROLLER',
      );

      final newDevis = Devis(
        clientId: selectedClient!.id!,
        reference: data['reference'],
        dateCreation: DateTime.now(),
        dateValidite: data['date_validite'],
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items,
        remiseGlobale: data['remise_globale'],
        tva: data['tva'],
        conditions: data['conditions'],
        commercialId: userId,
        titre: data['titre'],
        delaiLivraison: data['delai_livraison'],
        garantie: data['garantie'],
      );

      AppLogger.debug(
        'Devis préparé: ${newDevis.toJson()}',
        tag: 'DEVIS_CONTROLLER',
      );

      final createdDevis = await _devisService.createDevis(newDevis);

      CacheHelper.clearByPrefix('devis_');

      // Insertion locale uniquement si le statut correspond à l'onglet actuel (ou tous). Nouveau devis = statut 1 (en attente).
      const newDevisStatus = 1;
      final shouldInsert =
          _currentStatus == null || _currentStatus == newDevisStatus;
      if (createdDevis.id != null && shouldInsert) {
        final devisToAdd = Devis(
          id: createdDevis.id,
          clientId: createdDevis.clientId,
          reference: createdDevis.reference,
          dateCreation: createdDevis.dateCreation,
          dateValidite: createdDevis.dateValidite,
          notes: createdDevis.notes,
          status: 1,
          items: createdDevis.items,
          remiseGlobale: createdDevis.remiseGlobale,
          tva: createdDevis.tva,
          conditions: createdDevis.conditions,
          commercialId: userId,
          titre: createdDevis.titre,
          delaiLivraison: createdDevis.delaiLivraison,
          garantie: createdDevis.garantie,
        );
        if (!devis.any((d) => d.id == devisToAdd.id)) {
          devis.insert(0, devisToAdd);
          final fullList = List<Devis>.from(devis);
          DevisService.saveDevisToHive(fullList, _currentStatus);
          AppLogger.debug(
            '[Création devis] insertion locale + mise à jour Hive (statut=$_currentStatus, ${fullList.length} total)',
            tag: 'DEVIS_CONTROLLER',
          );
        }
      }

      DashboardRefreshHelper.refreshPatronCounter('devis');

      if (createdDevis.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'devis',
          entityName: NotificationHelper.getEntityDisplayName(
            'devis',
            createdDevis,
          ),
          entityId: createdDevis.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'devis',
            createdDevis.id.toString(),
          ),
        );
      }

      ErrorHelper.showSuccess('Devis créé avec succès');

      clearForm();
      // Pas de loadDevis(forceRefresh: true) pour ne pas écraser l'insertion par d'anciennes données

      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la création du devis: $e',
        tag: 'DEVIS_CONTROLLER',
        error: e,
        stackTrace: stackTrace,
      );

      // Afficher un message d'erreur plus détaillé
      String errorMessage = 'Impossible de créer le devis';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else if (e.toString().contains('HttpException')) {
        errorMessage = 'Erreur de connexion au serveur';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Erreur de format des données';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Délai d\'attente dépassé. Veuillez réessayer.';
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<bool> updateDevis(int devisId, Map<String, dynamic> data) async {
    if (isLoading) return false;
    try {
      isLoading = true;
      final devisToUpdate = devis.firstWhere((d) => d.id == devisId);
      final updatedDevis = Devis(
        id: devisId,
        clientId: devisToUpdate.clientId,
        reference: data['reference'] ?? devisToUpdate.reference,
        dateCreation: devisToUpdate.dateCreation,
        dateValidite: data['date_validite'] ?? devisToUpdate.dateValidite,
        notes: data['notes'] ?? devisToUpdate.notes,
        status: devisToUpdate.status,
        items: items.isEmpty ? devisToUpdate.items : items,
        remiseGlobale: data['remise_globale'] ?? devisToUpdate.remiseGlobale,
        tva: data['tva'] ?? devisToUpdate.tva,
        conditions: data['conditions'] ?? devisToUpdate.conditions,
        commercialId: devisToUpdate.commercialId,
        titre: data['titre'] ?? devisToUpdate.titre,
        delaiLivraison: data['delai_livraison'] ?? devisToUpdate.delaiLivraison,
        garantie: data['garantie'] ?? devisToUpdate.garantie,
      );

      await _devisService.updateDevis(updatedDevis);

      ErrorHelper.showSuccess('Devis mis à jour avec succès');

      try {
        await loadDevis();
      } catch (e) {}

      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le devis',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteDevis(int devisId) async {
    try {
      isLoading = true;
      final success = await _devisService.deleteDevis(devisId);
      if (success) {
        devis.removeWhere((d) => d.id == devisId);
        ErrorHelper.showSuccess('Devis supprimé avec succès');
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le devis',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> sendDevis(int devisId) async {
    try {
      isLoading = true;
      final success = await _devisService.sendDevis(devisId);
      if (success) {
        await loadDevis();
        ErrorHelper.showSuccess('Devis envoyé avec succès');
      } else {
        throw Exception('Erreur lors de l\'envoi');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible d\'envoyer le devis',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> acceptDevis(int devisId) async {
    try {
      isLoading = true;

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement le statut
      final devisIndex = devis.indexWhere((d) => d.id == devisId);
      Devis? originalDevis;
      if (devisIndex != -1) {
        originalDevis = devis[devisIndex];
        // Mettre à jour le statut à 2 (Validé) pour tous les cas
        final updatedDevis = Devis(
          id: originalDevis.id,
          clientId: originalDevis.clientId,
          reference: originalDevis.reference,
          dateCreation: originalDevis.dateCreation,
          dateValidite: originalDevis.dateValidite,
          notes: originalDevis.notes,
          status: 2, // Validé
          items: originalDevis.items,
          remiseGlobale: originalDevis.remiseGlobale,
          tva: originalDevis.tva,
          conditions: originalDevis.conditions,
          commercialId: originalDevis.commercialId,
          submittedBy: originalDevis.submittedBy,
          rejectionComment: originalDevis.rejectionComment,
          submittedAt: originalDevis.submittedAt,
          validatedAt: DateTime.now(), // Date de validation
          titre: originalDevis.titre,
          delaiLivraison: originalDevis.delaiLivraison,
          garantie: originalDevis.garantie,
        );

        // Mettre à jour le statut dans la liste complète
        // Remplacer le devis dans la liste par la version mise à jour
        devis[devisIndex] = updatedDevis;

        AppLogger.info(
          'Devis ${devisId} mis à jour avec statut 2 (Validé) dans la liste',
          tag: 'DEVIS_CONTROLLER',
        );
      }

      // Appel API
      final success = await _devisService.acceptDevis(devisId);

      if (success) {
        // Invalider le cache après succès (mémoire + Hive pour éviter données périmées)
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');
        await DevisService.clearDevisHiveCache();

        // Afficher le message de succès immédiatement
        ErrorHelper.showSuccess('Devis accepté avec succès');

        // Rafraîchir les compteurs et notifier en arrière-plan (non-bloquant)
        Future.microtask(() {
          DashboardRefreshHelper.refreshPatronCounter('devis');
          DashboardRefreshHelper.refreshCommercialDashboard();

          if (originalDevis != null) {
            NotificationHelper.notifyValidation(
              entityType: 'devis',
              entityName: NotificationHelper.getEntityDisplayName(
                'devis',
                originalDevis,
              ),
              entityId: devisId.toString(),
              route: NotificationHelper.getEntityRoute(
                'devis',
                devisId.toString(),
              ),
              entity: originalDevis,
            );
          }
        });

        // Recharger les données en arrière-plan après un court délai
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          // Recharger TOUS les devis (status null) pour que la page validation affiche à jour
          loadDevis(status: null, forceRefresh: true).catchError((e) {
            AppLogger.error(
              'Erreur lors du rechargement après validation: $e',
              tag: 'DEVIS_CONTROLLER',
            );
          });
        });
      } else {
        // En cas d'échec, restaurer l'état original
        if (originalDevis != null && devisIndex != -1) {
          if (devisIndex < devis.length) {
            devis.insert(devisIndex, originalDevis);
          } else {
            devis.add(originalDevis);
          }
        }

        // Ne pas afficher d'erreur si la validation a peut-être réussi côté serveur
        errorHelperShowSnackbar?.call(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
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
        loadDevis().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadDevis().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }

      // Recharger en arrière-plan pour restaurer l'état correct (non-bloquant)
      Future.microtask(() {
        loadDevis(status: _currentStatus).catchError((e) {
          AppLogger.error(
            'Erreur lors du rechargement après erreur: $e',
            tag: 'DEVIS_CONTROLLER',
          );
        });
      });
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectDevis(int devisId, String commentaire) async {
    try {
      isLoading = true;

      // Mise à jour optimiste de l'UI - retirer immédiatement de la liste si on est sur l'onglet "En attente"
      final devisIndex = devis.indexWhere((d) => d.id == devisId);
      Devis? originalDevis;
      if (devisIndex != -1) {
        originalDevis = devis[devisIndex];
        // Si on est sur l'onglet "En attente" (status = 1), retirer le devis de la liste
        // car un devis rejeté a généralement un status différent (3)
        if (_currentStatus == 1) {
          devis.removeAt(devisIndex);
        } else {
          // Sinon, mettre à jour le statut (status = 3 pour rejeté)
          final updatedDevis = Devis(
            id: originalDevis.id,
            clientId: originalDevis.clientId,
            reference: originalDevis.reference,
            dateCreation: originalDevis.dateCreation,
            dateValidite: originalDevis.dateValidite,
            notes: originalDevis.notes,
            status: 3, // Rejeté
            items: originalDevis.items,
            remiseGlobale: originalDevis.remiseGlobale,
            tva: originalDevis.tva,
            conditions: originalDevis.conditions,
            commercialId: originalDevis.commercialId,
          );
          devis[devisIndex] = updatedDevis;
        }
      }

      // Appel API
      final success = await _devisService.rejectDevis(devisId, commentaire);

      if (success) {
        // Invalider le cache après succès (mémoire + Hive)
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');
        await DevisService.clearDevisHiveCache();

        // Afficher le message de succès immédiatement
        ErrorHelper.showSuccess('Devis rejeté avec succès');

        // Rafraîchir les compteurs et notifier en arrière-plan (non-bloquant)
        Future.microtask(() {
          DashboardRefreshHelper.refreshPatronCounter('devis');
          DashboardRefreshHelper.refreshCommercialDashboard();

          if (originalDevis != null) {
            NotificationHelper.notifyRejection(
              entityType: 'devis',
              entityName: NotificationHelper.getEntityDisplayName(
                'devis',
                originalDevis,
              ),
              entityId: devisId.toString(),
              reason: commentaire,
              route: NotificationHelper.getEntityRoute(
                'devis',
                devisId.toString(),
              ),
              entity: originalDevis,
            );
          }
        });

        // Recharger les données en arrière-plan (non-bloquant)
        Future.microtask(() {
          loadDevis(status: _currentStatus).catchError((e) {
            AppLogger.error(
              'Erreur lors du rechargement après rejet: $e',
              tag: 'DEVIS_CONTROLLER',
            );
          });
        });
      } else {
        // En cas d'échec, restaurer l'état original
        if (originalDevis != null && devisIndex != -1) {
          if (devisIndex < devis.length) {
            devis.insert(devisIndex, originalDevis);
          } else {
            devis.add(originalDevis);
          }
        }

        throw Exception('Erreur lors du rejet du devis');
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
        loadDevis().catchError((e) {});
        return;
      }

      // Pour les autres erreurs, vérifier si c'est une erreur d'authentification
      if (errorStr.contains('401') ||
          errorStr.contains('403') ||
          errorStr.contains('unauthorized') ||
          errorStr.contains('forbidden')) {
        // Erreur d'authentification - afficher
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadDevis().catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }

      // Recharger en arrière-plan pour restaurer l'état correct (non-bloquant)
      Future.microtask(() {
        loadDevis(status: _currentStatus).catchError((e) {
          AppLogger.error(
            'Erreur lors du rechargement après erreur: $e',
            tag: 'DEVIS_CONTROLLER',
          );
        });
      });
    } finally {
      isLoading = false;
    }
  }

  void addItem(DevisItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, DevisItem item) {
    items[index] = item;
  }

  void clearItems() {
    items.clear();
  }

  Future<void> loadValidatedClients() async {
    isLoadingClients = true;
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      clients.clear();
      clients.addAll(cached);
      isLoadingClients = false;
    } else {
      clients.clear();
    }
    try {
      final clientsList = await _clientService.getClients(status: 1);
      final validatedClients = clientsList.where((c) => c.status == 1).toList();
      clients.clear();
      clients.addAll(validatedClients);
    } catch (e) {
      if (clients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          clients.clear();
          clients.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les clients validés',
          );
        }
      }
    } finally {
      isLoadingClients = false;
    }
  }

  Future<void> searchClients(String query) async {
    if (query.isEmpty) {
      await loadValidatedClients();
      return;
    }
    final cached = ClientService.getCachedClients(1);
    List<Client> validated =
        cached.isNotEmpty ? List.from(cached) : clients.toList();
    if (validated.isEmpty) {
      await loadValidatedClients();
      validated = List.from(clients);
    }
    final filtered =
        validated.where((client) {
          final nom = client.nom?.toLowerCase() ?? '';
          final email = client.email?.toLowerCase() ?? '';
          final q = query.toLowerCase();
          return nom.contains(q) || email.contains(q);
        }).toList();
    clients.clear();
    clients.addAll(filtered);
  }

  void selectClient(Client client) {
    selectedClient = client;
  }

  void clearSelectedClient() {
    selectedClient = null;
  }

  Future<String> generateReference() async {
    // Recharger les devis pour avoir le comptage à jour
    await loadDevis();

    // Extraire toutes les références existantes
    final existingReferences =
        devis.map((d) => d.reference).where((ref) => ref.isNotEmpty).toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'DEV',
      existingReferences,
    );
  }

  Future<void> initializeGeneratedReference() async {
    if (generatedReference.isEmpty) {
      generatedReference = await generateReference();
    }
  }

  void clearForm() {
    selectedClient = null;
    items.clear();
    generatedReference = '';
    initializeGeneratedReference();
  }

  Future<void> generatePDF(int devisId) async {
    try {
      isLoading = true;

      // Trouver le devis
      final selectedDevis = devis.firstWhere(
        (d) => d.id == devisId,
        orElse: () => throw Exception('Devis introuvable'),
      );

      // Charger les données nécessaires (timeout long : génération PDF peut être lente)
      final clients = await _clientService.getClients(
        timeout: AppConfig.extraLongTimeout,
      );
      final client = clients.firstWhere(
        (c) => c.id == selectedDevis.clientId,
        orElse: () => throw Exception('Client introuvable pour ce devis'),
      );

      // Sécuriser les champs pour éviter les erreurs si des valeurs sont null ou vides
      final items =
          selectedDevis.items
              .map(
                (item) => {
                  'reference': item.reference?.toString().trim() ?? '',
                  'designation':
                      (item.designation.toString().trim().isNotEmpty
                          ? item.designation
                          : 'Article sans désignation'),
                  'unite': 'unité',
                  'quantite': item.quantite > 0 ? item.quantite : 1,
                  'prix_unitaire':
                      (item.prixUnitaire.isFinite && item.prixUnitaire >= 0)
                          ? item.prixUnitaire
                          : 0.0,
                  'montant_total':
                      (item.total.isFinite && item.total >= 0)
                          ? item.total
                          : 0.0,
                },
              )
              .toList();

      // Générer le PDF avec des valeurs toujours définies
      await PdfService().generateDevisPdf(
        devis: {
          'reference':
              (selectedDevis.reference.trim().isNotEmpty
                  ? selectedDevis.reference
                  : 'N/A'),
          'date_creation': selectedDevis.dateCreation,
          'montant_ht':
              (selectedDevis.totalHT.isFinite ? selectedDevis.totalHT : 0.0),
          'tva': selectedDevis.tva ?? 0.0,
          'total_ttc':
              (selectedDevis.totalTTC.isFinite ? selectedDevis.totalTTC : 0.0),
          'titre': selectedDevis.titre?.toString().trim() ?? '',
          'delai_livraison': selectedDevis.delaiLivraison?.toString().trim() ?? '',
          'garantie': selectedDevis.garantie?.toString().trim() ?? '',
          'conditions': selectedDevis.conditions?.toString().trim() ?? '',
        },
        items: items,
        client: {
          'nom': client.nom?.toString().trim() ?? '',
          'prenom': client.prenom?.toString().trim() ?? '',
          'nom_entreprise': client.nomEntreprise?.toString().trim() ?? '',
          'email': client.email?.toString().trim() ?? '',
          'contact': client.contact?.toString().trim() ?? '',
          'adresse': client.adresse?.toString().trim() ?? '',
          'numero_contribuable': client.numeroContribuable?.toString().trim() ?? '',
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
      );

      ErrorHelper.showSuccess('PDF généré avec succès');
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading = false;
    }
  }
}
