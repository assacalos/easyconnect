import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/commercial_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/invoice_service.dart';

class CommercialDashboardController extends BaseDashboardController {
  var currentSection = 'dashboard'.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Service pour récupérer les données
  final CommercialDashboardService _dashboardService =
      CommercialDashboardService();
  final ClientService _clientService = Get.find<ClientService>();
  final DevisService _devisService = Get.find<DevisService>();
  final BordereauService _bordereauService = Get.find<BordereauService>();
  final BonCommandeService _bonCommandeService = Get.find<BonCommandeService>();
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
  final pendingBonCommandes = 0.obs;

  // Deuxième partie - Entités validées
  final validatedClients = 0.obs;
  final validatedDevis = 0.obs;
  final validatedBordereaux = 0.obs;
  final validatedBonCommandes = 0.obs;

  // Troisième partie - Statistiques montants
  final totalRevenue = 0.0.obs;
  final pendingDevisAmount = 0.0.obs;
  final paidBordereauxAmount = 0.0.obs;

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
  Future<void> loadData() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Charger les données des entités en attente
      await _loadPendingEntities();

      // Charger les données des entités validées
      await _loadValidatedEntities();

      // Charger les statistiques montants
      await _loadStatistics();

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
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      final clients = await _clientService.getClients();
      pendingClients.value =
          clients.where((c) => c.status == 0 || c.status == null).length;

      final devis = await _devisService.getDevis();
      pendingDevis.value = devis.where((d) => d.status == 1).length;

      final bordereaux = await _bordereauService.getBordereaux();
      pendingBordereaux.value = bordereaux.where((b) => b.status == 1).length;

      final bons = await _bonCommandeService.getBonCommandes();
      pendingBonCommandes.value = bons.where((b) => b.status == 0).length;
    } catch (e) {
      print('Erreur lors du chargement des entités en attente: $e');
      pendingClients.value = 0;
      pendingDevis.value = 0;
      pendingBordereaux.value = 0;
      pendingBonCommandes.value = 0;
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final clients = await _clientService.getClients();
      validatedClients.value = clients.where((c) => c.status == 1).length;

      final devis = await _devisService.getDevis();
      validatedDevis.value = devis.length - pendingDevis.value;

      final bordereaux = await _bordereauService.getBordereaux();
      validatedBordereaux.value = bordereaux.length - pendingBordereaux.value;

      final bons = await _bonCommandeService.getBonCommandes();
      validatedBonCommandes.value = bons.length - pendingBonCommandes.value;
    } catch (e) {
      print('Erreur lors du chargement des entités validées: $e');
      validatedClients.value = 0;
      validatedDevis.value = 0;
      validatedBordereaux.value = 0;
      validatedBonCommandes.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final invoices = await _invoiceService.getAllInvoices();
      totalRevenue.value = invoices
          .where((f) => f.status == 'paid')
          .fold(0.0, (sum, f) => sum + f.totalAmount);

      final allDevis = await _devisService.getDevis();
      pendingDevisAmount.value = allDevis
          .where((d) => d.status == 1)
          .fold(0.0, (sum, d) => sum + d.totalTTC);

      final bordereaux = await _bordereauService.getBordereaux();
      paidBordereauxAmount.value = bordereaux
          .where((b) => b.status == 2)
          .fold(0.0, (sum, b) => sum + b.montantTTC);
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      totalRevenue.value = 0.0;
      pendingDevisAmount.value = 0.0;
      paidBordereauxAmount.value = 0.0;
    }
  }
}
