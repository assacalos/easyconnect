import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/services/comptable_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/services/task_service.dart';

class ComptableDashboardController extends BaseDashboardController {
  String currentSection = 'dashboard';
  String selectedPeriod = 'month';
  String selectedDepartment = 'all';

  final ComptableDashboardService _dashboardService =
      ComptableDashboardService();
  final InvoiceService _invoiceService = InvoiceService.to;
  final PaymentService _paymentService = PaymentService.to;
  final ExpenseService _expenseService = ExpenseService();
  final SalaryService _salaryService = SalaryService();
  final TaskService _taskService = TaskService.to;

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.COMPTABLE);

  final List<ChartData> revenueData = [];
  final List<ChartData> paymentData = [];
  final List<ChartData> expenseData = [];
  final List<ChartData> salaryData = [];

  int pendingFactures = 0;
  int pendingPaiements = 0;
  int pendingDepenses = 0;
  int pendingSalaires = 0;
  int pendingTasks = 0;

  int validatedFactures = 0;
  int validatedPaiements = 0;
  int validatedDepenses = 0;
  int validatedSalaires = 0;

  double totalRevenue = 0.0;
  double totalPayments = 0.0;
  double totalExpenses = 0.0;
  double totalSalaries = 0.0;
  double netProfit = 0.0;

  List<StatCard> get stats => [
    StatCard(
      title: "Factures",
      value: validatedFactures.toString(),
      icon: Icons.receipt,
      color: Colors.red,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Paiements",
      value: validatedPaiements.toString(),
      icon: Icons.payment,
      color: Colors.teal,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Dépenses",
      value: validatedDepenses.toString(),
      icon: Icons.money_off,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Salaires",
      value: validatedSalaires.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
  ];

  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Factures en attente",
      value: pendingFactures.toString(),
      icon: Icons.receipt,
      color: Colors.red,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Paiements en attente",
      value: pendingPaiements.toString(),
      icon: Icons.payment,
      color: Colors.teal,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Dépenses en attente",
      value: pendingDepenses.toString(),
      icon: Icons.money_off,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Salaires en attente",
      value: pendingSalaires.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
  ];

  ComptableDashboardController() {
    refreshPendingEntities();
  }

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
    final cachedPendingFactures = CacheHelper.get<int>(
      'dashboard_comptable_pendingFactures',
    );
    if (cachedPendingFactures != null)
      pendingFactures = cachedPendingFactures;

    final cachedPendingPaiements = CacheHelper.get<int>(
      'dashboard_comptable_pendingPaiements',
    );
    if (cachedPendingPaiements != null)
      pendingPaiements = cachedPendingPaiements;

    final cachedPendingDepenses = CacheHelper.get<int>(
      'dashboard_comptable_pendingDepenses',
    );
    if (cachedPendingDepenses != null)
      pendingDepenses = cachedPendingDepenses;

    final cachedPendingSalaires = CacheHelper.get<int>(
      'dashboard_comptable_pendingSalaires',
    );
    if (cachedPendingSalaires != null)
      pendingSalaires = cachedPendingSalaires;

    final cachedTotalRevenue = CacheHelper.get<double>(
      'dashboard_comptable_totalRevenue',
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

      paymentData.clear();
      paymentData.addAll([
        ChartData(1, 35000, "Espèces"),
        ChartData(2, 25000, "Virement"),
        ChartData(3, 20000, "Chèque"),
        ChartData(4, 10000, "Autres"),
      ]);

      expenseData.clear();
      expenseData.addAll([
        ChartData(1, 12000, "Fournitures"),
        ChartData(2, 8000, "Équipement"),
        ChartData(3, 5000, "Transport"),
        ChartData(4, 3000, "Autres"),
      ]);

      salaryData.clear();
      salaryData.addAll([
        ChartData(1, 45000, "Salaires"),
        ChartData(2, 5000, "Primes"),
        ChartData(3, 3000, "Avantages"),
        ChartData(4, 2000, "Autres"),
      ]);

      updateChartData('revenue', revenueData);
      updateChartData('payments', paymentData);
      updateChartData('expenses', expenseData);
      updateChartData('salaries', salaryData);
    } catch (e) {
    } finally {
      isLoading = false;
    }
  }

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

  Future<void> _loadPendingEntities() async {
    try {
      final factures = await _invoiceService.getAllInvoices();
      final statusLower = (String status) => status.toLowerCase();
      final pendingFacturesCount =
          factures.where((f) {
            final status = statusLower(f.status);
            return status == 'draft' || status == 'en_attente';
          }).length;
      pendingFactures = pendingFacturesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingFactures',
        pendingFacturesCount,
      );

      final paiements = await _paymentService.getAllPayments();
      final pendingPaiementsCount = paiements.where((p) => p.isPending).length;
      pendingPaiements = pendingPaiementsCount;
      CacheHelper.set(
        'dashboard_comptable_pendingPaiements',
        pendingPaiementsCount,
      );

      final depenses = await _expenseService.getExpenses();
      final pendingDepensesCount =
          depenses.where((d) => d.status == 'pending').length;
      pendingDepenses = pendingDepensesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingDepenses',
        pendingDepensesCount,
      );

      final salaires = await _salaryService.getSalaries();
      final pendingSalairesCount =
          salaires.where((s) => s.status == 'pending').length;
      pendingSalaires = pendingSalairesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingSalaires',
        pendingSalairesCount,
      );

      await _loadPendingTasks();
    } catch (e) {}
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
        _invoiceService.getAllInvoices(),
        _paymentService.getAllPayments(),
        _expenseService.getExpenses(),
        _salaryService.getSalaries(),
      ], eagerError: false);

      final factures = results[0] as List;
      validatedFactures = factures.length - pendingFactures;

      final paiements = results[1] as List;
      validatedPaiements = paiements.length - pendingPaiements;

      final depenses = results[2] as List;
      validatedDepenses = depenses.length - pendingDepenses;

      final salaires = results[3] as List;
      validatedSalaires = salaires.length - pendingSalaires;
    } catch (e) {}
  }

  Future<void> _loadStatistics() async {
    try {
      final results = await Future.wait([
        _invoiceService.getAllInvoices(),
        _paymentService.getAllPayments(),
        _expenseService.getExpenses(),
        _salaryService.getSalaries(),
      ], eagerError: false);

      final factures = results[0] as List;
      final statusLower = (String status) => status.toLowerCase().trim();
      final revenue = factures
          .where((f) {
            final status = statusLower(f.status);
            return status == 'valide' ||
                status == 'validated' ||
                status == 'approved';
          })
          .fold(0.0, (sum, f) => sum + f.totalAmount);
      totalRevenue = revenue;
      CacheHelper.set('dashboard_comptable_totalRevenue', revenue);

      final paiements = results[1] as List;
      final payments = paiements.fold(0.0, (sum, p) => sum + (p.amount ?? 0.0));
      totalPayments = payments;
      CacheHelper.set('dashboard_comptable_totalPayments', payments);

      final depenses = results[2] as List;
      final expenses = depenses.fold(0.0, (sum, d) => sum + (d.amount ?? 0.0));
      totalExpenses = expenses;
      CacheHelper.set('dashboard_comptable_totalExpenses', expenses);

      final salaires = results[3] as List;
      final salaries = salaires.fold(0.0, (sum, s) => sum + (s.netSalary));
      totalSalaries = salaries;
      CacheHelper.set('dashboard_comptable_totalSalaries', salaries);

      netProfit = revenue - expenses - salaries;
    } catch (e) {}
  }
}
