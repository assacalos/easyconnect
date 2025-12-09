import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Models/bon_de_commande_fournisseur_model.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/Models/client_model.dart';
import 'package:easyconnect/Models/supplier_model.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/pdf_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/reference_generator.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/dashboard_refresh_helper.dart';
import 'package:easyconnect/utils/logger.dart';

class BonDeCommandeFournisseurController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late int userId;
  final BonDeCommandeFournisseurService _service =
      BonDeCommandeFournisseurService();
  final ClientService _clientService = ClientService();
  final SupplierService _supplierService = SupplierService();

  final bonDeCommandes = <BonDeCommande>[].obs;
  final selectedClient = Rxn<Client>();
  final selectedSupplier = Rxn<Supplier>();
  final availableClients = <Client>[].obs;
  final availableSuppliers = <Supplier>[].obs;
  final isLoading = false.obs;
  final isLoadingClients = false.obs;
  final isLoadingSuppliers = false.obs;
  final currentBonDeCommande = Rxn<BonDeCommande>();
  final items = <BonDeCommandeItem>[].obs;

  // Référence générée automatiquement
  final generatedNumeroCommande = ''.obs;

  // Gestion des onglets
  late TabController tabController;
  final selectedStatus = Rxn<String>();
  String? _currentStatus; // Mémoriser le statut actuellement chargé

  // Statistiques
  final totalBonDeCommandes = 0.obs;
  final bonDeCommandesEnAttente = 0.obs;
  final bonDeCommandesValides = 0.obs;
  final bonDeCommandesRejetes = 0.obs;
  final bonDeCommandesLivres = 0.obs;
  final montantTotal = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    userId = int.parse(
      Get.find<AuthController>().userAuth.value!.id.toString(),
    );
    tabController = TabController(length: 5, vsync: this);
    tabController.addListener(_onTabChanged);
    // Charger les données de manière asynchrone pour ne pas bloquer l'UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadBonDeCommandes();
      // Ne charger que les fournisseurs, pas les clients
      loadSuppliers();
      // Générer automatiquement le numéro de commande au démarrage
      initializeGeneratedNumeroCommande();
    });
  }

  // Générer automatiquement le numéro de commande fournisseur
  Future<String> generateNumeroCommande() async {
    // Recharger les bons de commande pour avoir le comptage à jour
    await loadBonDeCommandes();

    // Extraire tous les numéros de commande existants
    final existingNumbers =
        bonDeCommandes
            .map((bc) => bc.numeroCommande)
            .where((num) => num.isNotEmpty)
            .toList();

    // Générer avec incrément
    return ReferenceGenerator.generateReferenceWithIncrement(
      'BCF',
      existingNumbers,
    );
  }

  // Initialiser le numéro de commande généré
  Future<void> initializeGeneratedNumeroCommande() async {
    if (generatedNumeroCommande.value.isEmpty) {
      generatedNumeroCommande.value = await generateNumeroCommande();
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
          tabController.index == 0
              ? null
              : _getStatusFromIndex(tabController.index);
    }
  }

  String _getStatusFromIndex(int index) {
    switch (index) {
      case 1:
        return 'en_attente';
      case 2:
        return 'valide';
      case 3:
        return 'rejete';
      case 4:
        return 'livre';
      default:
        return '';
    }
  }

  List<BonDeCommande> getFilteredBonDeCommandes() {
    // Si aucun statut sélectionné, retourner tous les bons de commande
    if (selectedStatus.value == null || selectedStatus.value == 'all') {
      return bonDeCommandes;
    }

    // Filtrer par statut (comparaison insensible à la casse)
    final statusLower = selectedStatus.value!.toLowerCase().trim();
    return bonDeCommandes.where((bc) {
      final bcStatus = bc.statut.toLowerCase().trim();
      // Gérer les différentes variantes de statuts
      switch (statusLower) {
        case 'en_attente':
        case 'pending':
          return bcStatus == 'en_attente' || bcStatus == 'pending';
        case 'valide':
        case 'approved':
        case 'validated':
          return bcStatus == 'valide' ||
              bcStatus == 'approved' ||
              bcStatus == 'validated';
        case 'rejete':
        case 'rejected':
          return bcStatus == 'rejete' || bcStatus == 'rejected';
        default:
          return bcStatus == statusLower;
      }
    }).toList();
  }

  Future<void> loadBonDeCommandes({
    String? status,
    bool forceRefresh = false,
  }) async {
    try {
      _currentStatus = status; // Mémoriser le statut actuel

      // Mettre à jour le statut sélectionné
      if (status != null) {
        selectedStatus.value = status;
      } else {
        selectedStatus.value = 'all';
      }

      // Afficher immédiatement les données du cache si disponibles
      final cacheKey = 'bon_de_commandes_fournisseur_${status ?? 'all'}';
      final cachedBonDeCommandes = CacheHelper.get<List<BonDeCommande>>(
        cacheKey,
      );
      if (cachedBonDeCommandes != null &&
          cachedBonDeCommandes.isNotEmpty &&
          !forceRefresh) {
        bonDeCommandes.value = cachedBonDeCommandes;
        isLoading.value = false; // Permettre l'affichage immédiat
        AppLogger.debug(
          'Données chargées depuis le cache: ${cachedBonDeCommandes.length} bons de commande',
          tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
        );
      } else {
        isLoading.value = true;
      }

      // Charger tous les bons de commande (le filtrage se fera côté client)
      final loadedBonDeCommandes = await _service.getBonDeCommandes();
      bonDeCommandes.value = loadedBonDeCommandes;

      // Sauvegarder dans le cache
      CacheHelper.set(cacheKey, loadedBonDeCommandes);
    } catch (e) {
      bonDeCommandes.value = [];
      // Ne pas afficher d'erreur si c'est une erreur d'authentification
      // (elle est déjà gérée par AuthErrorHandler)
      final errorString = e.toString().toLowerCase();
      if (!errorString.contains('session expirée') &&
          !errorString.contains('401') &&
          !errorString.contains('unauthorized')) {
        Get.snackbar(
          'Erreur',
          'Impossible de charger les bons de commande: ${e.toString()}',
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

  Future<void> loadClients() async {
    try {
      isLoadingClients.value = true;
      final clients = await _clientService.getClients(status: 1);
      availableClients.value = clients;
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isLoadingClients.value = false;
    }
  }

  Future<void> loadSuppliers() async {
    try {
      isLoadingSuppliers.value = true;
      final suppliers = await _supplierService.getSuppliers();
      availableSuppliers.value = suppliers;
    } catch (e) {
      // Erreur silencieuse
    } finally {
      isLoadingSuppliers.value = false;
    }
  }

  Future<bool> createBonDeCommande(Map<String, dynamic> data) async {
    try {
      if (selectedSupplier.value == null) {
        throw Exception('Veuillez sélectionner un fournisseur');
      }

      if (selectedSupplier.value!.id == null) {
        throw Exception(
          'L\'ID du fournisseur est manquant. Veuillez sélectionner un fournisseur valide.',
        );
      }

      if (items.isEmpty) {
        throw Exception('Aucun article ajouté au bon de commande');
      }

      // Valider les items
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        if (item.designation.isEmpty) {
          throw Exception('La désignation de l\'article ${i + 1} est requise');
        }
        if (item.quantite <= 0) {
          throw Exception(
            'La quantité de l\'article ${i + 1} doit être supérieure à 0',
          );
        }
        if (item.prixUnitaire <= 0) {
          throw Exception(
            'Le prix unitaire de l\'article ${i + 1} doit être supérieur à 0',
          );
        }
      }

      // Utiliser le numéro généré si disponible, sinon celui fourni
      final numeroCommande =
          generatedNumeroCommande.value.isNotEmpty
              ? generatedNumeroCommande.value
              : data['numero_commande'];

      final newBonDeCommande = BonDeCommande(
        clientId: null, // Pas de client pour un bon de commande fournisseur
        fournisseurId: selectedSupplier.value!.id!,
        numeroCommande: numeroCommande,
        dateCommande: data['date_commande'] ?? DateTime.now(),
        description: data['description'],
        statut: 'en_attente',
        commentaire: data['commentaire'],
        conditionsPaiement: data['conditions_paiement'],
        delaiLivraison: data['delai_livraison'],
        items: items.toList(),
      );

      // Afficher le loader seulement pendant la création
      isLoading.value = true;

      AppLogger.info(
        'Création du bon de commande fournisseur: $numeroCommande',
        tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
      );

      final createdBonDeCommande = await _service.createBonDeCommande(
        newBonDeCommande,
      );

      AppLogger.info(
        'Bon de commande créé avec succès: ID ${createdBonDeCommande.id}',
        tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
      );

      // Invalider le cache
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      // Ajouter le bon de commande à la liste localement (mise à jour optimiste)
      // Le nouveau bon de commande a toujours le statut 'en_attente'
      if (createdBonDeCommande.id != null) {
        bonDeCommandes.insert(0, createdBonDeCommande);
        AppLogger.info(
          'Bon de commande ajouté à la liste: ${createdBonDeCommande.numeroCommande} (ID: ${createdBonDeCommande.id})',
          tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
        );
      }

      // Arrêter le loader immédiatement pour permettre la fermeture du formulaire
      isLoading.value = false;

      // Rafraîchir les compteurs du dashboard patron en arrière-plan
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );
      });

      // Afficher le message de succès
      Get.snackbar(
        'Succès',
        'Bon de commande créé avec succès',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // Réinitialiser le formulaire
      clearForm();

      // Recharger la liste en arrière-plan après un court délai pour synchroniser avec le serveur
      // Le bon de commande est déjà dans la liste, donc il restera visible même si le rechargement échoue
      Future.microtask(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        try {
          // Recharger avec le statut actuel pour synchroniser avec le serveur
          await loadBonDeCommandes(status: _currentStatus, forceRefresh: true);

          // Vérifier que le bon de commande créé est toujours dans la liste après rechargement
          if (createdBonDeCommande.id != null) {
            final bonDeCommandeExists = bonDeCommandes.any(
              (bc) => bc.id == createdBonDeCommande.id,
            );
            if (!bonDeCommandeExists) {
              // Si le bon de commande n'est pas dans la liste après rechargement, le rajouter
              AppLogger.warning(
                'Bon de commande créé non trouvé après rechargement, réajout à la liste',
                tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
              );
              bonDeCommandes.insert(0, createdBonDeCommande);
            }
          }

          AppLogger.info(
            'Liste rechargée après création du bon de commande',
            tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
          );
        } catch (e) {
          // Si le rechargement échoue, le bon de commande reste dans la liste grâce à la mise à jour optimiste
          AppLogger.warning(
            'Erreur lors du rechargement après création: $e',
            tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
          );
          // Ne pas afficher d'erreur car le bon de commande a été créé avec succès et est déjà dans la liste
        }
      });

      return true;
    } catch (e) {
      // S'assurer que le loader est arrêté en cas d'erreur
      isLoading.value = false;

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
    }
  }

  Future<bool> updateBonDeCommande(
    int bonDeCommandeId,
    Map<String, dynamic> data,
  ) async {
    try {
      isLoading.value = true;
      final bonDeCommandeToUpdate = bonDeCommandes.firstWhere(
        (b) => b.id == bonDeCommandeId,
      );
      final updatedBonDeCommande = BonDeCommande(
        id: bonDeCommandeId,
        clientId: data['client_id'] ?? bonDeCommandeToUpdate.clientId,
        fournisseurId:
            data['fournisseur_id'] ?? bonDeCommandeToUpdate.fournisseurId,
        numeroCommande:
            data['numero_commande'] ?? bonDeCommandeToUpdate.numeroCommande,
        dateCommande: bonDeCommandeToUpdate.dateCommande,
        description: data['description'] ?? bonDeCommandeToUpdate.description,
        statut: bonDeCommandeToUpdate.statut,
        commentaire: data['commentaire'] ?? bonDeCommandeToUpdate.commentaire,
        conditionsPaiement:
            data['conditions_paiement'] ??
            bonDeCommandeToUpdate.conditionsPaiement,
        delaiLivraison:
            data['delai_livraison'] ?? bonDeCommandeToUpdate.delaiLivraison,
        items: items.isEmpty ? bonDeCommandeToUpdate.items : items,
      );

      await _service.updateBonDeCommande(bonDeCommandeId, updatedBonDeCommande);
      Get.snackbar(
        'Succès',
        'Bon de commande mis à jour avec succès',
        snackPosition: SnackPosition.BOTTOM,
      );
      loadBonDeCommandes();
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

  Future<void> deleteBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading.value = true;
      final success = await _service.deleteBonDeCommande(bonDeCommandeId);
      if (success) {
        bonDeCommandes.removeWhere((b) => b.id == bonDeCommandeId);
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

  Future<void> approveBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      final success = await _service.validateBonDeCommande(bonDeCommandeId);

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );

        Get.snackbar(
          'Succès',
          'Bon de commande approuvé avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadBonDeCommandes(status: _currentStatus).catchError((e) {
            // En cas d'erreur, on garde la mise à jour optimiste
          });
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadBonDeCommandes(status: _currentStatus);
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> rejectBonDeCommande(
    int bonDeCommandeId,
    String commentaire,
  ) async {
    try {
      isLoading.value = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      final success = await _service.rejectBonDeCommande(
        bonDeCommandeId,
        commentaire,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );

        Get.snackbar(
          'Succès',
          'Bon de commande rejeté avec succès',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );

        // Recharger les données en arrière-plan avec le statut actuel
        // pour synchroniser avec le serveur (mais garder la mise à jour optimiste)
        Future.delayed(const Duration(milliseconds: 500), () {
          loadBonDeCommandes(status: _currentStatus).catchError((e) {
            // En cas d'erreur, on garde la mise à jour optimiste
          });
        });
      } else {
        // En cas d'échec, recharger pour restaurer l'état
        await loadBonDeCommandes(status: _currentStatus);
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading.value = false;
    }
  }

  // Gestion des items
  void addItem(BonDeCommandeItem item) {
    items.add(item);
  }

  void removeItem(int index) {
    items.removeAt(index);
  }

  void updateItem(int index, BonDeCommandeItem item) {
    items[index] = item;
  }

  void clearItems() {
    items.clear();
  }

  void selectClient(Client? client) {
    selectedClient.value = client;
  }

  void selectSupplier(Supplier? supplier) {
    selectedSupplier.value = supplier;
  }

  void clearForm() {
    selectedClient.value = null;
    selectedSupplier.value = null;
    items.clear();
    generatedNumeroCommande.value = '';
    // Régénérer un nouveau numéro de commande
    initializeGeneratedNumeroCommande();
  }

  Future<void> generatePDF(int bonDeCommandeId) async {
    try {
      isLoading.value = true;

      final bonDeCommande = bonDeCommandes.firstWhere(
        (bc) => bc.id == bonDeCommandeId,
      );

      final itemsData =
          bonDeCommande.items
              .map(
                (item) => {
                  'ref': item.ref ?? '',
                  'designation': item.designation,
                  'quantite': item.quantite,
                  'prix_unitaire': item.prixUnitaire,
                  'montant_total': item.montantTotal,
                },
              )
              .toList();

      await PdfService().generateBonCommandePdf(
        bonCommande: {
          'reference': bonDeCommande.numeroCommande,
          'date_creation': bonDeCommande.dateCommande,
          'montant_ht': bonDeCommande.montantTotalCalcule,
          'tva': 0.0,
          'total_ttc': bonDeCommande.montantTotalCalcule,
        },
        items: itemsData,
        fournisseur: {
          'nom': selectedSupplier.value?.nom ?? 'N/A',
          'email': selectedSupplier.value?.email ?? '',
          'contact': selectedSupplier.value?.telephone ?? '',
          'adresse': selectedSupplier.value?.adresse ?? '',
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
