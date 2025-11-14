import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/rh_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/services/contract_service.dart';

class RhDashboardController extends BaseDashboardController {
  var currentSection = 'dashboard'.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Service pour récupérer les données
  final RhDashboardService _dashboardService = RhDashboardService();
  final EmployeeService _employeeService = Get.find<EmployeeService>();
  final LeaveService _leaveService = Get.find<LeaveService>();
  final AttendancePunchService _attendanceService =
      Get.find<AttendancePunchService>();
  final RecruitmentService _recruitmentService = Get.find<RecruitmentService>();
  final ContractService _contractService = Get.find<ContractService>();

  List<Filter> get filters => DashboardFilters.getFiltersForRole(Roles.RH);

  // Données des graphiques
  final employeeData = <ChartData>[].obs;
  final leaveData = <ChartData>[].obs;
  final recruitmentData = <ChartData>[].obs;
  final salaryData = <ChartData>[].obs;

  // Nouvelles données pour le dashboard amélioré
  // Première partie - Entités en attente
  final pendingLeaves = 0.obs;
  final pendingRecruitments = 0.obs;
  final pendingAttendance = 0.obs;
  final pendingSalaries = 0.obs;
  final pendingContracts = 0.obs;

  // Deuxième partie - Entités validées
  final activeEmployees = 0.obs;
  final approvedLeaves = 0.obs;
  final completedRecruitments = 0.obs;
  final paidSalaries = 0.obs;
  final approvedContracts = 0.obs;

  // Troisième partie - Statistiques montants
  final totalSalaryMass = 0.0.obs;
  final totalBonuses = 0.0.obs;
  final recruitmentCost = 0.0.obs;
  final trainingCost = 0.0.obs;

  // Statistiques originales
  List<StatCard> get stats => [
    StatCard(
      title: "Employés",
      value: activeEmployees.value.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Congés",
      value: approvedLeaves.value.toString(),
      icon: Icons.beach_access,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
    StatCard(
      title: "Recrutement",
      value: completedRecruitments.value.toString(),
      icon: Icons.person_add,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
    ),
  ];

  // Nouvelles statistiques pour le dashboard amélioré
  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Congés en attente",
      value: pendingLeaves.value.toString(),
      icon: Icons.beach_access,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
    StatCard(
      title: "Recrutements en attente",
      value: pendingRecruitments.value.toString(),
      icon: Icons.person_add,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
    ),
    StatCard(
      title: "Pointages en attente",
      value: pendingAttendance.value.toString(),
      icon: Icons.access_time,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_ATTENDANCE,
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
      employeeData.value = [
        ChartData(1, 35, "Actifs"),
        ChartData(2, 5, "Inactifs"),
        ChartData(3, 3, "En congé"),
        ChartData(4, 2, "En formation"),
      ];

      leaveData.value = [
        ChartData(1, 12, "Approuvés"),
        ChartData(2, 5, "En attente"),
        ChartData(3, 2, "Refusés"),
        ChartData(4, 1, "Annulés"),
      ];

      recruitmentData.value = [
        ChartData(1, 8, "Embauches"),
        ChartData(2, 3, "En cours"),
        ChartData(3, 2, "En attente"),
        ChartData(4, 1, "Annulés"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('employees', employeeData);
      updateChartData('leaves', leaveData);
      updateChartData('recruitment', recruitmentData);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      // Charger les congés en attente
      try {
        final leaves = await _leaveService.getAllLeaveRequests();
        pendingLeaves.value = leaves.where((l) => l.status == 'pending').length;
      } catch (e) {
        pendingLeaves.value = 0;
      }

      // Charger les recrutements en attente
      // Les recrutements "en attente" sont ceux avec le statut "published" (publié mais pas encore validé)
      try {
        final recruitments =
            await _recruitmentService.getAllRecruitmentRequests();
        pendingRecruitments.value =
            recruitments.where((r) => r.status == 'published').length;
      } catch (e) {
        pendingRecruitments.value = 0;
      }

      // Charger les pointages en attente
      try {
        final attendances = await _attendanceService.getAttendances();
        pendingAttendance.value =
            attendances
                .where((a) => a.status.toLowerCase() == 'pending')
                .length;
      } catch (e) {
        pendingAttendance.value = 0;
      }

      // Charger les contrats en attente
      try {
        final contracts = await _contractService.getAllContracts();
        pendingContracts.value =
            contracts.where((c) => c.status == 'pending').length;
      } catch (e) {
        pendingContracts.value = 0;
      }
    } catch (e) {
      // En cas d'erreur globale, réinitialiser tous les compteurs
      pendingLeaves.value = 0;
      pendingRecruitments.value = 0;
      pendingAttendance.value = 0;
      pendingContracts.value = 0;
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final employees = await _employeeService.getEmployees();
      activeEmployees.value = employees.length;

      final leaves = await _leaveService.getAllLeaveRequests();
      approvedLeaves.value = leaves.where((l) => l.status == 'approved').length;

      final recruitments =
          await _recruitmentService.getAllRecruitmentRequests();
      completedRecruitments.value =
          recruitments.length - pendingRecruitments.value;

      final contracts = await _contractService.getAllContracts();
      approvedContracts.value =
          contracts.where((c) => c.status == 'active').length;
    } catch (e) {
      activeEmployees.value = 0;
      approvedLeaves.value = 0;
      completedRecruitments.value = 0;
      approvedContracts.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // Valeurs approximatives si non disponibles
      recruitmentCost.value = 0.0;
      trainingCost.value = 0.0;
    } catch (e) {
      recruitmentCost.value = 0.0;
      trainingCost.value = 0.0;
    }
  }
}
