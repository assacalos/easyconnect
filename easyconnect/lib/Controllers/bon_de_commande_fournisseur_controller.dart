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
import 'package:easyconnect/utils/notification_helper.dart';
import 'package:easyconnect/utils/error_helper.dart';

BonDeCommande? _firstWhereBonDeCommandeById(List<BonDeCommande> list, int id) {
  try {
    return list.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}

class BonDeCommandeFournisseurController {
  static final BonDeCommandeFournisseurController _instance = BonDeCommandeFournisseurController._();
  static BonDeCommandeFournisseurController get to => _instance;
  factory BonDeCommandeFournisseurController() => _instance;
  BonDeCommandeFournisseurController._();

  int get userId => int.parse(AuthController.to.userAuth?.id.toString() ?? '0');

  final BonDeCommandeFournisseurService _service = BonDeCommandeFournisseurService();
  final ClientService _clientService = ClientService();
  final SupplierService _supplierService = SupplierService();

  final List<BonDeCommande> bonDeCommandes = [];
  Client? selectedClient;
  Supplier? selectedSupplier;
  final List<Client> availableClients = [];
  final List<Supplier> availableSuppliers = [];
  bool isLoading = false;
  bool isLoadingClients = false;
  bool isLoadingSuppliers = false;
  BonDeCommande? currentBonDeCommande;
  final List<BonDeCommandeItem> items = [];

  // Référence générée automatiquement
  String generatedNumeroCommande = '';

  // Gestion des onglets : la vue crée le TabController et l'assigne via setTabController
  TabController? _tabController;
  String? selectedStatus;
  String? _currentStatus;

  // Statistiques
  int totalBonDeCommandes = 0;
  int bonDeCommandesEnAttente = 0;
  int bonDeCommandesValides = 0;
  int bonDeCommandesRejetes = 0;
  int bonDeCommandesLivres = 0;
  double montantTotal = 0.0;

  void setTabController(TabController c) {
    _tabController?.removeListener(_onTabChanged);
    _tabController = c;
    _tabController!.addListener(_onTabChanged);
  }

  /// À appeler au premier affichage (ex: depuis la vue) pour charger les données et les fournisseurs.
  void ensureInitialized() {
    loadBonDeCommandes();
    loadSuppliers();
    if (generatedNumeroCommande.isEmpty) {
      initializeGeneratedNumeroCommande();
    }
  }

  // Générer automatiquement le numéro de commande fournisseur
  Future<String> generateNumeroCommande() async {
    if (bonDeCommandes.isEmpty) await loadBonDeCommandes();

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
    if (generatedNumeroCommande.isEmpty) {
      generatedNumeroCommande = await generateNumeroCommande();
    }
  }

  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _tabController = null;
  }

  void _onTabChanged() {
    if (_tabController == null || !_tabController!.indexIsChanging) return;
    selectedStatus =
        _tabController!.index == 0
            ? null
            : _getStatusFromIndex(_tabController!.index);
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
    if (selectedStatus == null || selectedStatus == 'all') {
      return bonDeCommandes;
    }

    // Filtrer par statut (comparaison insensible à la casse)
    final statusLower = selectedStatus!.toLowerCase().trim();
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
    AppLogger.info(
      'loadBonDeCommandes: status=$status, forceRefresh=$forceRefresh',
      tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
    );
    final cacheKey = 'bon_de_commandes_fournisseur_${status ?? 'all'}';
    try {
      _currentStatus = status;

      // Mettre à jour le statut sélectionné
      if (status != null) {
        selectedStatus = status;
      } else {
        selectedStatus = 'all';
      }

      // Afficher immédiatement les données du cache si disponibles
      final cachedBonDeCommandes = CacheHelper.get<List<BonDeCommande>>(
        cacheKey,
      );
      if (cachedBonDeCommandes != null &&
          cachedBonDeCommandes.isNotEmpty &&
          !forceRefresh) {
        bonDeCommandes.clear();
        bonDeCommandes.addAll(cachedBonDeCommandes);
        isLoading = false; // Permettre l'affichage immédiat
        AppLogger.debug(
          'Données chargées depuis le cache: ${cachedBonDeCommandes.length} bons de commande',
          tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
        );
      } else {
        isLoading = true;
      }

      AppLogger.debug(
        'Appel API getBonDeCommandes (tous)',
        tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
      );
      final loadedBonDeCommandes = await _service.getBonDeCommandes();
      bonDeCommandes.clear();
      bonDeCommandes.addAll(loadedBonDeCommandes);
      AppLogger.info(
        'loadBonDeCommandes OK: ${loadedBonDeCommandes.length} éléments',
        tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
      );
      CacheHelper.set(cacheKey, loadedBonDeCommandes);
    } catch (e, st) {
      AppLogger.error(
        'loadBonDeCommandes erreur: $e',
        tag: 'BON_COMMANDE_FOURNISSEUR_CONTROLLER',
        stackTrace: st,
      );
      // Ne pas vider la liste si on a déjà des données (offline-first)
      if (bonDeCommandes.isEmpty) {
        final fallback = CacheHelper.get<List<BonDeCommande>>(cacheKey);
        if (fallback != null && fallback.isNotEmpty) {
          bonDeCommandes.clear();
          bonDeCommandes.addAll(fallback);
        } else {
          bonDeCommandes.clear();
          final errorString = e.toString().toLowerCase();
          if (!errorString.contains('session expirée') &&
              !errorString.contains('401') &&
              !errorString.contains('unauthorized')) {
            errorHelperShowSnackbar?.call(
              'Erreur',
              'Impossible de charger les bons de commande',
              duration: const Duration(seconds: 5),
            );
          }
        }
      }
    } finally {
      isLoading = false;
    }
  }

  /// Clients validés : cache Hive d'abord, puis API.
  Future<void> loadClients() async {
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
        }
      }
    } finally {
      isLoadingClients = false;
    }
  }

  /// Fournisseurs : cache Hive d'abord, puis API.
  Future<void> loadSuppliers() async {
    isLoadingSuppliers = true;
    final cached = SupplierService.getCachedFournisseurs();
    if (cached.isNotEmpty) {
      availableSuppliers.clear();
      availableSuppliers.addAll(cached);
      isLoadingSuppliers = false;
    } else {
      availableSuppliers.clear();
    }
    try {
      final suppliers = await _supplierService.getSuppliers();
      availableSuppliers.clear();
      availableSuppliers.addAll(suppliers);
    } catch (e) {
      if (availableSuppliers.isEmpty) {
        final fallback = SupplierService.getCachedFournisseurs();
        if (fallback.isNotEmpty) {
          availableSuppliers.clear();
          availableSuppliers.addAll(fallback);
        }
      }
    } finally {
      isLoadingSuppliers = false;
    }
  }

  Future<bool> createBonDeCommande(Map<String, dynamic> data) async {
    if (isLoading) return false;
    try {
      if (selectedSupplier == null) {
        throw Exception('Veuillez sélectionner un fournisseur');
      }

      if (selectedSupplier!.id == null) {
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
          generatedNumeroCommande.isNotEmpty
              ? generatedNumeroCommande
              : data['numero_commande'];

      final newBonDeCommande = BonDeCommande(
        clientId: null, // Pas de client pour un bon de commande fournisseur
        fournisseurId: selectedSupplier!.id!,
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
      isLoading = true;

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

      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      // Insertion locale uniquement si l'onglet actuel correspond. Nouveau bon = statut 'en_attente'
      const newStatus = 'en_attente';
      final shouldInsert = _currentStatus == null || _currentStatus == newStatus;
      if (shouldInsert && createdBonDeCommande.id != null) {
        bonDeCommandes.insert(0, createdBonDeCommande);
        final cacheKey = 'bon_de_commandes_fournisseur_${_currentStatus ?? 'all'}';
        CacheHelper.set(cacheKey, bonDeCommandes.toList());
      }

      if (createdBonDeCommande.id != null) {
        NotificationHelper.notifySubmission(
          entityType: 'bon_de_commande_fournisseur',
          entityName: NotificationHelper.getEntityDisplayName(
            'bon_de_commande_fournisseur',
            createdBonDeCommande,
          ),
          entityId: createdBonDeCommande.id.toString(),
          route: NotificationHelper.getEntityRoute(
            'bon_de_commande_fournisseur',
            createdBonDeCommande.id.toString(),
          ),
        );
      }

      isLoading = false;
      Future.microtask(() {
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );
      });
      errorHelperShowSnackbar?.call(
        'Succès',
        'Bon de commande créé avec succès',
        duration: const Duration(seconds: 3),
      );
      clearForm();
      // Pas de loadBonDeCommandes(forceRefresh: true) pour ne pas écraser l'insertion

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

      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      errorHelperShowSnackbar?.call(
        'Erreur',
        errorMessage,
        duration: const Duration(seconds: 5),
      );
      return false;
    }
  }

  Future<bool> updateBonDeCommande(
    int bonDeCommandeId,
    Map<String, dynamic> data,
  ) async {
    if (isLoading) return false;
    try {
      isLoading = true;
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
      errorHelperShowSnackbar?.call(
        'Succès',
        'Bon de commande mis à jour avec succès',
      );
      loadBonDeCommandes();
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

  Future<void> deleteBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading = true;
      final success = await _service.deleteBonDeCommande(bonDeCommandeId);
      if (success) {
        bonDeCommandes.removeWhere((b) => b.id == bonDeCommandeId);
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

  Future<void> approveBonDeCommande(int bonDeCommandeId) async {
    try {
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      final success = await _service.validateBonDeCommande(bonDeCommandeId);

      if (success) {
        // Rafraîchir les compteurs du dashboard patron et commercial
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );
        DashboardRefreshHelper.refreshCommercialDashboard();

        // Notifier l'utilisateur concerné de la validation
        final bonDeCommande = _firstWhereBonDeCommandeById(bonDeCommandes, bonDeCommandeId);
        if (bonDeCommande != null) {
          NotificationHelper.notifyValidation(
            entityType: 'bon_de_commande_fournisseur',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_de_commande_fournisseur',
              bonDeCommande,
            ),
            entityId: bonDeCommandeId.toString(),
            route: NotificationHelper.getEntityRoute(
              'bon_de_commande_fournisseur',
              bonDeCommandeId.toString(),
            ),
            entity: bonDeCommande,
          );
        }

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande approuvé avec succès',
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
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
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
    }
  }

  Future<void> rejectBonDeCommande(
    int bonDeCommandeId,
    String commentaire,
  ) async {
    try {
      isLoading = true;

      // Invalider le cache avant l'appel API
      CacheHelper.clearByPrefix('bon_de_commandes_fournisseur_');

      final success = await _service.rejectBonDeCommande(
        bonDeCommandeId,
        commentaire,
      );

      if (success) {
        // Rafraîchir les compteurs du dashboard patron et commercial
        DashboardRefreshHelper.refreshPatronCounter(
          'bon_de_commande_fournisseur',
        );
        DashboardRefreshHelper.refreshCommercialDashboard();

        // Notifier l'utilisateur concerné du rejet
        final bonDeCommande = _firstWhereBonDeCommandeById(bonDeCommandes, bonDeCommandeId);
        if (bonDeCommande != null) {
          NotificationHelper.notifyRejection(
            entityType: 'bon_de_commande_fournisseur',
            entityName: NotificationHelper.getEntityDisplayName(
              'bon_de_commande_fournisseur',
              bonDeCommande,
            ),
            entityId: bonDeCommandeId.toString(),
            reason: commentaire,
            route: NotificationHelper.getEntityRoute(
              'bon_de_commande_fournisseur',
              bonDeCommandeId.toString(),
            ),
            entity: bonDeCommande,
          );
        }

        errorHelperShowSnackbar?.call(
          'Succès',
          'Bon de commande rejeté avec succès',
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
        errorHelperShowSnackbar?.call(
          'Erreur',
          'Erreur d\'authentification. Veuillez vous reconnecter.',
        );
      } else {
        // Autre erreur - recharger pour vérifier l'état
        loadBonDeCommandes(status: _currentStatus).catchError((e) {});
        // Ne pas afficher d'erreur car l'action peut avoir réussi
      }
    } finally {
      isLoading = false;
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
    selectedClient = client;
  }

  void selectSupplier(Supplier? supplier) {
    selectedSupplier = supplier;
  }

  void clearForm() {
    selectedClient = null;
    selectedSupplier = null;
    items.clear();
    generatedNumeroCommande = '';
    // Régénérer un nouveau numéro de commande
    initializeGeneratedNumeroCommande();
  }

  Future<void> generatePDF(int bonDeCommandeId) async {
    try {
      isLoading = true;

      final bonDeCommande = bonDeCommandes.firstWhere(
        (bc) => bc.id == bonDeCommandeId,
      );

      final itemsData =
          bonDeCommande.items
              .map(
                (item) => {
                  'reference': item.ref ?? '',
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
          'titre': bonDeCommande.description,
          'date_creation': bonDeCommande.dateCommande,
          'montant_ht': bonDeCommande.montantTotalCalcule,
          'tva': 0.0,
          'total_ttc': bonDeCommande.montantTotalCalcule,
          'delai_livraison': bonDeCommande.delaiLivraison,
          'conditions_paiement': bonDeCommande.conditionsPaiement,
        },
        items: itemsData,
        fournisseur: {
          'nom': selectedSupplier?.nom ?? 'N/A',
          'email': selectedSupplier?.email ?? '',
          'contact': selectedSupplier?.telephone ?? '',
          'adresse': selectedSupplier?.adresse ?? '',
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
