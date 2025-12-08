import 'package:get/get.dart';
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

class BordereauxController extends GetxController {
  late int userId;
  final BordereauService _bordereauService = BordereauService();
  final ClientService _clientService = ClientService();
  final DevisService _devisService = DevisService();

  final bordereaux = <Bordereau>[].obs;
  final selectedClient = Rxn<Client>();
  final availableClients = <Client>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final currentBordereau = Rxn<Bordereau>();
  final items = <BordereauItem>[].obs;

  // Variables pour la gestion des devis
  final availableDevis = <Devis>[].obs;
  final selectedDevis = Rxn<Devis>();
  final isLoadingDevis = false.obs;

  // Référence générée automatiquement
  final generatedReference = ''.obs;

  // Mémoriser le statut actuellement chargé
  int? _currentStatus;

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;

  // Statistiques
  final totalBordereaux = 0.obs;
  final bordereauEnvoyes = 0.obs;
  final bordereauAcceptes = 0.obs;
  final bordereauRefuses = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    // Cela évite les erreurs et ralentissements inutiles
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   loadBordereaux();
    // });
  }

  Future<void> loadBordereaux({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    try {
      // Si on ne force pas le rafraîchissement et que les données sont déjà chargées avec le même statut, ne rien faire
      // MAIS seulement si on a vraiment des données (pas si la liste est vide)
      // ET seulement si le statut a déjà été défini (pas au premier chargement)
      // ET seulement si c'est la même page
      if (!forceRefresh &&
          bordereaux.isNotEmpty &&
          _currentStatus == status &&
          _currentStatus != null &&
          currentPage.value == page &&
          page == 1) {
        AppLogger.debug(
          'Données déjà chargées, pas de rechargement nécessaire',
          tag: 'BORDEREAU_CONTROLLER',
        );
        return;
      }

      _currentStatus = status; // Mémoriser le statut actuel

      // Afficher immédiatement les données du cache si disponibles (seulement page 1)
      final cacheKey = 'bordereaux_${status ?? 'all'}';
      final cachedBordereaux = CacheHelper.get<List<Bordereau>>(cacheKey);
      if (cachedBordereaux != null &&
          cachedBordereaux.isNotEmpty &&
          !forceRefresh &&
          page == 1) {
        bordereaux.value = cachedBordereaux;
        isLoading.value = false; // Permettre l'affichage immédiat
        AppLogger.debug(
          'Données chargées depuis le cache: ${cachedBordereaux.length} bordereaux',
          tag: 'BORDEREAU_CONTROLLER',
        );
      } else {
        isLoading.value = true;
      }

      // Charger les données avec pagination
      try {
        final paginatedResponse = await _bordereauService
            .getBordereauxPaginated(
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
          bordereaux.value = paginatedResponse.data;
        } else {
          bordereaux.addAll(paginatedResponse.data);
        }

        // Sauvegarder dans le cache (seulement pour la page 1)
        if (page == 1) {
          CacheHelper.set(cacheKey, paginatedResponse.data);
        }
      } catch (e) {
        try {
          final loadedBordereaux = await _bordereauService.getBordereaux(
            status: status,
          );
          if (page == 1) {
            bordereaux.value = loadedBordereaux;
          } else {
            bordereaux.addAll(loadedBordereaux);
          }
          if (page == 1) {
            CacheHelper.set(cacheKey, loadedBordereaux);
          }
        } catch (fallbackError) {
          // Si le fallback échoue aussi, vérifier le cache
          if (cachedBordereaux == null ||
              cachedBordereaux.isEmpty ||
              page > 1) {
            if (bordereaux.isEmpty) {
              final cacheKey = 'bordereaux_${status ?? 'all'}';
              final cachedBordereaux = CacheHelper.get<List<Bordereau>>(
                cacheKey,
              );
              if (cachedBordereaux != null && cachedBordereaux.isNotEmpty) {
                bordereaux.value = cachedBordereaux;
                return; // Ne pas afficher d'erreur si on a du cache
              }
            }
            rethrow; // Relancer l'erreur seulement si on n'avait pas de cache
          }
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des bordereaux: $e',
        tag: 'BORDEREAU_CONTROLLER',
      );

      // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
      // Ne pas afficher d'erreur pour les erreurs d'authentification (déjà gérées)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        if (bordereaux.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'bordereaux_${status ?? 'all'}';
          final cachedBordereaux = CacheHelper.get<List<Bordereau>>(cacheKey);
          if (cachedBordereaux == null || cachedBordereaux.isEmpty) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les bordereaux',
              snackPosition: SnackPosition.BOTTOM,
            );
          } else {
            // Charger les données du cache si disponibles
            bordereaux.value = cachedBordereaux;
          }
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bordereauService.getBordereauStats();
      totalBordereaux.value = stats['total'] ?? 0;
      bordereauEnvoyes.value = stats['envoyes'] ?? 0;
      bordereauAcceptes.value = stats['acceptes'] ?? 0;
      bordereauRefuses.value = stats['refuses'] ?? 0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {}
  }

  Future<bool> createBordereau(Map<String, dynamic> data) async {
    print('🔵 [BORDEREAU] Début de createBordereau');
    try {
      // Vérifications
      if (selectedClient.value == null) {
        print('❌ [BORDEREAU] Erreur: Aucun client sélectionné');
        throw Exception('Aucun client sélectionné');
      }
      if (items.isEmpty) {
        print('❌ [BORDEREAU] Erreur: Aucun article ajouté');
        throw Exception('Aucun article ajouté au bordereau');
      }

      print('✅ [BORDEREAU] Validations OK, démarrage du chargement');
      isLoading.value = true;

      // Utiliser la référence générée si un devis est sélectionné, sinon utiliser celle fournie
      final reference =
          selectedDevis.value != null && generatedReference.value.isNotEmpty
              ? generatedReference.value
              : data['reference'];

      final newBordereau = Bordereau(
        clientId: selectedClient.value!.id!,
        devisId: selectedDevis.value?.id,
        reference: reference,
        dateCreation: DateTime.now(),
        notes: data['notes'],
        status: 1, // Forcer le statut à 1 (En attente)
        items: items.toList(), // Convertir en liste
        commercialId: userId,
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

      // Invalider le cache
      CacheHelper.clearByPrefix('bordereaux_');

      // Ajouter le bordereau à la liste localement (mise à jour optimiste)
      // Le nouveau bordereau a toujours le statut 1 (En attente)
      print(
        '📋 [BORDEREAU] Ajout du bordereau à la liste (avant: ${bordereaux.length} éléments)',
      );
      bordereaux.insert(0, createdBordereau);
      print(
        '📋 [BORDEREAU] Bordereau ajouté à la liste (après: ${bordereaux.length} éléments)',
      );

      AppLogger.info(
        'Bordereau ajouté à la liste: ${createdBordereau.reference} (ID: ${createdBordereau.id})',
        tag: 'BORDEREAU_CONTROLLER',
      );

      // Arrêter le loader immédiatement pour permettre la fermeture du formulaire
      print('⏸️ [BORDEREAU] Arrêt du loader');
      isLoading.value = false;

      // Rafraîchir les compteurs du dashboard patron en arrière-plan
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter('bordereau');
      });

      // Effacer le formulaire avant d'afficher le message de succès
      print('🧹 [BORDEREAU] Effacement du formulaire');
      clearForm();

      // Afficher le message de succès (après avoir effacé le formulaire pour éviter les conflits)
      print('✅ [BORDEREAU] Affichage du message de succès');
      Get.snackbar(
        'Succès',
        'Bordereau créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Recharger la liste en arrière-plan après un court délai pour synchroniser avec le serveur
      // Le bordereau est déjà dans la liste, donc il restera visible même si le rechargement échoue
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          // Recharger avec le statut actuel pour synchroniser avec le serveur
          await loadBordereaux(status: _currentStatus, forceRefresh: true);

          // Vérifier que le bordereau créé est toujours dans la liste après rechargement
          print(
            '🔄 [BORDEREAU] Vérification après rechargement - Liste contient ${bordereaux.length} éléments',
          );
          if (createdBordereau.id != null) {
            final bordereauExists = bordereaux.any(
              (b) => b.id == createdBordereau.id,
            );
            print(
              '🔍 [BORDEREAU] Bordereau ID ${createdBordereau.id} existe dans la liste: $bordereauExists',
            );
            if (!bordereauExists) {
              // Si le bordereau n'est pas dans la liste après rechargement, le rajouter
              print(
                '⚠️ [BORDEREAU] Bordereau non trouvé après rechargement, réajout...',
              );
              AppLogger.warning(
                'Bordereau créé non trouvé après rechargement, réajout à la liste',
                tag: 'BORDEREAU_CONTROLLER',
              );
              bordereaux.insert(0, createdBordereau);
              print(
                '✅ [BORDEREAU] Bordereau réajouté - Liste contient maintenant ${bordereaux.length} éléments',
              );
            }
          }

          print('✅ [BORDEREAU] Liste rechargée avec succès');
          AppLogger.info(
            'Liste rechargée après création du bordereau',
            tag: 'BORDEREAU_CONTROLLER',
          );
        } catch (e) {
          // Si le rechargement échoue, le bordereau reste dans la liste grâce à la mise à jour optimiste
          print('⚠️ [BORDEREAU] Erreur lors du rechargement (ignorée): $e');
          print(
            '⚠️ [BORDEREAU] Liste actuelle contient ${bordereaux.length} éléments',
          );
          AppLogger.warning(
            'Erreur lors du rechargement après création: $e',
            tag: 'BORDEREAU_CONTROLLER',
          );
          // Ne pas afficher d'erreur car le bordereau a été créé avec succès et est déjà dans la liste
        }
      });

      print('✅ [BORDEREAU] Retour de createBordereau: true (SUCCÈS)');
      return true;
    } catch (e, stackTrace) {
      print('❌ [BORDEREAU] ERREUR CAPTURÉE dans createBordereau: $e');
      print('❌ [BORDEREAU] Stack trace: $stackTrace');

      // S'assurer que le loader est arrêté en cas d'erreur
      isLoading.value = false;

      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      print('❌ [BORDEREAU] Affichage du message d\'erreur: $errorMessage');
      AppLogger.error(
        'Erreur lors de la création du bordereau: $e',
        tag: 'BORDEREAU_CONTROLLER',
        error: e,
      );

      Get.snackbar(
        'Erreur',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 8),
        maxWidth: 400,
        isDismissible: true,
        shouldIconPulse: true,
      );
      print('❌ [BORDEREAU] Retour de createBordereau: false (ÉCHEC)');
      return false;
    }
  }

  Future<bool> updateBordereau(
    int bordereauId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      final bordereauToUpdate = bordereaux.firstWhere(
        (b) => b.id == bordereauId,
      );
      final updatedBordereau = Bordereau(
        id: bordereauId,
        clientId: bordereauToUpdate.clientId,
        reference: data['reference'] ?? bordereauToUpdate.reference,
        dateCreation: bordereauToUpdate.dateCreation,
        notes: data['notes'] ?? bordereauToUpdate.notes,
        status: bordereauToUpdate.status,
        items: items.isEmpty ? bordereauToUpdate.items : items,
        commercialId: bordereauToUpdate.commercialId,
      );

      await _bordereauService.updateBordereau(updatedBordereau);

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bordereau mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
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
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBordereau(int bordereauId) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.deleteBordereau(bordereauId);
      if (success) {
        bordereaux.removeWhere((b) => b.id == bordereauId);
        Get.snackbar(
          'Succès',
          'Bordereau supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitBordereau(int bordereauId) async {
    try {
      isLoading.value = true;
      final success = await _bordereauService.submitBordereau(bordereauId);
      if (success) {
        await loadBordereaux();

        // Notifier de manière asynchrone (non-bloquant)
        final bordereau = bordereaux.firstWhereOrNull(
          (b) => b.id == bordereauId,
        );
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

        Get.snackbar(
          'Succès',
          'Bordereau soumis avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre le bordereau',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBordereau(int bordereauId) async {
    bool validationSucceeded = false;
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bordereaux_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement le statut
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

          // Rafraîchir les compteurs du dashboard patron
          DashboardRefreshHelper.refreshPatronCounter('bordereau');

          // Notifier de manière asynchrone (non-bloquant)
          final bordereau = bordereaux.firstWhereOrNull(
            (b) => b.id == bordereauId,
          );
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
            );
          }

          Get.snackbar(
            'Succès',
            'Bordereau approuvé avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.green,
            colorText: Colors.white,
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
      // Ne pas afficher le message d'erreur si la validation a réussi
      // (les erreurs peuvent venir des opérations asynchrones comme les notifications)
      if (!validationSucceeded) {
        Get.snackbar(
          'Erreur',
          'Impossible d\'approuver le bordereau: $e',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBordereau(int bordereauId, String commentaire) async {
    try {
      isLoading.value = true;
      try {
        final success = await _bordereauService.rejectBordereau(
          bordereauId,
          commentaire,
        );

        if (success) {
          await loadBordereaux();

          // Rafraîchir les compteurs du dashboard patron
          DashboardRefreshHelper.refreshPatronCounter('bordereau');

          // Notifier de manière asynchrone (non-bloquant)
          final bordereau = bordereaux.firstWhereOrNull(
            (b) => b.id == bordereauId,
          );
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
            );
          }

          Get.snackbar(
            'Succès',
            'Bordereau rejeté avec succès',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
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
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bordereau: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
      );
    } finally {
      isLoading.value = false;
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

  // Chargement des clients validés
  Future<void> loadValidatedClients() async {
    try {
      isLoadingClients.value = true;
      final clients = await _clientService.getClients(
        status: 1,
      ); // Status 1 = Validé
      availableClients.value = clients;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les clients validés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingClients.value = false;
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
    selectedClient.value = client;
    // Charger les devis validés pour ce client
    onClientChanged(client);
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    selectedDevis.value = null;
    availableDevis.clear();
    items.clear();
  }

  // Chargement des devis validés pour le client sélectionné
  Future<void> loadValidatedDevisForClient(int clientId) async {
    try {
      isLoadingDevis.value = true;
      final devis = await _devisService.getDevis();

      // Filtrer par client et statut côté client
      final devisForClient =
          devis.where((d) => d.clientId == clientId && d.status == 2).toList();
      availableDevis.value = devisForClient;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de charger les devis validés',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoadingDevis.value = false;
    }
  }

  // Générer automatiquement la référence du bordereau basée sur le devis
  Future<String> generateBordereauReference(int? devisId) async {
    if (devisId == null) {
      // Si pas de devis, générer une référence par défaut
      return 'BL-${DateTime.now().millisecondsSinceEpoch}';
    }

    // Trouver le devis sélectionné
    final devis = selectedDevis.value;
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
    selectedDevis.value = devis;

    // Générer automatiquement la référence
    final ref = await generateBordereauReference(devis.id);
    generatedReference.value = ref;
    print('📋 [BORDEREAU] Référence générée: $ref');

    // Pré-remplir les items du bordereau avec les items du devis (sans les prix)
    items.clear();
    for (final devisItem in devis.items) {
      final bordereauItem = BordereauItem(
        designation: devisItem.designation,
        unite: 'unité', // Valeur par défaut
        quantite: devisItem.quantite,
        description: 'Basé sur le devis ${devis.reference}',
      );
      items.add(bordereauItem);
    }
  }

  // Effacer la sélection du devis
  void clearSelectedDevis() {
    selectedDevis.value = null;
    generatedReference.value = '';
    items.clear();
  }

  // Recharger les devis quand le client change
  void onClientChanged(Client? client) {
    if (client != null) {
      loadValidatedDevisForClient(client.id!);
    } else {
      availableDevis.clear();
      selectedDevis.value = null;
      items.clear();
    }
  }

  /// Générer un PDF pour un bordereau
  Future<void> generatePDF(int bordereauId) async {
    try {
      isLoading.value = true;

      // Trouver le bordereau
      final bordereau = bordereaux.firstWhere(
        (b) => b.id == bordereauId,
        orElse: () => throw Exception('Bordereau introuvable'),
      );

      // Charger les données nécessaires
      final clients = await _clientService.getClients();
      final client = clients.firstWhere(
        (c) => c.id == bordereau.clientId,
        orElse: () => throw Exception('Client introuvable pour ce bordereau'),
      );
      final items =
          bordereau.items
              .map(
                (item) => {
                  'designation': item.designation,
                  'unite': item.unite,
                  'quantite': item.quantite,
                  'montant_total': item.montantTotal,
                },
              )
              .toList();

      // Générer le PDF
      await PdfService().generateBordereauPdf(
        bordereau: {
          'reference': bordereau.reference,
          'date_creation': bordereau.dateCreation,
          'montant_ht': bordereau.montantHT,
          'total_ttc': bordereau.montantTTC,
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
