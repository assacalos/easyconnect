import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bordereau_model.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Models/devis_model.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/error_helper.dart';

Bordereau? _firstWhereBordereauById(List<Bordereau> list, int id) {
  try {
    return list.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}

class BordereauxController {
  static final BordereauxController _instance = BordereauxController._();
  static BordereauxController get to => _instance;
  factory BordereauxController() => _instance;
  BordereauxController._();

  int get userId => int.parse(AuthController.to.userAuth?.id.toString() ?? '0');

  final BordereauService _bordereauService = BordereauService();
  final ClientService _clientService = ClientService();
  final DevisService _devisService = DevisService();

  final List<Bordereau> bordereaux = [];
  final List<Client> availableClients = [];
  Client? selectedClient;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingClients = false;
  Bordereau? currentBordereau;
  final List<BordereauItem> items = [];

  final List<Devis> availableDevis = [];
  Devis? selectedDevis;
  bool isLoadingDevis = false;

  String generatedReference = '';

  int? _currentStatus;
  bool _isLoadingInProgress = false;

  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';
  final ScrollController scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  int totalBordereaux = 0;
  int bordereauEnvoyes = 0;
  int bordereauAcceptes = 0;
  int bordereauRefuses = 0;
  double montantTotal = 0.0;

  void setSearchQuery(String q) {
    if (searchQuery == q) return;
    searchQuery = q;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      AppLogger.debug(
        'Bordereaux recherche (debounce): rechargement statut=$_currentStatus, query="$searchQuery"',
        tag: 'BORDEREAU_CONTROLLER',
      );
      loadBordereaux(status: _currentStatus, forceRefresh: true);
    });
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
    scrollController.dispose();
  }

  Future<void> loadBordereaux({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) {
      AppLogger.debug('Chargement déjà en cours, ignore', tag: 'BORDEREAU_CONTROLLER');
      return;
    }
    if (!forceRefresh &&
        bordereaux.isNotEmpty &&
        _currentStatus == status &&
        currentPage == page &&
        page == 1) {
      AppLogger.debug('Données déjà chargées', tag: 'BORDEREAU_CONTROLLER');
      return;
    }
    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'bordereaux_${status ?? 'all'}';

    if (page == 1) {
      isLoading = true;
      if (!forceRefresh) {
        final cachedData = BordereauService.getCachedBordereaux(status);
        if (cachedData.isNotEmpty) {
          bordereaux.clear();
          bordereaux.addAll(cachedData);
          isLoading = false;
          AppLogger.debug(
            '[Hive] statut=$status, ${cachedData.length} bordereau(x) → affichage instantané',
            tag: 'BORDEREAU_CONTROLLER',
          );
        } else {
          bordereaux.clear();
        }
      } else {
        bordereaux.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final response = await _bordereauService.getBordereauxPaginated(
        status: status,
        page: page,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug('[API] onglet changé, mise à jour ignorée', tag: 'BORDEREAU_CONTROLLER');
        return;
      }

      if (page == 1) {
        bordereaux.clear();
        bordereaux.addAll(response.data);
        CacheHelper.set(entityKey, response.data);
        BordereauService.saveBordereauxToHive(response.data, status);
        currentPage = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} bordereau(x), Hive mis à jour',
          tag: 'BORDEREAU_CONTROLLER',
        );
      } else {
        bordereaux.addAll(response.data);
      }

      totalPages = response.meta.lastPage;
      totalItems = response.meta.total;
      hasNextPage = response.hasNextPage;
      hasPreviousPage = response.hasPreviousPage;
      if (page > 1) currentPage = response.meta.currentPage;
    } catch (e) {
      if (AuthErrorHandler.shouldIgnoreError(e)) return;
      final err = e.toString().toLowerCase();
      if (err.contains('401') || err.contains('unauthorized') || err.contains('non autorisé')) return;
      AppLogger.error('Erreur API Bordereaux: $e', tag: 'BORDEREAU_CONTROLLER');
      if (bordereaux.isEmpty) {
        final fallback = BordereauService.getCachedBordereaux(status);
        if (fallback.isNotEmpty) {
          bordereaux.clear();
          bordereaux.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les bordereaux. Vérifiez votre connexion ou réessayez.',
            duration: const Duration(seconds: 3),
          );
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingInProgress = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  /// Charge les bordereaux pour l’onglet donné (0=En attente, 1=Validés, 2=Rejetés → status 1,2,3). Appelé par le TabBar.
  Future<void> loadByStatus(int index) async {
    final status = index == 0 ? 1 : index == 1 ? 2 : 3;
    await loadBordereaux(status: status, forceRefresh: false);
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadBordereaux(status: _currentStatus, page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading && !isLoadingMore) {
      loadBordereaux(status: _currentStatus, page: currentPage - 1);
    }
  }

  // ignore: unused_element
  Future<void> _refreshBordereauxFromApi(int? status, String cacheKey) async {
    if (_isLoadingInProgress) return;
    _isLoadingInProgress = true;
    try {
      AppLogger.debug(
        '[Retour API] demande en cours statut=$status...',
        tag: 'BORDEREAU_CONTROLLER',
      );
      try {
        final paginatedResponse = await _bordereauService.getBordereauxPaginated(
          status: status,
          page: 1,
          perPage: perPage,
          search: searchQuery.isNotEmpty ? searchQuery : null,
        );
        AppLogger.debug(
          '[Retour API] statut=$status, ${paginatedResponse.data.length} bordereau(x) reçu(s)',
          tag: 'BORDEREAU_CONTROLLER',
        );
        if (_currentStatus != status) {
          AppLogger.debug(
            '[Retour API] onglet changé (current=$_currentStatus, response=$status), mise à jour ignorée',
            tag: 'BORDEREAU_CONTROLLER',
          );
          return;
        }
        final newData = paginatedResponse.data;
        final different = _bordereauxDataDifferent(bordereaux, newData);
        if (different || newData.isEmpty) {
          bordereaux.clear();
          bordereaux.addAll(newData);
          totalPages = paginatedResponse.meta.lastPage;
          totalItems = paginatedResponse.meta.total;
          hasNextPage = paginatedResponse.hasNextPage;
          hasPreviousPage = paginatedResponse.hasPreviousPage;
          currentPage = 1;
          CacheHelper.set(cacheKey, newData);
          BordereauService.saveBordereauxToHive(newData, status);
          AppLogger.debug(
            '[Mise à jour Cache] liste et Hive mis à jour avec ${newData.length} bordereau(x)',
            tag: 'BORDEREAU_CONTROLLER',
          );
        }
        return;
      } catch (_) {
        // Fallback : utiliser /api/bordereaux-list
        final list = await _bordereauService.getBordereaux(status: status);
        if (_currentStatus != status) return;
        bordereaux.clear();
        bordereaux.addAll(list);
        totalPages = list.isEmpty ? 1 : 1;
        totalItems = list.length;
        hasNextPage = false;
        hasPreviousPage = false;
        currentPage = 1;
        CacheHelper.set(cacheKey, list);
        return;
      }
    } catch (e) {
      AppLogger.warning(
        'Rafraîchissement bordereaux en arrière-plan échoué: $e',
        tag: 'BORDEREAU_CONTROLLER',
      );
      if (AuthErrorHandler.shouldIgnoreError(e)) {
        isLoading = false;
        return;
      }
      final err = e.toString().toLowerCase();
      if (err.contains('401') || err.contains('unauthorized') || err.contains('non autorisé')) {
        isLoading = false;
        return;
      }
      if (bordereaux.isEmpty) {
        errorHelperShowSnackbar?.call(
          'Connexion',
          'Impossible de charger les bordereaux. Vérifiez votre connexion ou réessayez.',
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      isLoading = false;
      _isLoadingInProgress = false;
    }
  }

  static bool _bordereauxDataDifferent(List<Bordereau> a, List<Bordereau> b) {
    if (a.length != b.length) return true;
    for (var i = 0; i < a.length; i++) {
      final ad = a[i].dateValidation?.toIso8601String() ?? a[i].dateCreation.toIso8601String();
      final bd = b[i].dateValidation?.toIso8601String() ?? b[i].dateCreation.toIso8601String();
      if (a[i].id != b[i].id || ad != bd) return true;
    }
    return false;
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bordereauService.getBordereauStats();
      totalBordereaux = stats['total'] ?? 0;
      bordereauEnvoyes = stats['envoyes'] ?? 0;
      bordereauAcceptes = stats['acceptes'] ?? 0;
      bordereauRefuses = stats['refuses'] ?? 0;
      montantTotal = stats['montant_total'] ?? 0.0;
    } catch (e) {}
  }

  Future<bool> createBordereau(Map<String, dynamic> data) async {
    if (isLoading) return false;
    print('🔵 [BORDEREAU] Début de createBordereau');
    try {
      // Vérifications
      if (selectedClient == null) {
        print('❌ [BORDEREAU] Erreur: Aucun client sélectionné');
        throw Exception('Aucun client sélectionné');
      }
      if (items.isEmpty) {
        print('❌ [BORDEREAU] Erreur: Aucun article ajouté');
        throw Exception('Aucun article ajouté au bordereau');
      }

      print('✅ [BORDEREAU] Validations OK, démarrage du chargement');
      isLoading = true;

      // Utiliser la référence générée si un devis est sélectionné, sinon utiliser celle fournie
      final reference =
          selectedDevis != null && generatedReference.isNotEmpty
              ? generatedReference
              : data['reference'];

      DateTime? parseDateLivraison(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) {
          try {
            return DateTime.parse(v);
          } catch (_) {}
        }
        return null;
      }

      final newBordereau = Bordereau(
        clientId: selectedClient!.id!,
        devisId: selectedDevis?.id,
        reference: reference,
        titre: data['titre']?.toString(),
        dateCreation: DateTime.now(),
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items.toList(), // Convertir en liste
        commercialId: userId,
        etatLivraison: data['etat_livraison']?.toString(),
        garantie: data['garantie']?.toString(),
        dateLivraison: parseDateLivraison(data['date_livraison']),
      );

      print(
        '📤 [BORDEREAU] Appel du service pour créer: ${newBordereau.reference}',
      );
      AppLogger.info(
        'Création du bordereau en cours: ${newBordereau.reference}',
        tag: 'BORDEREAU_CONTROLLER',
      );

      final createdBordereau = await _bordereauService.createBordereau(
        newBordereau,
      );

      print(
        '📥 [BORDEREAU] Réponse du service reçue - ID: ${createdBordereau.id}, Référence: ${createdBordereau.reference}',
      );

      // Vérifier que la création a vraiment réussi (l'entité a un ID)
      if (createdBordereau.id == null) {
        print('❌ [BORDEREAU] ERREUR: Bordereau créé mais sans ID');
        AppLogger.error(
          'Bordereau créé mais sans ID',
          tag: 'BORDEREAU_CONTROLLER',
        );
        throw Exception(
          'Le bordereau a été créé mais sans ID. Veuillez réessayer.',
        );
      }

      print(
        '✅ [BORDEREAU] Bordereau créé avec succès: ID ${createdBordereau.id}',
      );
      AppLogger.info(
        'Bordereau créé avec succès: ID ${createdBordereau.id}, Référence: ${createdBordereau.reference}',
        tag: 'BORDEREAU_CONTROLLER',
      );

      CacheHelper.clearByPrefix('bordereaux_');
      await BordereauService.clearBordereauxHiveCache();

      // Insertion locale uniquement si le statut correspond
      const newBordereauStatus = 1;
      final shouldInsert = _currentStatus == null || _currentStatus == newBordereauStatus;
      if (shouldInsert) {
        bordereaux.insert(0, createdBordereau);
        final fullList = bordereaux.toList();
        BordereauService.saveBordereauxToHive(fullList, _currentStatus);
        AppLogger.debug(
          '[Création bordereau] insertion locale + mise à jour Hive (statut=$_currentStatus, ${fullList.length} total)',
          tag: 'BORDEREAU_CONTROLLER',
        );
      }

      if (createdBordereau.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bordereau',
          entityName: NotificationHelper.getEntityDisplayName(
            'bordereau',
            createdBordereau,
          ),
          entityId: createdBordereau.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'bordereau',
            createdBordereau.id.toString(),
          ),
        );
      }

      isLoading = false;
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter('bordereau');
      });
      clearForm();

      errorHelperShowSnackbar?.call(
        'Succès',
        'Bordereau créé avec succès',
        duration: const Duration(seconds: 3),
      );
      // Pas de loadBordereaux(forceRefresh: true) pour ne pas écraser l'insertion par d'anciennes données

      return true;
    } catch (e) {
      // S'assurer que le loader est arrêté en cas d'erreur
      isLoading = false;

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

      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      AppLogger.error(
        'Erreur lors de la création du bordereau: $e',
        tag: 'BORDEREAU_CONTROLLER',
        error: e,
      );

      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        duration: const Duration(seconds: 8),
      );
      return false;
    }
  }

  Future<bool> updateBordereau(
    int bordereauId,
    Map<String, dynamic> data,
  ) async {
    if (isLoading) return false;
    try {
      isLoading = true;
      final bordereauToUpdate = bordereaux.firstWhere(
        (b) => b.id == bordereauId,
      );
      DateTime? parseDate(dynamic v) {
        if (v == null) return null;
        if (v is DateTime) return v;
        if (v is String && v.isNotEmpty) {
          try {
            return DateTime.parse(v);
          } catch (_) {}
        }
        return null;
      }

      final updatedBordereau = Bordereau(
        id: bordereauId,
        clientId: bordereauToUpdate.clientId,
        devisId: bordereauToUpdate.devisId,
        reference: data['reference'] ?? bordereauToUpdate.reference,
        titre: data['titre'] ?? bordereauToUpdate.titre,
        dateCreation: bordereauToUpdate.dateCreation,
        dateValidation: bordereauToUpdate.dateValidation,
        notes: data['notes'] ?? bordereauToUpdate.notes,
        status: bordereauToUpdate.status,
        items: items.isEmpty ? bordereauToUpdate.items : items,
        commercialId: bordereauToUpdate.commercialId,
        commentaireRejet: bordereauToUpdate.commentaireRejet,
        etatLivraison: data['etat_livraison'] ?? bordereauToUpdate.etatLivraison,
        garantie: data['garantie'] ?? bordereauToUpdate.garantie,
        dateLivraison: parseDate(data['date_livraison']) ?? bordereauToUpdate.dateLivraison,
      );

      await _bordereauService.updateBordereau(updatedBordereau);

      // Si la mise à jour réussit, afficher le message de succès
      errorHelperShowSnackbar?.call(
        'Succès',
        'Bordereau mis à jour avec succès',
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadBordereaux();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le bordereau a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le bordereau',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteBordereau(int bordereauId) async {
    try {
      isLoading = true;
      final success = await _bordereauService.deleteBordereau(bordereauId);
      if (success) {
        bordereaux.removeWhere((b) => b.id == bordereauId);
        errorHelperShowSnackbar?.call(
          'Succès',
          'Bordereau supprimé avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le bordereau',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> submitBordereau(int bordereauId) async {
    try {
      isLoading = true;
      final success = await _bordereauService.submitBordereau(bordereauId);
      if (success) {
        await loadBordereaux();

        // Notifier de manière asynchrone (non-bloquant)
        final bordereau = _firstWhereBordereauById(bordereaux, bordereauId);
        if (bordereau != null) {
          NotificationHelper.notifySubmission(
            entityType: 'bordereau',
            entityName: NotificationHelper.getEntityDisplayName(
              'bordereau',
              bordereau,
            ),
            entityId: bordereauId.toString(),
            route: NotificationHelper.getEntityRoute(
              'bordereau',
              bordereauId.toString(),
            ),
          );
        }

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bordereau soumis avec succès',
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de soumettre le bordereau',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> approveBordereau(int bordereauId) async {
    bool validationSucceeded = false;
    try {
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bordereaux_');
      await BordereauService.clearBordereauxHiveCache();

      // Mise à jour optimiste de l'UI
      final bordereauIndex = bordereaux.indexWhere((b) => b.id == bordereauId);
      Bordereau? originalBordereau;
      if (bordereauIndex != -1) {
        originalBordereau = bordereaux[bordereauIndex];
        // Si on est sur l'onglet "En attente" (status = 1), retirer le bordereau de la liste
        if (_currentStatus == 1) {
          bordereaux.removeAt(bordereauIndex);
        } else {
          // Sinon, mettre à jour le statut (status = 2 pour approuvé)
          final updatedBordereau = Bordereau(
            id: originalBordereau.id,
            reference: originalBordereau.reference,
            clientId: originalBordereau.clientId,
            commercialId: originalBordereau.commercialId,
            devisId: originalBordereau.devisId,
            dateCreation: originalBordereau.dateCreation,
            dateValidation: originalBordereau.dateValidation,
            notes: originalBordereau.notes,
            status: 2, // Approuvé
            items: originalBordereau.items,
          );
          bordereaux[bordereauIndex] = updatedBordereau;
        }
      }

      try {
        final success = await _bordereauService.approveBordereau(bordereauId);

        if (success) {
          validationSucceeded = true; // Marquer que la validation a réussi

          // Rafraîchir les compteurs du dashboard patron et commercial
          DashboardRefreshHelper.refreshPatronCounter('bordereau');
          DashboardRefreshHelper.refreshCommercialDashboard();

          // Notifier de manière asynchrone (non-bloquant)
          final bordereau = _firstWhereBordereauById(bordereaux, bordereauId);
          if (bordereau != null) {
            NotificationHelper.notifyValidation(
              entityType: 'bordereau',
              entityName: NotificationHelper.getEntityDisplayName(
                'bordereau',
                bordereau,
              ),
              entityId: bordereauId.toString(),
              route: NotificationHelper.getEntityRoute(
                'bordereau',
                bordereauId.toString(),
              ),
              entity: bordereau,
            );
          }

          errorHelperShowSnackbar?.call(
            'Succès',
            'Bordereau approuvé avec succès',
          );

          // Recharger les données en arrière-plan après un court délai
          // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
          Future.delayed(const Duration(milliseconds: 500), () {
            loadBordereaux(status: _currentStatus).catchError((e) {
              // En cas d'erreur, on garde la mise à jour optimiste
            });
          });
        } else {
          // En cas d'échec, recharger pour restaurer l'état
          await loadBordereaux(status: _currentStatus);
          throw Exception(
            'Erreur lors de l\'approbation - La réponse du serveur indique un échec',
          );
        }
      } catch (e) {
        // En cas d'erreur, recharger pour restaurer l'état correct
        if (originalBordereau != null) {
          await loadBordereaux(status: _currentStatus);
        }
        // Si le service a lancé une exception, la propager seulement si la validation n'a pas réussi
        if (!validationSucceeded) {
          rethrow;
        }
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
        loadBordereaux(status: _currentStatus).catchError((e) {});
        return;
      }

      // Ne pas afficher le message d'erreur si la validation a réussi
      // (les erreurs peuvent venir des opérations asynchrones comme les notifications)
      if (!validationSucceeded) {
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Impossible d\'approuver le bordereau: $e',
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      isLoading = true;
      // Mise à jour optimiste : retirer ou mettre à jour le bordereau dans la liste
      final bordereauIndex = bordereaux.indexWhere((b) => b.id == bordereauId);
      Bordereau? originalBordereau;
      if (bordereauIndex != -1) {
        originalBordereau = bordereaux[bordereauIndex];
        if (_currentStatus == 1) {
          bordereaux.removeAt(bordereauIndex);
        } else {
          final updatedBordereau = Bordereau(
            id: originalBordereau.id,
            reference: originalBordereau.reference,
            titre: originalBordereau.titre,
            clientId: originalBordereau.clientId,
            commercialId: originalBordereau.commercialId,
            devisId: originalBordereau.devisId,
            dateCreation: originalBordereau.dateCreation,
            dateValidation: originalBordereau.dateValidation,
            notes: originalBordereau.notes,
            status: 3, // Rejeté
            items: originalBordereau.items,
            commentaireRejet: commentaire,
            etatLivraison: originalBordereau.etatLivraison,
            garantie: originalBordereau.garantie,
            dateLivraison: originalBordereau.dateLivraison,
          );
          bordereaux[bordereauIndex] = updatedBordereau;
        }
      }
      try {
        final success = await _bordereauService.rejectBordereau(
          bordereauId,
          commentaire,
        );

        if (success) {
          await BordereauService.clearBordereauxHiveCache();
          // Sync en arrière-plan (pas d'await pour ne pas bloquer l'UI)
          loadBordereaux(status: _currentStatus).catchError((e) {});

          // Rafraîchir les compteurs du dashboard patron et commercial
          DashboardRefreshHelper.refreshPatronCounter('bordereau');
          DashboardRefreshHelper.refreshCommercialDashboard();

          // Notifier de manière asynchrone (non-bloquant)
          final bordereau = _firstWhereBordereauById(bordereaux, bordereauId)
              ?? originalBordereau;
          if (bordereau != null) {
            NotificationHelper.notifyRejection(
              entityType: 'bordereau',
              entityName: NotificationHelper.getEntityDisplayName(
                'bordereau',
                bordereau,
              ),
              entityId: bordereauId.toString(),
              reason: commentaire,
              route: NotificationHelper.getEntityRoute(
                'bordereau',
                bordereauId.toString(),
              ),
              entity: bordereau,
            );
          }

          errorHelperShowSnackbar?.call(
            'Succès',
            'Bordereau rejeté avec succès',
          );
        } else {
          throw Exception(
            'Erreur lors du rejet - La réponse du serveur indique un échec',
          );
        }
      } catch (e) {
        // Si le service a lancé une exception, la propager
        rethrow;
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
        loadBordereaux(status: _currentStatus).catchError((e) {});
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
        loadBordereaux(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  // Gestion des items
  void addItem(BordereauItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, BordereauItem item) {
    items[index] = item;
  }

  void clearItems() {
    items.clear();
  }

  // Chargement des clients validés : cache Hive d'abord (affichage immédiat), puis API.
  Future<void> loadValidatedClients() async {
    isLoadingClients = true;
    // Afficher tout de suite les clients validés en cache (évite liste vide au premier affichage)
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      availableClients.clear();
      availableClients.addAll(cached);
      isLoadingClients = false;
    } else {
      availableClients.clear();
    }
    try {
      final clients = await _clientService.getClients(status: 1);
      availableClients.clear();
      availableClients.addAll(clients);
    } catch (e) {
      if (availableClients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          availableClients.clear();
          availableClients.addAll(fallback);
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

  // Recherche de clients validés
  Future<void> searchClients(String query) async {
    try {
      if (availableClients.isEmpty) {
        await loadValidatedClients();
      }
      // La recherche sera implémentée dans l'interface utilisateur
    } catch (e) {}
  }

  void selectClient(Client client) {
    selectedClient = client;
    // Charger les devis validés pour ce client
    onClientChanged(client);
  }

  void clearSelectedClient() {
    selectedClient = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient = null;
    selectedDevis = null;
    availableDevis.clear();
    items.clear();
  }

  // Chargement des devis validés pour le client sélectionné : cache Hive d'abord (status 2 = validé), puis API.
  Future<void> loadValidatedDevisForClient(int clientId) async {
    isLoadingDevis = true;
    final cached = DevisService.getCachedDevis(2);
    final cachedForClient = cached.where((d) => d.clientId == clientId).toList();
    if (cachedForClient.isNotEmpty) {
      availableDevis.clear();
      availableDevis.addAll(cachedForClient);
      isLoadingDevis = false;
    } else {
      availableDevis.clear();
    }
    try {
      final devis = await _devisService.getDevis(status: 2, clientId: clientId);
      availableDevis.clear();
      availableDevis.addAll(devis);
    } catch (e) {
      if (availableDevis.isEmpty) {
        final fallback = DevisService.getCachedDevis(2)
            .where((d) => d.clientId == clientId)
            .toList();
        if (fallback.isNotEmpty) {
          availableDevis.clear();
          availableDevis.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les devis validés',
          );
        }
      }
    } finally {
      isLoadingDevis = false;
    }
  }

  // Générer automatiquement la référence du bordereau basée sur le devis
  Future<String> generateBordereauReference(int? devisId) async {
    if (devisId == null) {
      // Si pas de devis, générer une référence par défaut
      return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Trouver le devis sélectionné
    final devis = selectedDevis;
    if (devis == null) {
      return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Recharger les bordereaux pour avoir le comptage à jour
    await loadBordereaux();

    // Compter combien de bordereaux existent déjà pour ce devis
    final existingBordereaux =
        bordereaux.where((b) => b.devisId == devisId).toList();
    final increment = existingBordereaux.length + 1;

    // Générer la référence : [référence_devis]-BL[incrément]
    return '${devis.reference}-BL$increment';
  }

  // Sélection d'un devis
  Future<void> selectDevis(Devis devis) async {
    selectedDevis = devis;

    // Générer automatiquement la référence
    final ref = await generateBordereauReference(devis.id);
    generatedReference = ref;
    print('📋 [BORDEREAU] Référence générée: $ref');

    // Pré-remplir les items du bordereau avec les items du devis (sans les prix)
    items.clear();
    for (final devisItem in devis.items) {
      final bordereauItem = BordereauItem(
        reference: devisItem.reference,
        designation: devisItem.designation,
        unite: 'unité',
        quantite: devisItem.quantite,
        description: 'Basé sur le devis ${devis.reference}',
      );
      items.add(bordereauItem);
    }
  }

  // Effacer la sélection du devis
  void clearSelectedDevis() {
    selectedDevis = null;
    generatedReference = '';
    items.clear();
  }

  // Recharger les devis quand le client change
  void onClientChanged(Client? client) {
    if (client != null) {
      loadValidatedDevisForClient(client.id!);
    } else {
      availableDevis.clear();
      selectedDevis = null;
      items.clear();
    }
  }

  /// Générer un PDF pour un bordereau
  Future<void> generatePDF(int bordereauId) async {
    try {
      isLoading = true;

      // Trouver le bordereau
      final bordereau = bordereaux.firstWhere(
        (b) => b.id == bordereauId,
        orElse: () => throw Exception('Bordereau introuvable'),
      );

      // Charger les données nécessaires (timeout long : génération PDF)
      final clients = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final client = clients.firstWhere(
        (c) => c.id == bordereau.clientId,
        orElse: () => throw Exception('Client introuvable pour ce bordereau'),
      );
      final items =
          bordereau.items
              .map(
                (item) => {
                  'reference': item.reference ?? '',
                  'designation': item.designation,
                  'quantite': item.quantite,
                },
              )
              .toList();

      await PdfService().generateBordereauPdf(
        bordereau: {
          'reference': bordereau.reference,
          'titre': bordereau.titre,
          'date_creation': bordereau.dateCreation,
          'montant_ht': bordereau.montantHT,
          'total_ttc': bordereau.montantTTC,
          'date_livraison': bordereau.dateLivraison,
          'garantie': bordereau.garantie,
        },
        items: items,
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise ?? '',
          'email': client.email ?? '',
          'contact': client.contact ?? '',
          'adresse': client.adresse ?? '',
          'numero_contribuable': client.numeroContribuable ?? '',
        },
        commercial: {'nom': 'Commercial', 'prenom': '', 'email': ''},
      );

      errorHelperShowSnackbar?.call(
        'Succès',
        'PDF généré avec succès',
      );
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
      );
    } finally {
      isLoading = false;
    }
  }
}
