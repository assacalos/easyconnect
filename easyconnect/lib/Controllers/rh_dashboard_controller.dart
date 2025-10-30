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
import 'package:easyconnect/services/salary_service.dart';

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
  final SalaryService _salaryService = Get.find<SalaryService>();

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

  // Deuxième partie - Entités validées
  final activeEmployees = 0.obs;
  final approvedLeaves = 0.obs;
  final completedRecruitments = 0.obs;
  final paidSalaries = 0.obs;

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
    StatCard(
      title: "Salaires",
      value: paidSalaries.value.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_SALARIES,
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
    StatCard(
      title: "Salaires en attente",
      value: pendingSalaries.value.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.MANAGE_SALARIES,
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

      salaryData.value = [
        ChartData(1, 45000, "Salaires"),
        ChartData(2, 5000, "Primes"),
        ChartData(3, 3000, "Avantages"),
        ChartData(4, 2000, "Autres"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('employees', employeeData);
      updateChartData('leaves', leaveData);
      updateChartData('recruitment', recruitmentData);
      updateChartData('salaries', salaryData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      final leaves = await _leaveService.getAllLeaveRequests();
      pendingLeaves.value = leaves.where((l) => l.status == 'pending').length;

      final recruitments =
          await _recruitmentService.getAllRecruitmentRequests();
      pendingRecruitments.value =
          recruitments.where((r) => r.status == 'draft').length;

      final attendances = await _attendanceService.getAttendances();
      pendingAttendance.value =
          attendances.where((a) => a.status.toLowerCase() == 'pending').length;

      final salaries = await _salaryService.getSalaries();
      pendingSalaries.value =
          salaries.where((s) => s.status == 'pending').length;
    } catch (e) {
      print('Erreur lors du chargement des entités en attente: $e');
      pendingLeaves.value = 0;
      pendingRecruitments.value = 0;
      pendingAttendance.value = 0;
      pendingSalaries.value = 0;
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

      final salaries = await _salaryService.getSalaries();
      paidSalaries.value = salaries.length - pendingSalaries.value;
    } catch (e) {
      print('Erreur lors du chargement des entités validées: $e');
      activeEmployees.value = 0;
      approvedLeaves.value = 0;
      completedRecruitments.value = 0;
      paidSalaries.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final salaries = await _salaryService.getSalaries();
      totalSalaryMass.value = salaries.fold(0.0, (sum, s) => sum + s.netSalary);
      totalBonuses.value = salaries.fold(0.0, (sum, s) => sum + s.bonus);
      // Valeurs approximatives si non disponibles
      recruitmentCost.value = 0.0;
      trainingCost.value = 0.0;
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      totalSalaryMass.value = 0.0;
      totalBonuses.value = 0.0;
      recruitmentCost.value = 0.0;
      trainingCost.value = 0.0;
    }
  }
}
