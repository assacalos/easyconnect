import 'dart:async';
import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/technicien_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/task_service.dart';

class TechnicienDashboardController extends BaseDashboardController {
  static final TechnicienDashboardController _instance = TechnicienDashboardController._();
  static TechnicienDashboardController get to => _instance;
  factory TechnicienDashboardController() => _instance;
  TechnicienDashboardController._();

  String currentSection = 'dashboard';
  String selectedPeriod = 'month';
  String selectedDepartment = 'all';

  final TechnicienDashboardService _dashboardService = TechnicienDashboardService();
  final InterventionService _interventionService = InterventionService();
  final EquipmentService _equipmentService = EquipmentService();
  final ReportingService _reportingService = ReportingService.to;
  final TaskService _taskService = TaskService.to;

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.TECHNICIEN);

  // Données des graphiques
  final List<ChartData> interventionData = [];
  final List<ChartData> maintenanceData = [];
  final List<ChartData> equipmentData = [];
  final List<ChartData> reportData = [];

  int pendingInterventions = 0;
  int pendingMaintenance = 0;
  int pendingReports = 0;
  int pendingEquipments = 0;
  int pendingTasks = 0;

  int completedInterventions = 0;
  int completedMaintenance = 0;
  int validatedReports = 0;
  int operationalEquipments = 0;

  double interventionCost = 0.0;
  double maintenanceCost = 0.0;
  double equipmentValue = 0.0;
  double savings = 0.0;

  // Statistiques originales
  List<StatCard> get stats => [
    StatCard(
      title: "Interventions",
      value: completedInterventions.toString(),
      icon: Icons.build,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_INTERVENTIONS,
    ),
    StatCard(
      title: "Maintenance",
      value: completedMaintenance.toString(),
      icon: Icons.engineering,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Équipements",
      value: operationalEquipments.toString(),
      icon: Icons.settings,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Rapports",
      value: validatedReports.toString(),
      icon: Icons.analytics,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_REPORTS,
    ),
  ];

  // Nouvelles statistiques pour le dashboard amélioré
  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Interventions en attente",
      value: pendingInterventions.toString(),
      icon: Icons.build,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_INTERVENTIONS,
    ),
    StatCard(
      title: "Maintenance en attente",
      value: pendingMaintenance.toString(),
      icon: Icons.engineering,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EQUIPMENT,
    ),
    StatCard(
      title: "Rapports en attente",
      value: pendingReports.toString(),
      icon: Icons.analytics,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_REPORTS,
    ),
    StatCard(
      title: "Équipements en attente",
      value: pendingEquipments.toString(),
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

  /// À appeler quand le dashboard est affiché (ex. initState de la vue).
  void onReady() {
    // Recharger les données quand le dashboard est prêt
    loadData();
    // Configurer les listeners après que tout soit initialisé
    Future.delayed(const Duration(milliseconds: 500), () {
      _setupListeners();
    });
  }

  Timer? _refreshTimer;

  void _setupListeners() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      refreshPendingEntities();
    });
  }

  void dispose() {
    _refreshTimer?.cancel();
  }

  // Rafraîchissement silencieux
  Future<void> refreshPendingEntities() async {
    try {
      isLoading = true;
      try {
        await _loadPendingEntities();
        await _loadValidatedEntities();
        await _loadStatistics();
      } finally {
        isLoading = false;
      }
    } catch (e) {
      isLoading = false;
    }
  }

  @override
  Future<void> loadData() async {
    if (isLoading) return;
    isLoading = true;
    if (_refreshTimer == null) _setupListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Charger les données des entités en attente
      await _loadPendingEntities();

      // Charger les données des entités validées
      await _loadValidatedEntities();

      // Charger les statistiques montants
      await _loadStatistics();

      // Simuler le chargement des données des graphiques
      interventionData.clear();
      interventionData.addAll([
        ChartData(1, 15, "Terminées"),
        ChartData(2, 8, "En cours"),
        ChartData(3, 5, "En attente"),
        ChartData(4, 2, "Annulées"),
      ]);

      maintenanceData.clear();
      maintenanceData.addAll([
        ChartData(1, 12, "Préventive"),
        ChartData(2, 8, "Corrective"),
        ChartData(3, 5, "Prédictive"),
        ChartData(4, 3, "Urgente"),
      ]);

      equipmentData.clear();
      equipmentData.addAll([
        ChartData(1, 25, "Opérationnels"),
        ChartData(2, 5, "En maintenance"),
        ChartData(3, 3, "Hors service"),
        ChartData(4, 2, "En réparation"),
      ]);

      reportData.clear();
      reportData.addAll([
        ChartData(1, 20, "Validés"),
        ChartData(2, 5, "En attente"),
        ChartData(3, 3, "Rejetés"),
        ChartData(4, 2, "Brouillons"),
      ]);

      // Mettre à jour les données des graphiques
      updateChartData('interventions', interventionData);
      updateChartData('maintenance', maintenanceData);
      updateChartData('equipments', equipmentData);
      updateChartData('reports', reportData);
    } catch (e) {
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      // OPTIMISATION : Charger toutes les entités en parallèle
      final results = await Future.wait([
        _interventionService.getInterventions(),
        _reportingService.getAllReports(),
        _equipmentService.getEquipments(),
      ], eagerError: false);

      // Charger depuis les services directement pour avoir les données les plus récentes
      final interventions = results[0] as List;
      final pendingCount =
          interventions
              .where((i) => (i as dynamic).status.toLowerCase() == 'pending')
              .length;
      pendingInterventions = pendingCount;

      pendingMaintenance = 0;

      try {
        final reports = results[1] as List;
        pendingReports =
            reports.where((r) {
              final status = (r as dynamic).status;
              return status == 'pending' || status == 'submitted';
            }).length;
      } catch (e) {
        // Ne pas réinitialiser
      }

      try {
        final equipments = results[2] as List;
        pendingEquipments =
            equipments.where((e) {
              final status =
                  (e as dynamic).status?.toString().toLowerCase() ?? '';
              // Inclure les statuts: pending, en_attente, maintenance, broken
              // et les équipements qui nécessitent une maintenance
              return status == 'pending' ||
                  status == 'en_attente' ||
                  status == 'maintenance' ||
                  status == 'broken' ||
                  (e as dynamic).needsMaintenance == true;
            }).length;
      } catch (e) {
        // Ne pas réinitialiser
      }

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
    } catch (e) {
      // Ne pas réinitialiser
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final interventions = await _interventionService.getInterventions();

      // Les interventions validées peuvent être 'approved' ou 'completed'
      completedInterventions =
          interventions.where((i) {
            final status = i.status.toLowerCase();
            return status == 'completed' ||
                status == 'approved' ||
                status == 'validated';
          }).length;

      print(
        '🔍 [TECHNICIEN_DASHBOARD] Interventions validées: $completedInterventions',
      );
      print(
        '🔍 [TECHNICIEN_DASHBOARD] Tous les statuts d\'interventions: ${interventions.map((i) => i.status).toSet()}',
      );

      completedMaintenance = 0;

      final reports = await _reportingService.getAllReports();
      validatedReports =
          reports
              .where((r) => r.status == 'validated' || r.status == 'done')
              .length;

      final equipments = await _equipmentService.getEquipments();
      operationalEquipments =
          equipments.where((e) => e.status.toLowerCase() == 'active').length;
    } catch (e) {
      // Ne pas réinitialiser
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Valeurs approximatives basées sur les listes
      final interventions = await _interventionService.getInterventions();
      interventionCost = interventions.fold(
        0.0,
        (sum, i) => sum + (i.cost ?? 0.0),
      );

      final equipments = await _equipmentService.getEquipments();
      equipmentValue = equipments.fold(
        0.0,
        (sum, e) => sum + (e.currentValue ?? 0.0),
      );

      maintenanceCost = 0.0;
      savings = 0.0;
    } catch (e) {
      // Ne pas réinitialiser
    }
  }
}
