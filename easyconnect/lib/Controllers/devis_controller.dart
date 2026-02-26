import 'dart:async';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

class DevisController extends GetxController {
  int userId = int.parse(
    Get.find<AuthController>().userAuth.value!.id.toString(),
  );

  final DevisService _devisService = DevisService();
  final ClientService _clientService = ClientService();

  final devis = <Devis>[].obs;
  final selectedClient = Rxn<Client>();
  final isLoading = false.obs;
  final currentDevis = Rxn<Devis>();
  final items = <DevisItem>[].obs;
  final RxBool isLoadingMore = false.obs;
  int? _currentStatus; // Mémoriser le statut actuellement chargé

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;
  bool _isLoadingInProgress = false;
  Timer? _searchDebounceTimer;

  // Statistiques
  final totalDevis = 0.obs;
  final devisEnvoyes = 0.obs;
  final devisAcceptes = 0.obs;
  final devisRefuses = 0.obs;
  final tauxConversion = 0.0.obs;
  final montantTotal = 0.0.obs;

  final clients = <Client>[].obs;
  final isLoadingClients = false.obs;

  // Référence générée automatiquement
  final generatedReference = ''.obs;

  @override
  void onInit() {
    super.onInit();
    initializeGeneratedReference();
    ever(searchQuery, (_) {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        AppLogger.debug(
          'Devis recherche (debounce): rechargement statut=$_currentStatus, query="${searchQuery.value}"',
          tag: 'DEVIS_CONTROLLER',
        );
        loadDevis(status: _currentStatus, forceRefresh: true);
      });
    });
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    super.onClose();
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
        Get.snackbar(
          'Debug Devis',
          'Total: ${stats['total_devis']}, Par statut: ${stats['devis_by_status']}, Par user: ${stats['devis_by_user']}',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    } catch (e) {
      AppLogger.error('Erreur lors du debug: $e', tag: 'DEVIS_CONTROLLER');
      Get.snackbar(
        'Erreur Debug',
        'Impossible de récupérer les informations de debug: $e',
        snackPosition: SnackPosition.BOTTOM,
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
      AppLogger.debug('Chargement déjà en cours, ignore', tag: 'DEVIS_CONTROLLER');
      return;
    }
    if (!forceRefresh &&
        devis.isNotEmpty &&
        _currentStatus == status &&
        currentPage.value == page &&
        page == 1) {
      AppLogger.debug('Données déjà chargées', tag: 'DEVIS_CONTROLLER');
      return;
    }
    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'devis_${status ?? 'all'}';

    if (page == 1) {
      isLoading.value = true;
      final cachedData = DevisService.getCachedDevis(status);
      if (cachedData.isNotEmpty) {
        devis.assignAll(cachedData);
        isLoading.value = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} devis → affichage instantané',
          tag: 'DEVIS_CONTROLLER',
        );
      } else {
        devis.value = [];
      }
    } else {
      isLoadingMore.value = true;
    }

    try {
      final response = await _devisService.getDevisPaginated(
        status: status,
        page: page,
        perPage: perPage.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug('[API] onglet changé, mise à jour ignorée', tag: 'DEVIS_CONTROLLER');
        return;
      }

      if (page == 1) {
        devis.assignAll(response.data);
        CacheHelper.set(entityKey, response.data);
        DevisService.saveDevisToHive(response.data, status);
        currentPage.value = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} devis, Hive mis à jour',
          tag: 'DEVIS_CONTROLLER',
        );
      } else {
        devis.addAll(response.data);
      }

      totalPages.value = response.meta.lastPage;
      totalItems.value = response.meta.total;
      hasNextPage.value = response.hasNextPage;
      hasPreviousPage.value = response.hasPreviousPage;
      if (page > 1) currentPage.value = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Devis: $e', tag: 'DEVIS_CONTROLLER');
      if (devis.isEmpty) {
        final fallback = DevisService.getCachedDevis(status);
        if (fallback.isNotEmpty) {
          devis.assignAll(fallback);
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les devis',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white,
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

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadDevis(status: _currentStatus, page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadDevis(status: _currentStatus, page: currentPage.value - 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _devisService.getDevisStats();
      totalDevis.value = stats['total'] ?? 0;
      devisEnvoyes.value = stats['envoyes'] ?? 0;
      devisAcceptes.value = stats['acceptes'] ?? 0;
      devisRefuses.value = stats['refuses'] ?? 0;
      tauxConversion.value = stats['taux_conversion'] ?? 0.0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {}
  }

  Future<bool> createDevis(Map<String, dynamic> data) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;

      // Validation des données avant création
      if (selectedClient.value == null || selectedClient.value!.id == null) {
        AppLogger.error(
          'Client non sélectionné ou ID manquant',
          tag: 'DEVIS_CONTROLLER',
        );
        Get.snackbar(
          'Erreur',
          'Veuillez sélectionner un client valide',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      if (items.isEmpty) {
        AppLogger.error('Aucun article dans le devis', tag: 'DEVIS_CONTROLLER');
        Get.snackbar(
          'Erreur',
          'Veuillez ajouter au moins un article',
          snackPosition: SnackPosition.BOTTOM,
        );
        return false;
      }

      AppLogger.info(
        'Création du devis avec référence: ${data['reference']}',
        tag: 'DEVIS_CONTROLLER',
      );

      final newDevis = Devis(
        clientId: selectedClient.value!.id!,
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
      final shouldInsert = _currentStatus == null || _currentStatus == newDevisStatus;
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
          devis.refresh();
          final fullList = devis.toList();
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

      Get.snackbar(
        'Succès',
        'Devis créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

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

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );

      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDevis(int devisId, Map<String, dynamic> data) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;
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

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Devis mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadDevis();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le devis a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteDevis(int devisId) async {
    try {
      isLoading.value = true;
      final success = await _devisService.deleteDevis(devisId);
      if (success) {
        devis.removeWhere((d) => d.id == devisId);
        Get.snackbar(
          'Succès',
          'Devis supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendDevis(int devisId) async {
    try {
      isLoading.value = true;
      final success = await _devisService.sendDevis(devisId);
      if (success) {
        await loadDevis();
        Get.snackbar(
          'Succès',
          'Devis envoyé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de l\'envoi');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible d\'envoyer le devis',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> acceptDevis(int devisId) async {
    try {
      isLoading.value = true;

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

        // Forcer la mise à jour de la liste observable pour que tous les onglets se rafraîchissent
        devis.refresh();

        AppLogger.info(
          'Devis ${devisId} mis à jour avec statut 2 (Validé) dans la liste',
          tag: 'DEVIS_CONTROLLER',
        );
      }

      // Appel API
      final success = await _devisService.acceptDevis(devisId);

      if (success) {
        // Invalider le cache après succès
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');

        // Afficher le message de succès immédiatement
        Get.snackbar(
          'Succès',
          'Devis accepté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Rafraîchir les compteurs et notifier en arrière-plan (non-bloquant)
        Future.microtask(() {
          DashboardRefreshHelper.refreshPatronCounter('devis');

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
          // Recharger l'onglet actuel avec forceRefresh pour s'assurer que les données sont à jour
          loadDevis(status: _currentStatus, forceRefresh: true).catchError((e) {
            AppLogger.error(
              'Erreur lors du rechargement après validation: $e',
              tag: 'DEVIS_CONTROLLER',
            );
          });

          // Recharger tous les onglets pour que le changement de statut soit visible partout
          // Onglet "En attente" (status = 1) - pour retirer le devis validé
          if (_currentStatus != 1) {
            loadDevis(status: 1, forceRefresh: true).catchError((e) {
              AppLogger.debug(
                'Erreur lors du rechargement de l\'onglet En attente: $e',
                tag: 'DEVIS_CONTROLLER',
              );
            });
          }

          // Onglet "Validés" (status = 2) - pour ajouter le devis validé
          if (_currentStatus != 2) {
            loadDevis(status: 2, forceRefresh: true).catchError((e) {
              AppLogger.debug(
                'Erreur lors du rechargement de l\'onglet Validés: $e',
                tag: 'DEVIS_CONTROLLER',
              );
            });
          }

          // Onglet "Rejetés" (status = 3) - pour s'assurer qu'il n'y a pas de confusion
          if (_currentStatus != 3) {
            loadDevis(status: 3, forceRefresh: true).catchError((e) {
              AppLogger.debug(
                'Erreur lors du rechargement de l\'onglet Rejetés: $e',
                tag: 'DEVIS_CONTROLLER',
              );
            });
          }
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
        loadDevis().catchError((e) {});
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
      isLoading.value = false;
    }
  }

  Future<void> rejectDevis(int devisId, String commentaire) async {
    try {
      isLoading.value = true;

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
        // Invalider le cache après succès
        CacheHelper.clearByPrefix('devis_');
        CacheHelper.clearByPrefix('dashboard_');

        // Afficher le message de succès immédiatement
        Get.snackbar(
          'Succès',
          'Devis rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 2),
        );

        // Rafraîchir les compteurs et notifier en arrière-plan (non-bloquant)
        Future.microtask(() {
          DashboardRefreshHelper.refreshPatronCounter('devis');

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
        Get.snackbar(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
          snackPosition: SnackPosition.BOTTOM,
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
      isLoading.value = false;
    }
  }

  // Gestion des items
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

  /// Charge les clients validés : cache Hive d'abord (affichage immédiat), puis API.
  /// À appeler à l'entrée du formulaire devis pour avoir la liste prête au premier clic.
  Future<void> loadValidatedClients() async {
    isLoadingClients.value = true;
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      clients.assignAll(cached);
      isLoadingClients.value = false;
    } else {
      clients.value = [];
    }
    try {
      final clientsList = await _clientService.getClients(status: 1);
      final validatedClients = clientsList.where((c) => c.status == 1).toList();
      clients.assignAll(validatedClients);
    } catch (e) {
      if (clients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          clients.assignAll(fallback);
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les clients validés',
            snackPosition: SnackPosition.BOTTOM,
          );
        }
      }
    } finally {
      isLoadingClients.value = false;
    }
  }

  // Sélection du client (validés uniquement) : filtre sur la liste déjà chargée ou charge si vide.
  Future<void> searchClients(String query) async {
    if (query.isEmpty) {
      await loadValidatedClients();
      return;
    }
    final cached = ClientService.getCachedClients(1);
    List<Client> validated = cached.isNotEmpty ? List.from(cached) : clients.toList();
    if (validated.isEmpty) {
      await loadValidatedClients();
      validated = clients.toList();
    }
    final filtered = validated.where((client) {
      final nom = client.nom?.toLowerCase() ?? '';
      final email = client.email?.toLowerCase() ?? '';
      final q = query.toLowerCase();
      return nom.contains(q) || email.contains(q);
    }).toList();
    clients.value = filtered;
  }

  void selectClient(Client client) {
    selectedClient.value = client;
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Générer automatiquement la référence du devis
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

  /// Initialiser la référence générée
  Future<void> initializeGeneratedReference() async {
    if (generatedReference.value.isEmpty) {
      generatedReference.value = await generateReference();
    }
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    items.clear();
    generatedReference.value = '';
    // Régénérer un nouveau numéro de référence
    initializeGeneratedReference();
  }

  /// Générer un PDF pour un devis
  Future<void> generatePDF(int devisId) async {
    try {
      isLoading.value = true;

      // Trouver le devis
      final selectedDevis = devis.firstWhere(
        (d) => d.id == devisId,
        orElse: () => throw Exception('Devis introuvable'),
      );

      // Charger les données nécessaires (timeout long : génération PDF peut être lente)
      final clients = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final client = clients.firstWhere(
        (c) => c.id == selectedDevis.clientId,
        orElse: () => throw Exception('Client introuvable pour ce devis'),
      );
      final items =
          selectedDevis.items
              .map(
                (item) => {
                  'reference': item.reference ?? '',
                  'designation':
                      (item.designation.isNotEmpty
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

      // Générer le PDF
      await PdfService().generateDevisPdf(
        devis: {
          'reference':
              (selectedDevis.reference.isNotEmpty
                  ? selectedDevis.reference
                  : 'N/A'),
          'date_creation': selectedDevis.dateCreation,
          'montant_ht':
              (selectedDevis.totalHT.isFinite ? selectedDevis.totalHT : 0.0),
          'tva': selectedDevis.tva ?? 0.0, // tva peut être null
          'total_ttc':
              (selectedDevis.totalTTC.isFinite ? selectedDevis.totalTTC : 0.0),
          'titre': selectedDevis.titre,
          'delai_livraison': selectedDevis.delaiLivraison,
          'garantie': selectedDevis.garantie,
          'conditions': selectedDevis.conditions, // Ajouter les conditions
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

      Get.snackbar(
        'Succès',
        'PDF généré avec succès',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la génération du PDF: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
