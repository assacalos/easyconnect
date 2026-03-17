import 'dart:async';
import 'dart:io';
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

BonCommande? _firstWhereBonCommandeById(List<BonCommande> list, int id) {
  try {
    return list.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}

class BonCommandeController {
  static final BonCommandeController _instance = BonCommandeController._();
  static BonCommandeController get to => _instance;
  factory BonCommandeController() => _instance;
  BonCommandeController._();

  int get userId => int.parse(AuthController.to.userAuth?.id.toString() ?? '0');

  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ClientService _clientService = ClientService();

  final List<BonCommande> bonCommandes = [];
  Client? selectedClient;
  final List<Client> availableClients = [];
  bool isLoading = false;
  bool isLoadingMore = false;
  bool isLoadingClients = false;
  BonCommande? currentBonCommande;

  // Fichiers scannés (liste de chemins locaux)
  final List<Map<String, dynamic>> selectedFiles = [];

  // Gestion des onglets : la vue crée le TabController et l'assigne via setTabController
  TabController? _tabController;
  int? selectedStatus;
  int? _currentStatus;
  bool _isLoadingInProgress = false;

  // Métadonnées de pagination
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 15;
  String searchQuery = '';
  final ScrollController scrollController = ScrollController();
  Timer? _searchDebounceTimer;

  // Statistiques
  int totalBonCommandes = 0;
  int bonCommandesEnvoyes = 0;
  int bonCommandesAcceptes = 0;
  int bonCommandesRefuses = 0;
  int bonCommandesLivres = 0;
  double montantTotal = 0.0;

  void setTabController(TabController c) {
    _tabController?.removeListener(_onTabChanged);
    _tabController = c;
    _tabController!.addListener(_onTabChanged);
  }

  void setSearchQuery(String q) {
    if (searchQuery == q) return;
    searchQuery = q;
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      loadBonCommandes(status: _currentStatus, forceRefresh: true);
    });
  }
  // Sélectionner des fichiers (scan ou sélection). Nécessite [context] pour les dialogs.
  Future<void> selectFiles(BuildContext context) async {
    try {
      // Proposer de choisir le type de sélection
      final String? selectionType = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Sélectionner des fichiers'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Fichiers (PDF, Documents, etc.)'),
                onTap: () => Navigator.of(ctx).pop('file'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Image depuis la galerie'),
                onTap: () => Navigator.of(ctx).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Prendre une photo / Scanner'),
                onTap: () => Navigator.of(ctx).pop('camera'),
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
                errorHelperShowSnackbar?.call(
                  'Erreur',
                  'Le fichier "${platformFile.name}" est trop volumineux (max 10 MB)',
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

          errorHelperShowSnackbar?.call(
            'Succès',
            '${result.files.length} fichier(s) sélectionné(s)',
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
              errorHelperShowSnackbar?.call(
                'Erreur',
                'Le fichier est trop volumineux (max 10 MB)',
                duration: const Duration(seconds: 3),
              );
              return;
            }

            // Valider l'image
            try {
              await cameraService.validateImage(imageFile);
            } catch (e) {
              errorHelperShowSnackbar?.call(
                'Erreur',
                'Image invalide: $e',
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

            errorHelperShowSnackbar?.call(
              'Succès',
              'Fichier sélectionné',
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

          errorHelperShowSnackbar?.call(
            'Erreur',
            errorMessage,
            duration: const Duration(seconds: 4),
          );
        }
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Erreur lors de la sélection du fichier: ${e.toString().replaceFirst('Exception: ', '')}',
        duration: const Duration(seconds: 4),
      );
    }
  }

  void removeFile(int index) {
    if (index >= 0 && index < selectedFiles.length) {
      selectedFiles.removeAt(index);
    }
  }

  void dispose() {
    _searchDebounceTimer?.cancel();
    scrollController.dispose();
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;
  }

  void _onTabChanged() {
    if (_tabController == null || !_tabController!.indexIsChanging) return;
    final index = _tabController!.index;
    selectedStatus = index == 0 ? null : index;
  }

  /// Retourne les bons de commande filtrés selon l'onglet (0 = Tous, 1 = En attente, 2 = Validés, 3 = Rejetés, 4 = Livrés).
  /// En attente : statuts 0 et 1 sont considérés comme "en attente".
  List<BonCommande> getFilteredBonCommandes() {
    final status = selectedStatus;
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
        currentPage == page &&
        page == 1) {
      AppLogger.debug('Données déjà chargées', tag: 'BON_COMMANDE_CONTROLLER');
      return;
    }
    _isLoadingInProgress = true;
    _currentStatus = status;
    final entityKey = 'bon_commandes_${status ?? 'all'}';

    if (page == 1) {
      isLoading = true;
      final cachedData = BonCommandeService.getCachedBonCommandes(status);
      if (cachedData.isNotEmpty) {
        bonCommandes.clear();
        bonCommandes.addAll(cachedData);
        isLoading = false;
        AppLogger.debug(
          '[Hive] statut=$status, ${cachedData.length} bon(s) → affichage instantané',
          tag: 'BON_COMMANDE_CONTROLLER',
        );
      } else {
        bonCommandes.clear();
      }
    } else {
      isLoadingMore = true;
    }

    try {
      final response = await _bonCommandeService.getBonCommandesPaginated(
        status: status,
        page: page,
        perPage: perPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
      );

      if (_currentStatus != status) {
        AppLogger.debug('[API] onglet changé, mise à jour ignorée', tag: 'BON_COMMANDE_CONTROLLER');
        return;
      }

      if (page == 1) {
        bonCommandes.clear();
        bonCommandes.addAll(response.data);
        CacheHelper.set(entityKey, response.data);
        BonCommandeService.saveCachedBonCommandes(response.data, status);
        currentPage = 1;
        AppLogger.debug(
          '[API] page 1 → ${response.data.length} bon(s), Hive mis à jour',
          tag: 'BON_COMMANDE_CONTROLLER',
        );
      } else {
        bonCommandes.addAll(response.data);
      }

      totalPages = response.meta.lastPage;
      totalItems = response.meta.total;
      hasNextPage = response.hasNextPage;
      hasPreviousPage = response.hasPreviousPage;
      if (page > 1) currentPage = response.meta.currentPage;
    } catch (e) {
      AppLogger.error('Erreur API Bons de commande: $e', tag: 'BON_COMMANDE_CONTROLLER');
      if (bonCommandes.isEmpty) {
        final fallback = BonCommandeService.getCachedBonCommandes(status);
        if (fallback.isNotEmpty) {
          bonCommandes.clear();
          bonCommandes.addAll(fallback);
        } else {
          errorHelperShowSnackbar?.call(
            'Erreur',
            'Impossible de charger les bons de commande',
            duration: const Duration(seconds: 4),
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

  /// Charger la page suivante
  void loadNextPage() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadBonCommandes(status: _currentStatus, page: currentPage + 1);
    }
  }

  /// Charger la page précédente
  void loadPreviousPage() {
    if (hasPreviousPage && !isLoading) {
      loadBonCommandes(status: _currentStatus, page: currentPage - 1);
    }
  }

  Future<void> loadStats() async {
    try {
      final stats = await _bonCommandeService.getBonCommandeStats();
      totalBonCommandes = stats['total'] ?? 0;
      bonCommandesEnvoyes = stats['envoyes'] ?? 0;
      bonCommandesAcceptes = stats['acceptes'] ?? 0;
      bonCommandesRefuses = stats['refuses'] ?? 0;
      bonCommandesLivres = stats['livres'] ?? 0;
      montantTotal = stats['montant_total'] ?? 0.0;
    } catch (e) {
      // Erreur silencieuse lors du chargement des statistiques
    }
  }

  Future<bool> createBonCommande() async {
    if (isLoading) return false;
    try {
      // Vérifications
      if (selectedClient == null) {
        throw Exception('Aucun client sélectionné');
      }

      if (selectedClient!.id == null) {
        throw Exception(
          'L\'ID du client est manquant. Veuillez sélectionner un client valide.',
        );
      }

      if (selectedFiles.isEmpty) {
        throw Exception('Veuillez ajouter au moins un fichier scanné');
      }

      isLoading = true;

      final clientId = selectedClient!.id!;

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

      errorHelperShowSnackbar?.call(
        'Succès',
        'Bon de commande créé avec succès',
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
      isLoading = false;
    }
  }

  Future<bool> updateBonCommande(int bonCommandeId) async {
    if (isLoading) return false;
    try {
      isLoading = true;
      final bonCommandeToUpdate = bonCommandes.firstWhere(
        (b) => b.id == bonCommandeId,
      );

      // Extraire les chemins des fichiers
      final fichiersPaths =
          selectedFiles.map((file) => file['path'] as String).toList();

      final updatedBonCommande = BonCommande(
        id: bonCommandeId,
        clientId: selectedClient?.id ?? bonCommandeToUpdate.clientId,
        commercialId: bonCommandeToUpdate.commercialId,
        fichiers:
            fichiersPaths.isNotEmpty
                ? fichiersPaths
                : bonCommandeToUpdate.fichiers,
        status: bonCommandeToUpdate.status,
      );

      await _bonCommandeService.updateBonCommande(updatedBonCommande);

      // Si la mise à jour réussit, afficher le message de succès
      errorHelperShowSnackbar?.call(
        'Succès',
        'Bon de commande mis à jour avec succès',
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
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de mettre à jour le bon de commande',
      );
      return false;
    } finally {
      isLoading = false;
    }
  }

  Future<void> deleteBonCommande(int bonCommandeId) async {
    try {
      isLoading = true;
      final success = await _bonCommandeService.deleteBonCommande(
        bonCommandeId,
      );
      if (success) {
        bonCommandes.removeWhere((b) => b.id == bonCommandeId);
        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande supprimé avec succès',
        );
      } else {
        throw Exception('Erreur lors de la suppression');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de supprimer le bon de commande',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> submitBonCommande(int bonCommandeId) async {
    try {
      isLoading = true;
      final success = await _bonCommandeService.submitBonCommande(
        bonCommandeId,
      );
      if (success) {
        await loadBonCommandes();

        // Notifier le patron de la soumission
        final bonCommande = _firstWhereBonCommandeById(bonCommandes, bonCommandeId);
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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande soumis avec succès',
        );
      } else {
        throw Exception('Erreur lors de la soumission');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de soumettre le bon de commande',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> approveBonCommande(int bonCommandeId) async {
    try {
      isLoading = true;

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
        // Rafraîchir les compteurs du dashboard patron et commercial
        DashboardRefreshHelper.refreshPatronCounter('boncommande');
        DashboardRefreshHelper.refreshCommercialDashboard();

        // Notifier l'utilisateur concerné de la validation
        final bonCommande = _firstWhereBonCommandeById(bonCommandes, bonCommandeId);
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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande approuvé avec succès',
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectBonCommande(int bonCommandeId, String commentaire) async {
    try {
      isLoading = true;

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
        // Rafraîchir les compteurs du dashboard patron et commercial
        DashboardRefreshHelper.refreshPatronCounter('boncommande');
        DashboardRefreshHelper.refreshCommercialDashboard();

        // Notifier l'utilisateur concerné du rejet
        final bonCommande = _firstWhereBonCommandeById(bonCommandes, bonCommandeId);
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

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande rejeté avec succès',
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
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadBonCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> markAsDelivered(int bonCommandeId) async {
    try {
      isLoading = true;
      final success = await _bonCommandeService.markAsDelivered(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande marqué comme livré',
        );
      } else {
        throw Exception('Erreur lors du marquage comme livré');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de marquer le bon de commande comme livré',
      );
    } finally {
      isLoading = false;
    }
  }

  Future<void> generateInvoice(int bonCommandeId) async {
    try {
      isLoading = true;
      final success = await _bonCommandeService.generateInvoice(bonCommandeId);
      if (success) {
        await loadBonCommandes();
        errorHelperShowSnackbar?.call(
          'Succès',
          'Facture générée avec succès',
        );
      } else {
        throw Exception('Erreur lors de la génération de la facture');
      }
    } catch (e) {
      errorHelperShowSnackbar?.call(
        'Erreur',
        'Impossible de générer la facture',
      );
    } finally {
      isLoading = false;
    }
  }

  // Chargement des clients validés : cache Hive d'abord, puis API.
  Future<void> loadValidatedClients() async {
    isLoadingClients = true;
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
    } catch (e) {
      // Erreur silencieuse lors de la recherche des clients
    }
  }

  void selectClient(Client client) {
    selectedClient = client;
  }

  void clearSelectedClient() {
    selectedClient = null;
  }

  /// Effacer toutes les données du formulaire
  void clearForm() {
    selectedClient = null;
    selectedFiles.clear();
  }

  /// Générer un PDF pour un bon de commande
  Future<void> generatePDF(int bonCommandeId) async {
    try {
      isLoading = true;

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
