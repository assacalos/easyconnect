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

class BonCommandeController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late int userId;
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final ClientService _clientService = ClientService();

  final bonCommandes = <BonCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final availableClients = <Client>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final currentBonCommande = Rxn<BonCommande>();
  int? _currentStatus; // Mémoriser le statut actuellement chargé

  // Fichiers scannés (liste de chemins locaux)
  final selectedFiles = <Map<String, dynamic>>[].obs;

  // Gestion des onglets
  late TabController tabController;
  final selectedStatus = Rxn<int>();

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
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);
    // Ne pas charger automatiquement - laisser les pages décider quand charger
    // Cela évite les erreurs et ralentissements inutiles
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   loadBonCommandes();
    //   loadStats();
    // });
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
    tabController.dispose();
    super.onClose();
  }

  void _onTabChanged() {
    if (tabController.indexIsChanging) {
      selectedStatus.value =
          tabController.index == 0 ? null : tabController.index;
    }
  }

  // Obtenir les bons de commande filtrés selon l'onglet sélectionné
  List<BonCommande> getFilteredBonCommandes() {
    if (selectedStatus.value == null) {
      return bonCommandes;
    }
    return bonCommandes
        .where((bonCommande) => bonCommande.status == selectedStatus.value)
        .toList();
  }

  Future<void> loadBonCommandes({
    int? status,
    bool forceRefresh = false,
  }) async {
    try {
      _currentStatus = status; // Mémoriser le statut actuel

      // Si on ne force pas le rafraîchissement et que les données sont déjà chargées, ne rien faire
      // MAIS seulement si on a vraiment des données (pas si la liste est vide)
      if (!forceRefresh &&
          bonCommandes.isNotEmpty &&
          _currentStatus == status) {
        return;
      }

      // Afficher immédiatement les données du cache si disponibles
      final cacheKey = 'bon_commandes_${status ?? 'all'}';
      final cachedBonCommandes = CacheHelper.get<List<BonCommande>>(cacheKey);
      if (cachedBonCommandes != null &&
          cachedBonCommandes.isNotEmpty &&
          !forceRefresh) {
        bonCommandes.value = cachedBonCommandes;
        isLoading.value = false; // Permettre l'affichage immédiat
      } else {
        isLoading.value = true;
      }

      // Charger les données fraîches en arrière-plan
      final loadedBonCommandes = await _bonCommandeService.getBonCommandes(
        status: status,
      );
      bonCommandes.value = loadedBonCommandes;
    } catch (e) {
      // Ne pas afficher d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        // Ne pas afficher d'erreur si des données sont disponibles (cache ou liste non vide)
        if (bonCommandes.isEmpty) {
          // Vérifier une dernière fois le cache avant d'afficher l'erreur
          final cacheKey = 'bon_commandes_${status ?? 'all'}';
          final cachedBonCommandes = CacheHelper.get<List<BonCommande>>(
            cacheKey,
          );
          if (cachedBonCommandes == null || cachedBonCommandes.isEmpty) {
            Get.snackbar(
              'Erreur',
              'Impossible de charger les bons de commande: ${e.toString()}',
              snackPosition: SnackPosition.BOTTOM,
              duration: const Duration(seconds: 4),
            );
          } else {
            // Charger les données du cache si disponibles
            bonCommandes.value = cachedBonCommandes;
          }
        }
      }
    } finally {
      isLoading.value = false;
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

      // Invalider le cache
      CacheHelper.clearByPrefix('bon_commandes_');

      // Ajouter le bon de commande à la liste localement (mise à jour optimiste)
      if (createdBonCommande.id != null) {
        bonCommandes.add(createdBonCommande);
      }

      // Rafraîchir les compteurs du dashboard patron
      DashboardRefreshHelper.refreshPatronCounter('bon_commande');

      // Si la création réussit, afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Effacer le formulaire
      clearForm();

      // Essayer de recharger la liste (mais ne pas faire échouer si ça échoue)
      try {
        await loadBonCommandes();
      } catch (e) {
        // Si le rechargement échoue, on ne fait rien car le bon de commande a été créé avec succès
        // L'utilisateur peut recharger manuellement si nécessaire
      }

      return true;
    } catch (e) {
      // Extraire le message d'erreur
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
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

  Future<bool> updateBonCommande(int bonCommandeId) async {
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
        throw Exception('Erreur lors de l\'approbation');
      }
    } catch (e) {
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadBonCommandes(status: _currentStatus);
      Get.snackbar(
        'Erreur',
        'Impossible d\'approuver le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
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
      // En cas d'erreur, recharger pour restaurer l'état correct
      await loadBonCommandes(status: _currentStatus);
      Get.snackbar(
        'Erreur',
        'Impossible de rejeter le bon de commande',
        snackPosition: SnackPosition.BOTTOM,
      );
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
}
