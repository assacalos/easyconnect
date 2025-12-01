import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
import 'package:easyconnect/services/comptable_dashboard_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/salary_service.dart';

class ComptableDashboardController extends BaseDashboardController {
  var currentSection = 'dashboard'.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Service pour récupérer les données
  final ComptableDashboardService _dashboardService =
      ComptableDashboardService();
  final InvoiceService _invoiceService = Get.find<InvoiceService>();
  final PaymentService _paymentService = Get.find<PaymentService>();
  final ExpenseService _expenseService = Get.find<ExpenseService>();
  final SalaryService _salaryService = Get.find<SalaryService>();

  List<Filter> get filters =>
      DashboardFilters.getFiltersForRole(Roles.COMPTABLE);

  // Données des graphiques
  final revenueData = <ChartData>[].obs;
  final paymentData = <ChartData>[].obs;
  final expenseData = <ChartData>[].obs;
  final salaryData = <ChartData>[].obs;

  // Nouvelles données pour le dashboard amélioré
  // Première partie - Entités en attente
  final pendingFactures = 0.obs;
  final pendingPaiements = 0.obs;
  final pendingDepenses = 0.obs;
  final pendingSalaires = 0.obs;

  // Deuxième partie - Entités validées
  final validatedFactures = 0.obs;
  final validatedPaiements = 0.obs;
  final validatedDepenses = 0.obs;
  final validatedSalaires = 0.obs;

  // Troisième partie - Statistiques montants
  final totalRevenue = 0.0.obs;
  final totalPayments = 0.0.obs;
  final totalExpenses = 0.0.obs;
  final totalSalaries = 0.0.obs;
  final netProfit = 0.0.obs;

