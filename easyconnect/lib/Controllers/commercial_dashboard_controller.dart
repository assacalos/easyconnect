import 'dart:async';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/services/task_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:get_storage/get_storage.dart';

class CommercialDashboardController extends BaseDashboardController {
  String currentSection = 'dashboard';
  String selectedPeriod = 'month';
  String selectedDepartment = 'all';

  final ClientService _clientService = ClientService();
  final DevisService _devisService = DevisService();
  final BordereauService _bordereauService = BordereauService();
  final BonCommandeService _bonCommandeService = BonCommandeService();
  final BonDeCommandeFournisseurService _bonCommandeFournisseurService =
      BonDeCommandeFournisseurService();
  final TaskService _taskService = TaskService.to;

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.COMMERCIAL);

  final List<ChartData> revenueData = [];
  final List<ChartData> clientData = [];
  final List<ChartData> devisData = [];
  final List<ChartData> bordereauData = [];

  int pendingClients = 0;
  int pendingDevis = 0;
  int pendingBordereaux = 0;
  int pendingBonCommandes = 0;
  int pendingBonCommandesFournisseur = 0;
  int pendingTasks = 0;

  int validatedClients = 0;
  int validatedDevis = 0;
  int validatedBordereaux = 0;
  int validatedBonCommandes = 0;

  double totalRevenue = 0.0;
  double pendingDevisAmount = 0.0;
  double paidBordereauxAmount = 0.0;

  Timer? _refreshTimer;

  CommercialDashboardController() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshPendingEntities();
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
  }

  Future<void> refreshPendingEntities() async {
    try {
      final authController = AuthController.to;
      final token = GetStorage().read<String?>('token');
      final user = authController.userAuth;

      if (token == null || user == null) {
        _refreshTimer?.cancel();
        return;
      }

      isLoading = true;
      try {
        await _loadPendingEntities();
        await _loadValidatedEntities();
        await _loadStatistics();
      } finally {
        isLoading = false;
      }
    } catch (e) {
      _refreshTimer?.cancel();
      isLoading = false;
    }
  }

  List<StatCard> get stats => [
    StatCard(
      title: "Clients",
      value: validatedClients.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    StatCard(
      title: "Devis",
      value: validatedDevis.toString(),
      icon: Icons.description,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_DEVIS,
    ),
    StatCard(
      title: "Bordereaux",
      value: validatedBordereaux.toString(),
      icon: Icons.assignment_turned_in,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_SALES,
    ),
    StatCard(
      title: "Bons de Commande",
      value: validatedBonCommandes.toString(),
      icon: Icons.shopping_cart,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_SALES,
    ),
  ];

  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Clients en attente",
      value: pendingClients.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_CLIENTS,
    ),
    StatCard(
      title: "Devis en attente",
      value: pendingDevis.toString(),
      icon: Icons.description,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_DEVIS,
    ),
    StatCard(
      title: "Bordereaux en attente",
      value: pendingBordereaux.toString(),
      icon: Icons.assignment_turned_in,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_BORDEREAUX,
    ),
    StatCard(
      title: "Bons en attente",
      value: pendingBonCommandes.toString(),
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
    final cachedPendingClients = CacheHelper.get<int>(
      'dashboard_commercial_pendingClients',
    );
    if (cachedPendingClients != null)
      pendingClients = cachedPendingClients;

    final cachedPendingDevis = CacheHelper.get<int>(
      'dashboard_commercial_pendingDevis',
    );
    if (cachedPendingDevis != null) pendingDevis = cachedPendingDevis;

    final cachedPendingBordereaux = CacheHelper.get<int>(
      'dashboard_commercial_pendingBordereaux',
    );
    if (cachedPendingBordereaux != null)
      pendingBordereaux = cachedPendingBordereaux;

    final cachedPendingBonCommandes = CacheHelper.get<int>(
      'dashboard_commercial_pendingBonCommandes',
    );
    if (cachedPendingBonCommandes != null)
      pendingBonCommandes = cachedPendingBonCommandes;

    final cachedValidatedClients = CacheHelper.get<int>(
      'dashboard_commercial_validatedClients',
    );
    if (cachedValidatedClients != null)
      validatedClients = cachedValidatedClients;

    final cachedTotalRevenue = CacheHelper.get<double>(
      'dashboard_commercial_totalRevenue',
    );
    if (cachedTotalRevenue != null) totalRevenue = cachedTotalRevenue;
  }

  @override
  Future<void> loadData() async {
    if (isLoading) return;
    isLoading = false;

    try {
      _loadPendingEntities().catchError((e) {});
      _loadValidatedEntities().catchError((e) {});
      _loadStatistics().catchError((e) {});

      revenueData.clear();
      revenueData.addAll([
        ChartData(1, 85000, "Janvier"),
        ChartData(2, 92000, "Février"),
        ChartData(3, 88000, "Mars"),
        ChartData(4, 95000, "Avril"),
        ChartData(5, 103000, "Mai"),
        ChartData(6, 110000, "Juin"),
      ]);

      clientData.clear();
      clientData.addAll([
        ChartData(1, 35, "Nouveaux"),
        ChartData(2, 25, "Actifs"),
        ChartData(3, 20, "Inactifs"),
        ChartData(4, 10, "Prospects"),
      ]);

      devisData.clear();
      devisData.addAll([
        ChartData(1, 45, "En attente"),
        ChartData(2, 15, "Acceptés"),
        ChartData(3, 8, "Refusés"),
        ChartData(4, 2, "Expirés"),
      ]);

      bordereauData.clear();
      bordereauData.addAll([
        ChartData(1, 12, "En cours"),
        ChartData(2, 15, "Payés"),
        ChartData(3, 8, "En retard"),
        ChartData(4, 10, "Annulés"),
      ]);

      updateChartData('revenue', revenueData);
      updateChartData('clients', clientData);
      updateChartData('devis', devisData);
      updateChartData('bordereaux', bordereauData);
    } catch (e) {
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
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
      pendingClients = pendingClientsCount;
      CacheHelper.set(
        'dashboard_commercial_pendingClients',
        pendingClientsCount,
      );

      final devis = results[1] as List;
      final pendingDevisCount = devis.where((d) => d.status == 1).length;
      pendingDevis = pendingDevisCount;
      CacheHelper.set('dashboard_commercial_pendingDevis', pendingDevisCount);

      final bordereaux = results[2] as List;
      final pendingBordereauxCount =
          bordereaux.where((b) => b.status == 1).length;
      pendingBordereaux = pendingBordereauxCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBordereaux',
        pendingBordereauxCount,
      );

      final bonCommandes = results[3] as List;
      final pendingBonCommandesCount =
          bonCommandes.where((bc) => bc.status == 1).length;
      pendingBonCommandes = pendingBonCommandesCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBonCommandes',
        pendingBonCommandesCount,
      );

      final bonCommandesFournisseur = results[4] as List;
      final pendingBonCommandesFournisseurCount =
          bonCommandesFournisseur.where((bc) {
            final statut = bc.statut?.toString().toLowerCase().trim() ?? '';
            return statut == 'en_attente' || statut == 'pending';
          }).length;
      pendingBonCommandesFournisseur = pendingBonCommandesFournisseurCount;
      CacheHelper.set(
        'dashboard_commercial_pendingBonCommandesFournisseur',
        pendingBonCommandesFournisseurCount,
      );

      await _loadPendingTasks();
    } catch (e) {
      // Ne pas réinitialiser
    }
  }

  Future<void> _loadPendingTasks() async {
    try {
      final result = await _taskService.getTasks(
        status: 'pending',
        page: 1,
        perPage: 1,
      );
      if (result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        final count = pagination['total'] as int? ?? 0;
        pendingTasks = count;
      }
    } catch (e) {}
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final results = await Future.wait([
        _clientService.getClients(),
        _devisService.getDevis(),
        _bordereauService.getBordereaux(),
        _bonCommandeService.getBonCommandes(),
      ], eagerError: false);

      final clients = results[0] as List;
      final validatedClientsCount = clients.where((c) => c.status == 1).length;
      validatedClients = validatedClientsCount;
      CacheHelper.set(
        'dashboard_commercial_validatedClients',
        validatedClientsCount,
      );

      final devis = results[1] as List;
      validatedDevis = devis.length - pendingDevis;

      final bordereaux = results[2] as List;
      validatedBordereaux = bordereaux.length - pendingBordereaux;

      final bonCommandes = results[3] as List;
      validatedBonCommandes =
          bonCommandes.length - pendingBonCommandes;
    } catch (e) {}
  }

  Future<void> _loadStatistics() async {
    try {
      final allDevis = await _devisService.getDevis();
      final revenue = allDevis.fold(0.0, (sum, d) => sum + d.totalTTC);
      totalRevenue = revenue;
      CacheHelper.set('dashboard_commercial_totalRevenue', revenue);

      pendingDevisAmount = allDevis
          .where((d) => d.status == 1)
          .fold(0.0, (sum, d) => sum + d.totalTTC);

      final bordereaux = await _bordereauService.getBordereaux();
      paidBordereauxAmount = bordereaux
          .where((b) => b.status == 2)
          .fold(0.0, (sum, b) => sum + b.montantTTC);
    } catch (e) {}
  }
}
