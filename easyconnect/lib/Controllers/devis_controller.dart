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
  int? _currentStatus; // Mémoriser le statut actuellement chargé

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;

  // Statistiques
  final totalDevis = 0.obs;
  final devisEnvoyes = 0.obs;
  final devisAcceptes = 0.obs;
  final devisRefuses = 0.obs;
  final tauxConversion = 0.0.obs;
  final montantTotal = 0.0.obs;

  final clients = <Client>[].obs;

  // Référence générée automatiquement
  final generatedReference = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Générer automatiquement la référence au démarrage
    initializeGeneratedReference();
    // Ne pas charger automatiquement les devis - laisser les pages décider quand charger
    // Cela évite les erreurs et ralentissements inutiles
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   loadDevis();
    // });
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
    try {
      AppLogger.info(
        'Chargement des devis: status=$status, forceRefresh=$forceRefresh, page=$page',
        tag: 'DEVIS_CONTROLLER',
      );
      // Si on ne force pas le rafraîchissement et que les données sont déjà chargées avec le même statut, ne rien faire
      // MAIS seulement si on a vraiment des données (pas si la liste est vide)
      // ET seulement si le statut a déjà été défini (pas au premier chargement)
      // ET seulement si c'est la même page
      // IMPORTANT: Toujours charger si la liste est vide, même si le statut correspond
      if (!forceRefresh &&
          devis.isNotEmpty &&
          _currentStatus == status &&
          _currentStatus != null &&
          currentPage.value == page &&
          page == 1) {
        AppLogger.debug(
          'Données déjà chargées, pas de rechargement nécessaire',
          tag: 'DEVIS_CONTROLLER',
        );
        return;
      }

      // Si la liste est vide, forcer le chargement même si le statut correspond
      if (devis.isEmpty && !forceRefresh && _currentStatus == status) {
        AppLogger.debug(
          'Liste vide, forcer le chargement',
          tag: 'DEVIS_CONTROLLER',
        );
        forceRefresh = true;
      }

      _currentStatus = status; // Mémoriser le statut actuel

      // Afficher immédiatement les données du cache si disponibles (seulement page 1)
      final cacheKey = 'devis_${status ?? 'all'}';
      final cachedDevis = CacheHelper.get<List<Devis>>(cacheKey);
      if (cachedDevis != null &&
          cachedDevis.isNotEmpty &&
          !forceRefresh &&
          page == 1) {
        devis.value = cachedDevis;
        isLoading.value = false; // Permettre l'affichage immédiat
        AppLogger.debug(
          'Données chargées depuis le cache: ${cachedDevis.length} devis',
          tag: 'DEVIS_CONTROLLER',
        );
      } else {
        isLoading.value = true;
      }

      // Charger les données avec pagination
      try {
        final paginatedResponse = await _devisService.getDevisPaginated(
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
          devis.value = paginatedResponse.data;
          AppLogger.info(
            'Devis chargés avec succès: ${paginatedResponse.data.length} devis (statut: ${status ?? 'all'})',
            tag: 'DEVIS_CONTROLLER',
          );

          if (paginatedResponse.data.isEmpty) {
            AppLogger.warning(
              'Liste de devis vide après chargement. Total en base: ${paginatedResponse.meta.total}',
              tag: 'DEVIS_CONTROLLER',
            );
          }
        } else {
          devis.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
          AppLogger.debug(
            'Devis mis en cache: ${paginatedResponse.data.length} devis',
            tag: 'DEVIS_CONTROLLER',
          );
        }
      } catch (e, stackTrace) {
        // En cas d'erreur, essayer la méthode non-paginée en fallback
        AppLogger.warning(
          'Erreur avec pagination, tentative avec méthode non-paginée: $e',
          tag: 'DEVIS_CONTROLLER',
        );
        try {
          final loadedDevis = await _devisService.getDevis(
            status: status,
            forceRefresh: forceRefresh,
          );
          AppLogger.info(
            'Devis chargés via méthode fallback: ${loadedDevis.length} devis (statut: ${status ?? 'all'})',
            tag: 'DEVIS_CONTROLLER',
          );
          if (page == 1) {
            devis.value = loadedDevis;
          } else {
            devis.addAll(loadedDevis);
          }
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedDevis);
            AppLogger.debug(
              'Devis mis en cache via fallback: ${loadedDevis.length} devis',
              tag: 'DEVIS_CONTROLLER',
            );
          }
        } catch (fallbackError) {
          // Si le fallback échoue aussi, vérifier le cache
          if (cachedDevis == null || cachedDevis.isEmpty || page > 1) {
            if (devis.isEmpty) {
              final cacheKey = 'devis_${status ?? 'all'}';
              final cachedDevis = CacheHelper.get<List<Devis>>(cacheKey);
              if (cachedDevis != null && cachedDevis.isNotEmpty) {
                devis.value = cachedDevis;
                return; // Ne pas afficher d'erreur si on a du cache
              }
            }
            rethrow; // Relancer l'erreur seulement si on n'avait pas de cache
          }
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
          'Erreur lors du chargement des devis: $e',
          tag: 'DEVIS_CONTROLLER',
          error: e,
          stackTrace: stackTrace,
        );
        // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
        if (devis.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'devis_${status ?? 'all'}';
          final cachedDevis = CacheHelper.get<List<Devis>>(cacheKey);
          if (cachedDevis == null || cachedDevis.isEmpty) {
            // Toujours afficher l'erreur si la liste est vide et qu'il n'y a pas de cache
            Get.snackbar(
              'Erreur',
              'Impossible de charger les devis: ${e.toString().replaceFirst('Exception: ', '')}',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white,
              duration: const Duration(seconds: 5),
            );
            AppLogger.error(
              'Aucun devis chargé et aucun cache disponible',
              tag: 'DEVIS_CONTROLLER',
            );
          } else {
            // Charger les données du cache si disponibles
            devis.value = cachedDevis;
            AppLogger.info(
              'Données chargées depuis le cache après erreur: ${cachedDevis.length} devis',
              tag: 'DEVIS_CONTROLLER',
            );
          }
        } else {
          // Si on a des données mais qu'il y a eu une erreur, afficher un avertissement
          Get.snackbar(
            'Avertissement',
            'Erreur lors de la mise à jour des devis. Données en cache affichées.',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 3),
          );
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage.value && !isLoading.value) {
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
    try {
      isLoading.value = true;

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
      );

      final createdDevis = await _devisService.createDevis(newDevis);

      // Invalider le cache
      CacheHelper.clearByPrefix('devis_');

      // Ajouter le devis à la liste localement (mise à jour optimiste)
      // Le nouveau devis a toujours le statut 1 (en attente)
      if (createdDevis.id != null) {
        // Ajouter en début de liste pour qu'il apparaisse en premier
        devis.insert(0, createdDevis);
        AppLogger.info(
          'Devis ajouté à la liste: ${createdDevis.reference} (ID: ${createdDevis.id})',
          tag: 'DEVIS_CONTROLLER',
        );
      }

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('devis');

      // Notifier le patron de la soumission
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

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Devis créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Effacer le formulaire
      clearForm();

      // Recharger la liste avec le statut actuel pour synchroniser avec le serveur
      // IMPORTANT: Recharger en arrière-plan après un court délai pour laisser le temps au serveur
      // de traiter la création, mais garder le devis dans la liste immédiatement
      Future.delayed(const Duration(milliseconds: 500), () async {
        try {
          // Recharger avec le statut 1 (en attente) car le nouveau devis a ce statut
          // Cela garantit que le devis apparaîtra dans l'onglet "En attente"
          await loadDevis(
            status: 1, // Le nouveau devis est toujours en attente
            forceRefresh: true,
          );

          // Vérifier que le devis créé est toujours dans la liste après rechargement
          if (createdDevis.id != null) {
            final devisExists = devis.any((d) => d.id == createdDevis.id);
            if (!devisExists) {
              // Si le devis n'est pas dans la liste après rechargement, le rajouter
              AppLogger.warning(
                'Devis créé non trouvé après rechargement, réajout à la liste',
                tag: 'DEVIS_CONTROLLER',
              );
              devis.insert(0, createdDevis);
            }
          }

          AppLogger.info(
            'Liste rechargée après création du devis',
            tag: 'DEVIS_CONTROLLER',
          );
        } catch (e) {
          // Si le rechargement échoue, le devis reste dans la liste grâce à la mise à jour optimiste
          AppLogger.warning(
            'Erreur lors du rechargement après création: $e',
            tag: 'DEVIS_CONTROLLER',
          );
          // Ne pas afficher d'erreur car le devis a été créé avec succès et est déjà dans la liste
        }
      });

      return true;
    } catch (e, stackTrace) {
      Get.snackbar(
        'Erreur',
        'Impossible de créer le devis: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateDevis(int devisId, Map<String, dynamic> data) async {
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
        );

        // Si on est sur l'onglet "En attente" (status = 1), retirer le devis de la liste
        // car il n'est plus en attente
        if (_currentStatus == 1) {
          devis.removeAt(devisIndex);
        } else {
          // Sinon (onglet "Tous" ou autres), mettre à jour le statut dans la liste
          // pour que le changement soit visible immédiatement
          devis[devisIndex] = updatedDevis;
        }
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

          // Si on était sur l'onglet "Tous" (status = null), recharger aussi les autres onglets
          // pour s'assurer que le devis validé apparaît partout avec le bon statut
          if (_currentStatus == null) {
            // Recharger aussi l'onglet "Validés" pour que le devis validé apparaisse
            Future.delayed(const Duration(milliseconds: 300), () {
              loadDevis(status: 2, forceRefresh: true).catchError((e) {
                AppLogger.error(
                  'Erreur lors du rechargement des devis validés: $e',
                  tag: 'DEVIS_CONTROLLER',
                );
              });
            });
          }
          // Si on était sur l'onglet "En attente", recharger aussi l'onglet "Validés"
          // pour que le devis validé apparaisse
          else if (_currentStatus == 1) {
            Future.delayed(const Duration(milliseconds: 300), () {
              loadDevis(status: 2, forceRefresh: true).catchError((e) {
                AppLogger.error(
                  'Erreur lors du rechargement des devis validés: $e',
                  tag: 'DEVIS_CONTROLLER',
                );
              });
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
      // En cas d'erreur, restaurer l'état si nécessaire
      // Ne pas afficher d'erreur si c'est juste un problème de parsing
      final errorStr = e.toString().toLowerCase();
      if (!errorStr.contains('401') &&
          !errorStr.contains('403') &&
          !errorStr.contains('unauthorized') &&
          !errorStr.contains('forbidden')) {
        Get.snackbar(
          'Attention',
          'La validation peut avoir réussi. Veuillez vérifier.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
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
      // En cas d'erreur, restaurer l'état si nécessaire
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le devis: ${e.toString().replaceAll('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

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

  // Sélection du client
  Future<void> searchClients(String query) async {
    try {
      final clientsList = await _clientService.getClients();
      final validatedClients =
          clientsList.where((client) => client.status == 1).toList();

      if (query.isNotEmpty) {
        clients.value =
            validatedClients.where((client) {
              final nom = client.nom?.toLowerCase() ?? '';
              final email = client.email?.toLowerCase() ?? '';
              final searchQuery = query.toLowerCase();
              return nom.contains(searchQuery) || email.contains(searchQuery);
            }).toList();
      } else {
        clients.value = validatedClients;
      }
    } catch (e) {}
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

      // Charger les données nécessaires
      final clients = await _clientService.getClients();
      final client = clients.firstWhere(
        (c) => c.id == selectedDevis.clientId,
        orElse: () => throw Exception('Client introuvable pour ce devis'),
      );
      final items =
          selectedDevis.items
              .map(
                (item) => {
                  'designation':
                      (item.designation.isNotEmpty
                          ? item.designation
                          : 'Article sans désignation'),
                  'unite': 'unité',
                  'quantite': item.quantite,
                  'prix_unitaire': item.prixUnitaire,
                  'montant_total': (item.total.isFinite ? item.total : 0.0),
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
        },
        items: items,
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise ?? '',
          'email': client.email ?? '',
          'contact': client.contact ?? '',
          'adresse': client.adresse ?? '',
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
