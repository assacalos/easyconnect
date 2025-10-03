import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Patron/patron_permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/services/favorites_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/Models/notification_model.dart';

class PatronDashboardController extends BaseDashboardController {
  var currentSection = PatronSection.dashboard.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  List<Filter> get filters => DashboardFilters.getFiltersForRole(Roles.PATRON);

  // Données des graphiques
  final revenueData = <ChartData>[].obs;
  final employeeData = <ChartData>[].obs;
  final ticketData = <ChartData>[].obs;
  final leaveData = <ChartData>[].obs;

  // Statistiques
  List<StatCard> get stats => [
    StatCard(
      title: "Chiffre d'affaires",
      value: "103.5k fcfa",
      icon: Icons.currency_franc,
      color: Colors.green,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Employés",
      value: "85",
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Tickets",
      value: "12",
      icon: Icons.build,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_TICKETS,
    ),
    StatCard(
      title: "Congés",
      value: "5",
      icon: Icons.beach_access,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_LEAVES,
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
      // Simuler le chargement des données
      revenueData.value = [
        ChartData(1, 85000, "Janvier"),
        ChartData(2, 92000, "Février"),
        ChartData(3, 88000, "Mars"),
        ChartData(4, 95000, "Avril"),
        ChartData(5, 103000, "Mai"),
        ChartData(6, 110000, "Juin"),
      ];

      employeeData.value = [
        ChartData(1, 35, "Commercial"),
        ChartData(2, 25, "Technique"),
        ChartData(3, 20, "Support"),
        ChartData(4, 20, "Autres"),
      ];

      ticketData.value = [
        ChartData(1, 45, "Ouverts"),
        ChartData(2, 15, "En cours"),
        ChartData(3, 8, "En attente"),
        ChartData(4, 2, "Fermés"),
      ];

      leaveData.value = [
        ChartData(1, 12, "Lundi"),
        ChartData(2, 15, "Mardi"),
        ChartData(3, 8, "Mercredi"),
        ChartData(4, 10, "Jeudi"),
        ChartData(5, 5, "Vendredi"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('revenue', revenueData);
      updateChartData('employees', employeeData);
      updateChartData('tickets', ticketData);
      updateChartData('leaves', leaveData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }
}
