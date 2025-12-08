import 'dart:async';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class CommercialDashboardController extends BaseDashboardController {
  var currentSection = 'dashboard'.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Service pour récupérer les données
  final ClientService _clientService = Get.find<ClientService>();
  final DevisService _devisService = Get.find<DevisService>();
  final BordereauService _bordereauService = Get.find<BordereauService>();
  final BonCommandeService _bonCommandeService = Get.find<BonCommandeService>();
  final BonDeCommandeFournisseurService _bonCommandeFournisseurService =
      Get.find<BonDeCommandeFournisseurService>();
  final InvoiceService _invoiceService = Get.find<InvoiceService>();

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.COMMERCIAL);

  // Données des graphiques
  final revenueData = <ChartData>[].obs;
  final clientData = <ChartData>[].obs;
  final devisData = <ChartData>[].obs;
  final bordereauData = <ChartData>[].obs;

  // Nouvelles données pour le dashboard amélioré
  // Première partie - Entités en attente
  final pendingClients = 0.obs;
  final pendingDevis = 0.obs;
  final pendingBordereaux = 0.obs;
  final pendingBonCommandes = 0.obs; // Bons de commande entreprise
  final pendingBonCommandesFournisseur = 0.obs; // Bons de commande fournisseur

  // Deuxième partie - Entités validées
  final validatedClients = 0.obs;
  final validatedDevis = 0.obs;
  final validatedBordereaux = 0.obs;
  final validatedBonCommandes = 0.obs;

  // Troisième partie - Statistiques montants
  final totalRevenue = 0.0.obs;
  final pendingDevisAmount = 0.0.obs;
  final paidBordereauxAmount = 0.0.obs;

  // Timers pour le rafraîchissement automatique
  Timer? _setupTimer;
  Timer? _refreshTimer;
  bool _hasClientListener = false;
  bool _hasDevisListener = false;
  bool _hasBordereauListener = false;
  bool _hasBonCommandeListener = false;

  @override
  void onInit() {
    super.onInit();
    _trySetupListeners();

    // Si les contrôleurs ne sont pas encore disponibles, réessayer périodiquement
    _setupTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_hasClientListener ||
          !_hasDevisListener ||
          !_hasBordereauListener ||
          !_hasBonCommandeListener) {
        _trySetupListeners();
      } else {
        // Une fois tous les listeners configurés, annuler le timer
        _setupTimer?.cancel();
      }
    });

    // Ajouter un rafraîchissement périodique automatique toutes les 20 secondes
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshPendingEntities();
    });
  }

  void _trySetupListeners() {
    // Écouter les changements dans ClientController
    if (!_hasClientListener) {
      try {
        if (Get.isRegistered<ClientController>()) {
          final clientController = Get.find<ClientController>();
          ever(clientController.clients, (_) {
            refreshPendingEntities();
          });
          _hasClientListener = true;
        }
      } catch (e) {}
    }

    // Écouter les changements dans DevisController
    if (!_hasDevisListener) {
      try {
        if (Get.isRegistered<DevisController>()) {
          final devisController = Get.find<DevisController>();
          ever(devisController.devis, (_) {
            refreshPendingEntities();
          });
          _hasDevisListener = true;
        }
      } catch (e) {}
    }

    // Écouter les changements dans BordereauxController
    if (!_hasBordereauListener) {
      try {
        if (Get.isRegistered<BordereauxController>()) {
          final bordereauController = Get.find<BordereauxController>();
          ever(bordereauController.bordereaux, (_) {
            refreshPendingEntities();
          });
          _hasBordereauListener = true;
        }
      } catch (e) {}
    }

    // Écouter les changements dans BonCommandeController
    if (!_hasBonCommandeListener) {
      try {
        if (Get.isRegistered<BonCommandeController>()) {
          final bonCommandeController = Get.find<BonCommandeController>();
          ever(bonCommandeController.bonCommandes, (_) {
            refreshPendingEntities();
          });
          _hasBonCommandeListener = true;
        }
      } catch (e) {}
    }
  }

  @override
  void onClose() {
    _setupTimer?.cancel();
    _refreshTimer?.cancel();
    super.onClose();
  }

  // Méthode pour recharger uniquement les entités en attente (appelée depuis l'extérieur)
  Future<void> refreshPendingEntities() async {
    // Vérifier si l'utilisateur est toujours connecté avant de charger
    try {
      if (!Get.isRegistered<AuthController>()) {
        _setupTimer?.cancel();
        _refreshTimer?.cancel();
        return;
      }

      final authController = Get.find<AuthController>();
      final token = authController.storage.read<String?>('token');
      final user = authController.userAuth.value;

      if (token == null || user == null) {
        // L'utilisateur s'est déconnecté, arrêter le rafraîchissement
        _setupTimer?.cancel();
        _refreshTimer?.cancel();
        return;
      }

      await _loadPendingEntities();
      await _loadValidatedEntities();
      await _loadStatistics();
    } catch (e) {
      // Si le contrôleur n'existe plus, arrêter les timers
      _setupTimer?.cancel();
      _refreshTimer?.cancel();
    }
  }

  // Statistiques originales
  List<StatCard> get stats => [
    StatCard(
      title: "Clients",
      value: validatedClients.value.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    StatCard(
      title: "Devis",
      value: validatedDevis.value.toString(),
      icon: Icons.description,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_DEVIS,
    ),
    StatCard(
      title: "Bordereaux",
      value: validatedBordereaux.value.toString(),
      icon: Icons.assignment_turned_in,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_SALES,
    ),
    StatCard(
      title: "Bons de Commande",
      value: validatedBonCommandes.value.toString(),
      icon: Icons.shopping_cart,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_SALES,
    ),
  ];

  // Nouvelles statistiques pour le dashboard amélioré
  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Clients en attente",
      value: pendingClients.value.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    StatCard(
      title: "Devis en attente",
      value: pendingDevis.value.toString(),
      icon: Icons.description,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_DEVIS,
    ),
    StatCard(
      title: "Bordereaux en attente",
      value: pendingBordereaux.value.toString(),
      icon: Icons.assignment_turned_in,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_BORDEREAUX,
    ),
    StatCard(
      title: "Bons en attente",
      value: pendingBonCommandes.value.toString(),
      icon: Icons.shopping_cart,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_BON_COMMANDES,
    ),
  ];

  void onFilterChanged(Filter filter) {
    if (activeFilters.contains(filter)) {
      activeFilters.remove(filter);
    } else {
      activeFilters.add(filter);
    }
    loadData();
  }

  @override
  void loadCachedData() {
    // Charger les données depuis le cache pour un affichage instantané
    final cachedPendingClients = CacheHelper.get<int>(
      'dashboard_commercial_pendingClients',
    );
    if (cachedPendingClients != null)
      pendingClients.value = cachedPendingClients;

    final cachedPendingDevis = CacheHelper.get<int>(
      'dashboard_commercial_pendingDevis',
    );
    if (cachedPendingDevis != null) pendingDevis.value = cachedPendingDevis;

    final cachedPendingBordereaux = CacheHelper.get<int>(
      'dashboard_commercial_pendingBordereaux',
    );
    if (cachedPendingBordereaux != null)
      pendingBordereaux.value = cachedPendingBordereaux;

    final cachedPendingBonCommandes = CacheHelper.get<int>(
      'dashboard_commercial_pendingBonCommandes',
    );
    if (cachedPendingBonCommandes != null)
      pendingBonCommandes.value = cachedPendingBonCommandes;

    final cachedValidatedClients = CacheHelper.get<int>(
      'dashboard_commercial_validatedClients',
    );
    if (cachedValidatedClients != null)
      validatedClients.value = cachedValidatedClients;

    final cachedTotalRevenue = CacheHelper.get<double>(
      'dashboard_commercial_totalRevenue',
    );
    if (cachedTotalRevenue != null) totalRevenue.value = cachedTotalRevenue;
  }

  @override
  Future<void> loadData() async {
    if (isLoading.value) return;
    // Ne pas bloquer l'UI - charger en arrière-plan
    isLoading.value = false; // Permettre l'affichage immédiat

    try {
      // Charger les données des entités en attente (non-bloquant)
      _loadPendingEntities().catchError((e) {});

      // Charger les données des entités validées (non-bloquant)
      _loadValidatedEntities().catchError((e) {});

      // Charger les statistiques montants (non-bloquant)
      _loadStatistics().catchError((e) {});

      // Simuler le chargement des données des graphiques
      revenueData.value = [
        ChartData(1, 85000, "Janvier"),
        ChartData(2, 92000, "Février"),
        ChartData(3, 88000, "Mars"),
        ChartData(4, 95000, "Avril"),
        ChartData(5, 103000, "Mai"),
        ChartData(6, 110000, "Juin"),
      ];

      clientData.value = [
        ChartData(1, 35, "Nouveaux"),
        ChartData(2, 25, "Actifs"),
        ChartData(3, 20, "Inactifs"),
        ChartData(4, 10, "Prospects"),
      ];

      devisData.value = [
        ChartData(1, 45, "En attente"),
        ChartData(2, 15, "Acceptés"),
        ChartData(3, 8, "Refusés"),
        ChartData(4, 2, "Expirés"),
      ];

      bordereauData.value = [
        ChartData(1, 12, "En cours"),
        ChartData(2, 15, "Payés"),
        ChartData(3, 8, "En retard"),
        ChartData(4, 10, "Annulés"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('revenue', revenueData);
      updateChartData('clients', clientData);
      updateChartData('devis', devisData);
      updateChartData('bordereaux', bordereauData);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      // OPTIMISATION : Charger toutes les entités en parallèle
      final results = await Future.wait([
        _clientService.getClients(),
        _devisService.getDevis(),
        _bordereauService.getBordereaux(),
        _bonCommandeService.getBonCommandes(),
        _bonCommandeFournisseurService.getBonDeCommandes(),
      ], eagerError: false);

      final clients = results[0] as List;
      final pendingClientsCount =
          clients.where((c) => c.status == 0 || c.status == null).length;
      pendingClients.value = pendingClientsCount;
      CacheHelper.set(
        'dashboard_commercial_pendingClients',
        pendingClientsCount,
      );

      final devis = results[1] as List;
      final pendingDevisCount = devis.where((d) => d.status == 1).length;
      pendingDevis.value = pendingDevisCount;
      CacheHelper.set('dashboard_commercial_pendingDevis', pendingDevisCount);

      final bordereaux = results[2] as List;
      final pendingBordereauxCount =
          bordereaux.where((b) => b.status == 1).length;
      pendingBordereaux.value = pendingBordereauxCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBordereaux',
        pendingBordereauxCount,
      );

      // Bons de commande entreprise (status 1 = en attente)
      final bonCommandes = results[3] as List;
      final pendingBonCommandesCount =
          bonCommandes.where((bc) => bc.status == 1).length;
      pendingBonCommandes.value = pendingBonCommandesCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBonCommandes',
        pendingBonCommandesCount,
      );

      // Bons de commande fournisseur (statut 'en_attente' ou 'pending')
      final bonCommandesFournisseur = results[4] as List;
      final pendingBonCommandesFournisseurCount =
          bonCommandesFournisseur.where((bc) {
            final statut = bc.statut?.toString().toLowerCase().trim() ?? '';
            return statut == 'en_attente' || statut == 'pending';
          }).length;
      pendingBonCommandesFournisseur.value =
          pendingBonCommandesFournisseurCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBonCommandesFournisseur',
        pendingBonCommandesFournisseurCount,
      );
    } catch (e) {
      pendingClients.value = 0;
      pendingDevis.value = 0;
      pendingBordereaux.value = 0;
      pendingBonCommandes.value = 0;
      pendingBonCommandesFournisseur.value = 0;
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      // OPTIMISATION : Charger toutes les entités en parallèle
      final results = await Future.wait([
        _clientService.getClients(),
        _devisService.getDevis(),
        _bordereauService.getBordereaux(),
        _bonCommandeService.getBonCommandes(),
      ], eagerError: false);

      final clients = results[0] as List;
      final validatedClientsCount = clients.where((c) => c.status == 1).length;
      validatedClients.value = validatedClientsCount;
      CacheHelper.set(
        'dashboard_commercial_validatedClients',
        validatedClientsCount,
      );

      final devis = results[1] as List;
      validatedDevis.value = devis.length - pendingDevis.value;

      final bordereaux = results[2] as List;
      validatedBordereaux.value = bordereaux.length - pendingBordereaux.value;

      final bonCommandes = results[3] as List;
      validatedBonCommandes.value =
          bonCommandes.length - pendingBonCommandes.value;
    } catch (e) {
      validatedClients.value = 0;
      validatedDevis.value = 0;
      validatedBordereaux.value = 0;
      validatedBonCommandes.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      // Calculer le total des factures validées (chiffre d'affaires)
      final statusLower = (String status) => status.toLowerCase().trim();
      final revenue = invoices
          .where((f) {
            final status = statusLower(f.status);
            return status == 'valide' ||
                status == 'validated' ||
                status == 'approved';
          })
          .fold(0.0, (sum, f) => sum + f.totalAmount);
      totalRevenue.value = revenue;
      CacheHelper.set('dashboard_commercial_totalRevenue', revenue);

      final allDevis = await _devisService.getDevis();
      pendingDevisAmount.value = allDevis
          .where((d) => d.status == 1)
          .fold(0.0, (sum, d) => sum + d.totalTTC);

      final bordereaux = await _bordereauService.getBordereaux();
      paidBordereauxAmount.value = bordereaux
          .where((b) => b.status == 2)
          .fold(0.0, (sum, b) => sum + b.montantTTC);
    } catch (e) {
      totalRevenue.value = 0.0;
      pendingDevisAmount.value = 0.0;
      paidBordereauxAmount.value = 0.0;
    }
  }
}
