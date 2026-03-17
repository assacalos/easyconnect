import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/rh_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/task_service.dart';

class RhDashboardController extends BaseDashboardController {
  static final RhDashboardController _instance = RhDashboardController._();
  static RhDashboardController get to => _instance;
  factory RhDashboardController() => _instance;
  RhDashboardController._();

  String currentSection = 'dashboard';
  String selectedPeriod = 'month';
  String selectedDepartment = 'all';

  final RhDashboardService _dashboardService = RhDashboardService();
  final EmployeeService _employeeService = EmployeeService.to;
  final LeaveService _leaveService = LeaveService.to;
  final AttendancePunchService _attendanceService = AttendancePunchService();
  final RecruitmentService _recruitmentService = RecruitmentService.to;
  final ContractService _contractService = ContractService.to;
  final TaskService _taskService = TaskService.to;

  List<Filter> get filters => DashboardFilters.getFiltersForRole(Roles.RH);

  final List<ChartData> employeeData = [];
  final List<ChartData> leaveData = [];
  final List<ChartData> recruitmentData = [];
  final List<ChartData> salaryData = [];

  int pendingLeaves = 0;
  int pendingRecruitments = 0;
  int pendingAttendance = 0;
  int pendingSalaries = 0;
  int pendingContracts = 0;
  int pendingTasks = 0;

  int activeEmployees = 0;
  int approvedLeaves = 0;
  int completedRecruitments = 0;
  int paidSalaries = 0;
  int approvedContracts = 0;

  double totalSalaryMass = 0.0;
  double totalBonuses = 0.0;
  double recruitmentCost = 0.0;
  double trainingCost = 0.0;

  List<StatCard> get stats => [
    StatCard(
      title: "Employés",
      value: activeEmployees.toString(),
      icon: Icons.people,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Congés",
      value: approvedLeaves.toString(),
      icon: Icons.beach_access,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
    StatCard(
      title: "Recrutement",
      value: completedRecruitments.toString(),
      icon: Icons.person_add,
      color: Colors.orange,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
    ),
  ];

  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Congés en attente",
      value: pendingLeaves.toString(),
      icon: Icons.beach_access,
      color: Colors.blue,
      requiredPermission: Permissions.MANAGE_LEAVES,
    ),
    StatCard(
      title: "Recrutements en attente",
      value: pendingRecruitments.toString(),
      icon: Icons.person_add,
      color: Colors.green,
      requiredPermission: Permissions.MANAGE_RECRUITMENT,
    ),
    StatCard(
      title: "Pointages en attente",
      value: pendingAttendance.toString(),
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
    if (isLoading) return;
    isLoading = true;

    try {
      await Future.delayed(const Duration(seconds: 1));

      await _loadPendingEntities();
      await _loadValidatedEntities();
      await _loadStatistics();

      employeeData.clear();
      employeeData.addAll([
        ChartData(1, 35, "Actifs"),
        ChartData(2, 5, "Inactifs"),
        ChartData(3, 3, "En congé"),
        ChartData(4, 2, "En formation"),
      ]);

      leaveData.clear();
      leaveData.addAll([
        ChartData(1, 12, "Approuvés"),
        ChartData(2, 5, "En attente"),
        ChartData(3, 2, "Refusés"),
        ChartData(4, 1, "Annulés"),
      ]);

      recruitmentData.clear();
      recruitmentData.addAll([
        ChartData(1, 8, "Embauches"),
        ChartData(2, 3, "En cours"),
        ChartData(3, 2, "En attente"),
        ChartData(4, 1, "Annulés"),
      ]);

      updateChartData('employees', employeeData);
      updateChartData('leaves', leaveData);
      updateChartData('recruitment', recruitmentData);
    } catch (e) {
    } finally {
      isLoading = false;
    }
  }

  Future<void> _loadPendingEntities() async {
    try {
      final results = await Future.wait([
        _leaveService.getAllLeaveRequests(),
        _recruitmentService.getAllRecruitmentRequests(),
        _attendanceService.getAttendances(),
        _contractService.getAllContracts(),
      ], eagerError: false);

      try {
        final leaves = results[0] as List;
        pendingLeaves = leaves.where((l) => (l as dynamic).status == 'pending').length;
      } catch (e) {}

      try {
        final recruitments = results[1] as List;
        pendingRecruitments = recruitments.where((r) => (r as dynamic).status == 'published').length;
      } catch (e) {}

      try {
        final attendances = results[2] as List;
        pendingAttendance = attendances.where((a) => (a as dynamic).status.toLowerCase() == 'pending').length;
      } catch (e) {}

      try {
        final contracts = results[3] as List;
        pendingContracts = contracts.where((c) => (c as dynamic).status == 'pending').length;
      } catch (e) {}

      await _loadPendingTasks();
    } catch (e) {}
  }

  Future<void> _loadPendingTasks() async {
    try {
      final result = await _taskService.getTasks(status: 'pending', page: 1, perPage: 1);
      if (result['success'] == true) {
        final pagination = result['pagination'] as Map<String, dynamic>? ?? {};
        pendingTasks = pagination['total'] as int? ?? 0;
      }
    } catch (e) {}
  }

  Future<void> _loadValidatedEntities() async {
    try {
      final employees = await _employeeService.getEmployees();
      activeEmployees = employees.length;

      final leaves = await _leaveService.getAllLeaveRequests();
      approvedLeaves = leaves.where((l) => l.status == 'approved').length;

      final recruitments = await _recruitmentService.getAllRecruitmentRequests();
      completedRecruitments = recruitments.length - pendingRecruitments;

      final contracts = await _contractService.getAllContracts();
      approvedContracts = contracts.where((c) => c.status == 'active').length;
    } catch (e) {}
  }

  Future<void> _loadStatistics() async {
    try {
      recruitmentCost = 0.0;
      trainingCost = 0.0;
    } catch (e) {}
  }
}
