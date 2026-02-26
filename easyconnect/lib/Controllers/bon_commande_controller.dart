import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_commande_model.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/services/camera_service.dart';
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/utils/error_helper.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/app_config.dart';

class BonCommandeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late int userId;
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ClientService _clientService = ClientService();

  final bonCommandes = <BonCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final availableClients = <Client>[].obs;
  final isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;
  final isLoadingClients = false.obs;
  final currentBonCommande = Rxn<BonCommande>();
  int? _currentStatus;
  bool _isLoadingInProgress = false;

  // Fichiers scannés (liste de chemins locaux)
  final selectedFiles = <Map<String, dynamic>>[].obs;

  // Gestion des onglets
  late TabController tabController;
  final selectedStatus = Rxn<int>();

  // Métadonnées de pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 15.obs;
  final RxString searchQuery = ''.obs;
  final ScrollController scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  // Statistiques
  final totalBonCommandes = 0.obs;
  final bonCommandesEnvoyes = 0.obs;
  final bonCommandesAcceptes = 0.obs;
  final bonCommandesRefuses = 0.obs;
  final bonCommandesLivres = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);
    ever(searchQuery, (_) {
      _searchDebounceTimer?.cancel();
      _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        loadBonCommandes(status: _currentStatus, forceRefresh: true);
      });
    });
  }

  // Sélectionner des fichiers (scan ou sélection)
  Future<void> selectFiles() async {
    try {
      // Proposer de choisir le type de sélection
      final String? selectionType = await Get.dialog<String>(
        AlertDialog(
          title: const Text('Sélectionner des fichiers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Get.back(result: 'file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Get.back(result: 'gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo / Scanner'),
                onTap: () => Get.back(result: 'camera'),
              ),
            ],
          ),
        ),
      );

      if (selectionType == null) return;

      if (selectionType == 'file') {
        // Sélectionner des fichiers avec file_picker
        final FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: true,
        );

        if (result != null && result.files.isNotEmpty) {
          for (var platformFile in result.files) {
            if (platformFile.path != null) {
              final file = File(platformFile.path!);
              final fileSize = await file.length();

              // Vérifier la taille (max 10 MB)
              if (fileSize > 10 * 1024 * 1024) {
                Get.snackbar(
                  'Erreur',
                  'Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)',
                  snackPosition: SnackPosition.BOTTOM,
                );
                continue;
              }

              // Déterminer le type de fichier
              String fileType = 'document';
              final extension = platformFile.extension?.toLowerCase() ?? '';
              if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
                fileType = 'image';
              } else if (extension == 'pdf') {
                fileType = 'pdf';
              }

              // Ajouter le fichier à la liste
              selectedFiles.add({
                'name': platformFile.name,
                'path': platformFile.path!,
                'size': fileSize,
                'type': fileType,
                'extension': extension,
              });
            }
          }

          Get.snackbar(
            'Succès',
            '${result.files.length} fichier(s) sélectionné(s)',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        // Utiliser CameraService pour une meilleure gestion des permissions
        final cameraService = CameraService();
        File? imageFile;

        try {
          if (selectionType == 'camera') {
            imageFile = await cameraService.takePicture();
          } else {
            imageFile = await cameraService.pickImageFromGallery();
          }

          if (imageFile != null && await imageFile.exists()) {
            // Vérifier que le fichier existe
            if (!await imageFile.exists()) {
              throw Exception('Le fichier sélectionné n\'existe pas');
            }

            final fileSize = await imageFile.length();

            // Vérifier la taille (max 10 MB)
            if (fileSize > 10 * 1024 * 1024) {
              Get.snackbar(
                'Erreur',
                'Le fichier est trop volumineux (max 10 MB)',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
              return;
            }

            // Valider l'image
            try {
              await cameraService.validateImage(imageFile);
            } catch (e) {
              Get.snackbar(
                'Erreur',
                'Image invalide: $e',
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 3),
              );
              return;
            }

            final fileName = imageFile.path.split('/').last;
            final extension = fileName.split('.').last.toLowerCase();

            // Ajouter le fichier à la liste
            selectedFiles.add({
              'name': fileName,
              'path': imageFile.path,
              'size': fileSize,
              'type': 'image',
              'extension': extension,
            });

            Get.snackbar(
              'Succès',
              'Fichier sélectionné',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 2),
            );
          }
        } catch (e) {
          // Gérer les erreurs de permissions et autres erreurs
          String errorMessage = 'Erreur lors de la sélection du fichier';
          if (e.toString().contains('Permission')) {
            errorMessage =
                'Permission refusée. Veuillez autoriser l\'accès à la caméra/photos dans les paramètres de l\'application.';
          } else {
            errorMessage = e.toString().replaceFirst('Exception: ', '');
          }

          Get.snackbar(
            'Erreur',
            errorMessage,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Erreur lors de la sélection du fichier: ${e.toString().replaceFirst('Exception: ', '')}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Supprimer un fichier de la liste
  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  @override
  void onClose() {
    _searchDebounceTimer?.cancel();
    scrollController.dispose();
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    // Toujours synchroniser le filtre avec l'onglet affiché (comme bon de commande fournisseur)
    final index = tabController.index;
    selectedStatus.value = index == 0 ? null : index;
  }

  /// Retourne les bons de commande filtrés selon l'onglet (0 = Tous, 1 = En attente, 2 = Validés, 3 = Rejetés, 4 = Livrés).
  /// En attente : statuts 0 et 1 sont considérés comme "en attente".
  List<BonCommande> getFilteredBonCommandes() {
    final status = selectedStatus.value;
    if (status == null) return bonCommandes;
    if (status == 1) {
      return bonCommandes
          .where((bc) => bc.status == 0 || bc.status == 1)
          .toList();
    }
    return bonCommandes
        .where((bonCommande) => bonCommande.status == status)
        .toList();
  }

  Future<void> loadBonCommandes({
    int? status,
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingInProgress) {
      AppLogger.debug('Chargement déjà en cours, ignore', tag: 'BON_COMMANDE_CONTROLLER');
      return;
    }
    if (!forceRefresh &&
        bonCommandes.isNotEmpty &&
        _currentStatus == status &&
        currentPage.value == page &&
        page == 1) {
      AppLogger.debug('Données déjà chargées', tag: 'BON_COMMANDE_CONTROLLER');
      return;
    }
    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'bon_commandes_${status ?? 'all'}';

    if (page == 1) {
      isLoading.value = true;
      final cachedData = BonCommandeService.getCachedBonCommandes(status);
      if (cachedData.isNotEmpty) {
        bonCommandes.assignAll(cachedData);
        isLoading.value = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} bon(s) → affichage instantané',
          tag: 'BON_COMMANDE_CONTROLLER',
        );
      } else {
        bonCommandes.value = [];
      }
    } else {
      isLoadingMore.value = true;
    }

    try {
      final response = await _bonCommandeService.getBonCommandesPaginated(
        status: status,
        page: page,
        perPage: perPage.value,
        search: searchQuery.value.isNotEmpty ? searchQuery.value : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug('[API] onglet changé, mise à jour ignorée', tag: 'BON_COMMANDE_CONTROLLER');
        return;
      }

      if (page == 1) {
        bonCommandes.assignAll(response.data);
        CacheHelper.set(entityKey, response.data);
        BonCommandeService.saveCachedBonCommandes(response.data, status);
        currentPage.value = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} bon(s), Hive mis à jour',
          tag: 'BON_COMMANDE_CONTROLLER',
        );
      } else {
        bonCommandes.addAll(response.data);
      }

      totalPages.value = response.meta.lastPage;
      totalItems.value = response.meta.total;
      hasNextPage.value = response.hasNextPage;
      hasPreviousPage.value = response.hasPreviousPage;
      if (page > 1) currentPage.value = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Bons de commande: $e', tag: 'BON_COMMANDE_CONTROLLER');
      if (bonCommandes.isEmpty) {
        final fallback = BonCommandeService.getCachedBonCommandes(status);
        if (fallback.isNotEmpty) {
          bonCommandes.assignAll(fallback);
        } else {
          Get.snackbar(
            'Erreur',
            'Impossible de charger les bons de commande',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 4),
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
      loadBonCommandes(status: _currentStatus, page: currentPage.value + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage.value && !isLoading.value) {
      loadBonCommandes(status: _currentStatus, page: currentPage.value - 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bonCommandeService.getBonCommandeStats();
      totalBonCommandes.value = stats['total'] ?? 0;
      bonCommandesEnvoyes.value = stats['envoyes'] ?? 0;
      bonCommandesAcceptes.value = stats['acceptes'] ?? 0;
      bonCommandesRefuses.value = stats['refuses'] ?? 0;
      bonCommandesLivres.value = stats['livres'] ?? 0;
      montantTotal.value = stats['montant_total'] ?? 0.0;
    } catch (e) {
      // Erreur silencieuse lors du chargement des statistiques
    }
  }

  Future<bool> createBonCommande() async {
    if (isLoading.value) return false;
    try {
      // Vérifications
      if (selectedClient.value == null) {
        throw Exception('Aucun client sélectionné');
      }

      if (selectedClient.value!.id == null) {
        throw Exception(
          'L\'ID du client est manquant. Veuillez sélectionner un client valide.',
        );
      }

      if (selectedFiles.isEmpty) {
        throw Exception('Veuillez ajouter au moins un fichier scanné');
      }

      isLoading.value = true;

      final clientId = selectedClient.value!.id!;

      // Extraire les chemins des fichiers
      final fichiersPaths =
          selectedFiles.map((file) => file['path'] as String).toList();

      final newBonCommande = BonCommande(
        clientId: clientId,
        commercialId: userId,
        fichiers: fichiersPaths,
        status: 1, // En attente
      );

      final createdBonCommande = await _bonCommandeService.createBonCommande(
        newBonCommande,
      );

      CacheHelper.clearByPrefix('bon_commandes_');

      // Insertion locale uniquement si le statut correspond à l'onglet actuel. Nouveau bon = statut 1 (en attente).
      const newBonStatus = 1;
      final shouldInsert = _currentStatus == null || _currentStatus == newBonStatus;
      if (shouldInsert) {
        bonCommandes.insert(0, createdBonCommande);
        BonCommandeService.saveCachedBonCommandes(bonCommandes.toList(), _currentStatus);
        AppLogger.debug(
          '[Création bon commande] insertion locale + mise à jour Hive (statut=$_currentStatus)',
          tag: 'BON_COMMANDE_CONTROLLER',
        );
      }

      if (createdBonCommande.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bon_commande',
          entityName: NotificationHelper.getEntityDisplayName(
            'bon_commande',
            createdBonCommande,
          ),
          entityId: createdBonCommande.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'bon_commande',
            createdBonCommande.id.toString(),
          ),
        );
      }

      DashboardRefreshHelper.refreshPatronCounter('bon_commande');

      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      clearForm();
      // Pas de loadBonCommandes() pour ne pas écraser l'insertion locale

      return true;
    } catch (e) {
      // Utiliser ErrorHelper pour gérer les erreurs correctement
      // Ne pas afficher les erreurs post-succès et masquer en production
      ErrorHelper.showErrorIfNotPostSuccess(
        e,
        title: 'Erreur',
        customMessage: 'Impossible de créer le bon de commande',
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateBonCommande(int bonCommandeId) async {
    if (isLoading.value) return false;
    try {
      isLoading.value = true;
      final bonCommandeToUpdate = bonCommandes.firstWhere(
        (b) => b.id == bonCommandeId,
      );

      // Extraire les chemins des fichiers
      final fichiersPaths =
          selectedFiles.map((file) => file['path'] as String).toList();

      final updatedBonCommande = BonCommande(
        id: bonCommandeId,
        clientId: selectedClient.value?.id ?? bonCommandeToUpdate.clientId,
        commercialId: bonCommandeToUpdate.commercialId,
        fichiers:
            fichiersPaths.isNotEmpty
                ? fichiersPaths
                : bonCommandeToUpdate.fichiers,
        status: bonCommandeToUpdate.status,
      );

      await _bonCommandeService.updateBonCommande(updatedBonCommande);

      // Si la mise à jour réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bon de commande mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadBonCommandes();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le bon de commande a été mis à jour avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de mettre à jour le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.deleteBonCommande(
        bonCommandeId,
      );
      if (success) {
        bonCommandes.removeWhere((b) => b.id == bonCommandeId);
        Get.snackbar(
          'Succès',
          'Bon de commande supprimé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de supprimer le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> submitBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.submitBonCommande(
        bonCommandeId,
      );
      if (success) {
        await loadBonCommandes();

        // Notifier le patron de la soumission
        final bonCommande = bonCommandes.firstWhereOrNull(
          (b) => b.id == bonCommandeId,
        );
        if (bonCommande != null) {
          NotificationHelper.notifySubmission(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_commande',
              bonCommande,
            ),
            entityId: bonCommandeId.toString(),
            route: NotificationHelper.getEntityRoute(
              'bon_commande',
              bonCommandeId.toString(),
            ),
          );
        }

        Get.snackbar(
          'Succès',
          'Bon de commande soumis avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de soumettre le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> approveBonCommande(int bonCommandeId) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_commandes_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final bonCommandeIndex = bonCommandes.indexWhere(
        (b) => b.id == bonCommandeId,
      );
      if (bonCommandeIndex != -1) {
        final originalBonCommande = bonCommandes[bonCommandeIndex];
        final updatedBonCommande = BonCommande(
          id: originalBonCommande.id,
          clientId: originalBonCommande.clientId,
          commercialId: originalBonCommande.commercialId,
          fichiers: originalBonCommande.fichiers,
          status: 2, // Approuvé
        );
        bonCommandes[bonCommandeIndex] = updatedBonCommande;
      }

      final success = await _bonCommandeService.approveBonCommande(
        bonCommandeId,
      );
      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('boncommande');

        // Notifier l'utilisateur concerné de la validation
        final bonCommande = bonCommandes.firstWhereOrNull(
          (b) => b.id == bonCommandeId,
        );
        if (bonCommande != null) {
          NotificationHelper.notifyValidation(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_commande',
              bonCommande,
            ),
            entityId: bonCommandeId.toString(),
            route: NotificationHelper.getEntityRoute(
              'bon_commande',
              bonCommandeId.toString(),
            ),
            entity: bonCommande,
          );
        }

        Get.snackbar(
          'Succès',
          'Bon de commande approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadBonCommandes(status: _currentStatus).catchError((e) {
            // En cas d'erreur, on garde la mise à jour optimiste
          });
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadBonCommandes(status: _currentStatus);
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_commandes_');

      // Mise à jour optimiste de l'UI - mettre à jour immédiatement
      final bonCommandeIndex = bonCommandes.indexWhere(
        (b) => b.id == bonCommandeId,
      );
      if (bonCommandeIndex != -1) {
        final originalBonCommande = bonCommandes[bonCommandeIndex];
        final updatedBonCommande = BonCommande(
          id: originalBonCommande.id,
          clientId: originalBonCommande.clientId,
          commercialId: originalBonCommande.commercialId,
          fichiers: originalBonCommande.fichiers,
          status: 3, // Rejeté
        );
        bonCommandes[bonCommandeIndex] = updatedBonCommande;
      }

      final success = await _bonCommandeService.rejectBonCommande(
        bonCommandeId,
        commentaire,
      );
      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter('boncommande');

        // Notifier l'utilisateur concerné du rejet
        final bonCommande = bonCommandes.firstWhereOrNull(
          (b) => b.id == bonCommandeId,
        );
        if (bonCommande != null) {
          NotificationHelper.notifyRejection(
            entityType: 'bon_commande',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_commande',
              bonCommande,
            ),
            entityId: bonCommandeId.toString(),
            reason: commentaire,
            route: NotificationHelper.getEntityRoute(
              'bon_commande',
              bonCommandeId.toString(),
            ),
            entity: bonCommande,
          );
        }

        Get.snackbar(
          'Succès',
          'Bon de commande rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadBonCommandes(status: _currentStatus).catchError((e) {
            // En cas d'erreur, on garde la mise à jour optimiste
          });
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadBonCommandes(status: _currentStatus);
        throw Exception('Erreur lors du rejet');
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markAsDelivered(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.markAsDelivered(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Bon de commande marqué comme livré',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors du marquage comme livré');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de marquer le bon de commande comme livré',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> generateInvoice(int bonCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _bonCommandeService.generateInvoice(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        Get.snackbar(
          'Succès',
          'Facture générée avec succès',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        throw Exception('Erreur lors de la génération de la facture');
      }
    } catch (e) {
      Get.snackbar(
        'Erreur',
        'Impossible de générer la facture',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Chargement des clients validés : cache Hive d'abord, puis API.
  Future<void> loadValidatedClients() async {
    isLoadingClients.value = true;
    final cached = ClientService.getCachedClients(1);
    if (cached.isNotEmpty) {
      availableClients.assignAll(cached);
      isLoadingClients.value = false;
    } else {
      availableClients.value = [];
    }
    try {
      final clients = await _clientService.getClients(status: 1);
      availableClients.assignAll(clients);
    } catch (e) {
      if (availableClients.isEmpty) {
        final fallback = ClientService.getCachedClients(1);
        if (fallback.isNotEmpty) {
          availableClients.assignAll(fallback);
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

  // Recherche de clients validés
  Future<void> searchClients(String query) async {
    try {
      if (availableClients.isEmpty) {
        await loadValidatedClients();
      }
      // La recherche sera implémentée dans l'interface utilisateur
    } catch (e) {
      // Erreur silencieuse lors de la recherche des clients
    }
  }

  void selectClient(Client client) {
    selectedClient.value = client;
  }

  void clearSelectedClient() {
    selectedClient.value = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient.value = null;
    selectedFiles.clear();
  }

  /// Générer un PDF pour un bon de commande
  Future<void> generatePDF(int bonCommandeId) async {
    try {
      isLoading.value = true;

      // Trouver le bon de commande
      final bonCommande = bonCommandes.firstWhere(
        (b) => b.id == bonCommandeId,
        orElse: () => throw Exception('Bon de commande introuvable'),
      );

      // Charger les données nécessaires (timeout long : génération PDF)
      final clients = await _clientService.getClients(timeout: AppConfig.extraLongTimeout);
      final client = clients.firstWhere(
        (c) => c.id == bonCommande.clientId,
        orElse:
            () => throw Exception('Client introuvable pour ce bon de commande'),
      );

      // Générer le PDF avec les informations disponibles
      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bonCommande.id != null ? 'BC-${bonCommande.id}' : 'N/A',
          'date_creation': DateTime.now(),
          'montant_ht': 0.0,
          'tva': 0.0,
          'total_ttc': 0.0,
        },
        items: [], // Pas d'items pour les bons de commande entreprise
        fournisseur:
            {}, // Vide car on utilise client pour les bons de commande entreprise
        client: {
          'nom': client.nom ?? '',
          'prenom': client.prenom ?? '',
          'nom_entreprise': client.nomEntreprise ?? '',
          'email': client.email ?? '',
          'contact': client.contact ?? '',
          'adresse': client.adresse ?? '',
          'numero_contribuable': client.numeroContribuable ?? '',
        },
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
