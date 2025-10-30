import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/technicien_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';

class TechnicienDashboardController extends BaseDashboardController {
  var currentSection = 'dashboard'.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Service pour récupérer les données
  final TechnicienDashboardService _dashboardService =
      TechnicienDashboardService();
  final InterventionService _interventionService =
      Get.find<InterventionService>();
  final EquipmentService _equipmentService = Get.find<EquipmentService>();
  final ReportingService _reportingService = Get.find<ReportingService>();

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.TECHNICIEN);

  // Données des graphiques
  final interventionData = <ChartData>[].obs;
  final maintenanceData = <ChartData>[].obs;
  final equipmentData = <ChartData>[].obs;
  final reportData = <ChartData>[].obs;

  // Nouvelles données pour le dashboard amélioré
  // Première partie - Entités en attente
  final pendingInterventions = 0.obs;
  final pendingMaintenance = 0.obs;
  final pendingReports = 0.obs;
  final pendingEquipments = 0.obs;

  // Deuxième partie - Entités validées
  final completedInterventions = 0.obs;
  final completedMaintenance = 0.obs;
  final validatedReports = 0.obs;
  final operationalEquipments = 0.obs;

  // Troisième partie - Statistiques montants
  final interventionCost = 0.0.obs;
  final maintenanceCost = 0.0.obs;
  final equipmentValue = 0.0.obs;
  final savings = 0.0.obs;

  // Statistiques originales
  List<StatCard> get stats => [
    StatCard(
      title: "Interventions",
      value: completedInterventions.value.toString(),
      icon: Icons.build,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_INTERVENTIONS,
    ),
    StatCard(
      title: "Maintenance",
      value: completedMaintenance.value.toString(),
      icon: Icons.engineering,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Équipements",
      value: operationalEquipments.value.toString(),
      icon: Icons.settings,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Rapports",
      value: validatedReports.value.toString(),
      icon: Icons.analytics,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_REPORTS,
    ),
  ];

  // Nouvelles statistiques pour le dashboard amélioré
  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Interventions en attente",
      value: pendingInterventions.value.toString(),
      icon: Icons.build,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_INTERVENTIONS,
    ),
    StatCard(
      title: "Maintenance en attente",
      value: pendingMaintenance.value.toString(),
      icon: Icons.engineering,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Rapports en attente",
      value: pendingReports.value.toString(),
      icon: Icons.analytics,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_REPORTS,
    ),
    StatCard(
      title: "Équipements en attente",
      value: pendingEquipments.value.toString(),
      icon: Icons.settings,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
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
      interventionData.value = [
        ChartData(1, 15, "Terminées"),
        ChartData(2, 8, "En cours"),
        ChartData(3, 5, "En attente"),
        ChartData(4, 2, "Annulées"),
      ];

      maintenanceData.value = [
        ChartData(1, 12, "Préventive"),
        ChartData(2, 8, "Corrective"),
        ChartData(3, 5, "Prédictive"),
        ChartData(4, 3, "Urgente"),
      ];

      equipmentData.value = [
        ChartData(1, 25, "Opérationnels"),
        ChartData(2, 5, "En maintenance"),
        ChartData(3, 3, "Hors service"),
        ChartData(4, 2, "En réparation"),
      ];

      reportData.value = [
        ChartData(1, 20, "Validés"),
        ChartData(2, 5, "En attente"),
        ChartData(3, 3, "Rejetés"),
        ChartData(4, 2, "Brouillons"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('interventions', interventionData);
      updateChartData('maintenance', maintenanceData);
      updateChartData('equipments', equipmentData);
      updateChartData('reports', reportData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      final interventions = await _interventionService.getInterventions();
      pendingInterventions.value =
          interventions
              .where((i) => i.status.toLowerCase() == 'pending')
              .length;

      // Si vous avez une liste de maintenances, adaptez ici; sinon, approx 0
      pendingMaintenance.value = 0;

      final reports = await _reportingService.getAllReports();
      pendingReports.value =
          reports
              .where((r) => r.status == 'pending' || r.status == 'draft')
              .length;

      final equipments = await _equipmentService.getEquipments();
      pendingEquipments.value =
          equipments
              .where((e) => (e.status ?? '').toLowerCase() == 'pending')
              .length;
    } catch (e) {
      print('Erreur lors du chargement des entités en attente: $e');
      pendingInterventions.value = 0;
      pendingMaintenance.value = 0;
      pendingReports.value = 0;
      pendingEquipments.value = 0;
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final interventions = await _interventionService.getInterventions();
      completedInterventions.value =
          interventions
              .where((i) => i.status.toLowerCase() == 'completed')
              .length;

      completedMaintenance.value = 0;

      final reports = await _reportingService.getAllReports();
      validatedReports.value =
          reports
              .where((r) => r.status == 'validated' || r.status == 'done')
              .length;

      final equipments = await _equipmentService.getEquipments();
      operationalEquipments.value =
          equipments
              .where((e) => (e.status ?? '').toLowerCase() == 'operational')
              .length;
    } catch (e) {
      print('Erreur lors du chargement des entités validées: $e');
      completedInterventions.value = 0;
      completedMaintenance.value = 0;
      validatedReports.value = 0;
      operationalEquipments.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Valeurs approximatives basées sur les listes
      final interventions = await _interventionService.getInterventions();
      interventionCost.value = interventions.fold(
        0.0,
        (sum, i) => sum + (i.cost ?? 0.0),
      );

      final equipments = await _equipmentService.getEquipments();
      equipmentValue.value = equipments.fold(
        0.0,
        (sum, e) => sum + (e.currentValue ?? 0.0),
      );

      maintenanceCost.value = 0.0;
      savings.value = 0.0;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      interventionCost.value = 0.0;
      maintenanceCost.value = 0.0;
      equipmentValue.value = 0.0;
      savings.value = 0.0;
    }
  }
}