  // Statistiques originales
  List<StatCard> get stats => [
    StatCard(
      title: "Factures",
      value: validatedFactures.value.toString(),
      icon: Icons.receipt,
      color: Colors.red,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Paiements",
      value: validatedPaiements.value.toString(),
      icon: Icons.payment,
      color: Colors.teal,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Dépenses",
      value: validatedDepenses.value.toString(),
      icon: Icons.money_off,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Salaires",
      value: validatedSalaires.value.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
  ];

  // Nouvelles statistiques pour le dashboard amélioré
  List<StatCard> get enhancedStats => [
    StatCard(
      title: "Factures en attente",
      value: pendingFactures.value.toString(),
      icon: Icons.receipt,
      color: Colors.red,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Paiements en attente",
      value: pendingPaiements.value.toString(),
      icon: Icons.payment,
      color: Colors.teal,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Dépenses en attente",
      value: pendingDepenses.value.toString(),
      icon: Icons.money_off,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Salaires en attente",
      value: pendingSalaires.value.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
  ];

  @override
  void onReady() {
    super.onReady();
    // Rafraîchir les entités en attente quand le contrôleur est prêt
    // Cela permet de mettre à jour les compteurs quand on revient sur le dashboard
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
    // Charger les données depuis le cache pour un affichage instantané
    final cachedPendingFactures = CacheHelper.get<int>(
      'dashboard_comptable_pendingFactures',
    );
    if (cachedPendingFactures != null)
      pendingFactures.value = cachedPendingFactures;

    final cachedPendingPaiements = CacheHelper.get<int>(
      'dashboard_comptable_pendingPaiements',
    );
    if (cachedPendingPaiements != null)
      pendingPaiements.value = cachedPendingPaiements;

    final cachedPendingDepenses = CacheHelper.get<int>(
      'dashboard_comptable_pendingDepenses',
    );
    if (cachedPendingDepenses != null)
      pendingDepenses.value = cachedPendingDepenses;

    final cachedPendingSalaires = CacheHelper.get<int>(
      'dashboard_comptable_pendingSalaires',
    );
    if (cachedPendingSalaires != null)
      pendingSalaires.value = cachedPendingSalaires;

    final cachedTotalRevenue = CacheHelper.get<double>(
      'dashboard_comptable_totalRevenue',
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

      paymentData.value = [
        ChartData(1, 35000, "Espèces"),
        ChartData(2, 25000, "Virement"),
        ChartData(3, 20000, "Chèque"),
        ChartData(4, 10000, "Autres"),
      ];

      expenseData.value = [
        ChartData(1, 12000, "Fournitures"),
        ChartData(2, 8000, "Équipement"),
        ChartData(3, 5000, "Transport"),
        ChartData(4, 3000, "Autres"),
      ];

      salaryData.value = [
        ChartData(1, 45000, "Salaires"),
        ChartData(2, 5000, "Primes"),
        ChartData(3, 3000, "Avantages"),
        ChartData(4, 2000, "Autres"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('revenue', revenueData);
      updateChartData('payments', paymentData);
      updateChartData('expenses', expenseData);
      updateChartData('salaries', salaryData);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  // Méthode publique pour recharger les entités en attente
  Future<void> refreshPendingEntities() async {
    await _loadPendingEntities();
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
      pendingFactures.value = pendingFacturesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingFactures',
        pendingFacturesCount,
      );

      final paiements = await _paymentService.getAllPayments();
      // Utiliser la propriété isPending du modèle qui gère tous les cas
      final pendingPaiementsCount = paiements.where((p) => p.isPending).length;
      pendingPaiements.value = pendingPaiementsCount;
      CacheHelper.set(
        'dashboard_comptable_pendingPaiements',
        pendingPaiementsCount,
      );

      final depenses = await _expenseService.getExpenses();
      final pendingDepensesCount =
          depenses.where((d) => d.status == 'pending').length;
      pendingDepenses.value = pendingDepensesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingDepenses',
        pendingDepensesCount,
      );

      final salaires = await _salaryService.getSalaries();
      final pendingSalairesCount =
          salaires.where((s) => s.status == 'pending').length;
      pendingSalaires.value = pendingSalairesCount;
      CacheHelper.set(
        'dashboard_comptable_pendingSalaires',
        pendingSalairesCount,
      );
    } catch (e) {
      pendingFactures.value = 0;
      pendingPaiements.value = 0;
      pendingDepenses.value = 0;
      pendingSalaires.value = 0;
    }
  }

  Future<void> _loadValidatedEntities() async {
    try {
      // OPTIMISATION : Charger toutes les entités en parallèle
      final results = await Future.wait([
        _invoiceService.getAllInvoices(),
        _paymentService.getAllPayments(),
        _expenseService.getExpenses(),
        _salaryService.getSalaries(),
      ], eagerError: false);

      final factures = results[0] as List;
      validatedFactures.value = factures.length - pendingFactures.value;

      final paiements = results[1] as List;
      validatedPaiements.value = paiements.length - pendingPaiements.value;

      final depenses = results[2] as List;
      validatedDepenses.value = depenses.length - pendingDepenses.value;

      final salaires = results[3] as List;
      validatedSalaires.value = salaires.length - pendingSalaires.value;
    } catch (e) {
      validatedFactures.value = 0;
      validatedPaiements.value = 0;
      validatedDepenses.value = 0;
      validatedSalaires.value = 0;
    }
  }

  Future<void> _loadStatistics() async {
    try {
      // OPTIMISATION : Charger toutes les données en parallèle
      final results = await Future.wait([
        _invoiceService.getAllInvoices(),
        _paymentService.getAllPayments(),
        _expenseService.getExpenses(),
        _salaryService.getSalaries(),
      ], eagerError: false);

      final factures = results[0] as List;
      // Calculer le total des factures validées (chiffre d'affaires)
      final statusLower = (String status) => status.toLowerCase().trim();
      final revenue = factures
          .where((f) {
            final status = statusLower(f.status);
            return status == 'valide' ||
                status == 'validated' ||
                status == 'approved';
          })
          .fold(0.0, (sum, f) => sum + f.totalAmount);
      totalRevenue.value = revenue;
      CacheHelper.set('dashboard_comptable_totalRevenue', revenue);

      final paiements = results[1] as List;
      final payments = paiements.fold(0.0, (sum, p) => sum + (p.amount ?? 0.0));
      totalPayments.value = payments;
      CacheHelper.set('dashboard_comptable_totalPayments', payments);

      final depenses = results[2] as List;
      final expenses = depenses.fold(0.0, (sum, d) => sum + (d.amount ?? 0.0));
      totalExpenses.value = expenses;
      CacheHelper.set('dashboard_comptable_totalExpenses', expenses);

      final salaires = results[3] as List;
      final salaries = salaires.fold(0.0, (sum, s) => sum + (s.netSalary));
      totalSalaries.value = salaries;
      CacheHelper.set('dashboard_comptable_totalSalaries', salaries);

      netProfit.value = revenue - expenses - salaries;
    } catch (e) {
      totalRevenue.value = 0.0;
      totalPayments.value = 0.0;
      totalExpenses.value = 0.0;
      totalSalaries.value = 0.0;
      netProfit.value = 0.0;
    }
  }
}
