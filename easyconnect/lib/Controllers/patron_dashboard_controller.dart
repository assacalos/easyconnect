import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Patron/patron_permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/utils/permissions.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';

class PatronDashboardController extends BaseDashboardController {
  var currentSection = PatronSection.dashboard.obs;
  var selectedPeriod = 'month'.obs;
  var selectedDepartment = 'all'.obs;

  // Services pour récupérer les données directement
  final ClientService _clientService = Get.find<ClientService>();
  final DevisService _devisService = Get.find<DevisService>();
  final BordereauService _bordereauService = Get.find<BordereauService>();
  final InvoiceService _invoiceService = Get.find<InvoiceService>();
  final PaymentService _paymentService = Get.find<PaymentService>();
  final ExpenseService _expenseService = Get.find<ExpenseService>();
  final SalaryService _salaryService = Get.find<SalaryService>();
  final ReportingService _reportingService = Get.find<ReportingService>();
  final AttendancePunchService _attendanceService =
      Get.find<AttendancePunchService>();
  final BonCommandeService _bonCommandeService = Get.find<BonCommandeService>();
  final InterventionService _interventionService =
      Get.find<InterventionService>();
  final TaxService _taxService = Get.find<TaxService>();
  final RecruitmentService _recruitmentService = Get.find<RecruitmentService>();
  final SupplierService _supplierService = Get.find<SupplierService>();
  final StockService _stockService = Get.find<StockService>();
  final EmployeeService _employeeService = Get.find<EmployeeService>();

  List<Filter> get filters => DashboardFilters.getFiltersForRole(Roles.PATRON);

  // Données des graphiques
  final revenueData = <ChartData>[].obs;
  final employeeData = <ChartData>[].obs;
  final ticketData = <ChartData>[].obs;
  final leaveData = <ChartData>[].obs;

  // Nouvelles données pour le dashboard amélioré
  // Première partie - Validations en attente
  final pendingClients = 0.obs;
  final pendingDevis = 0.obs;
  final pendingBordereaux = 0.obs;
  final pendingBonCommandes = 0.obs;
  final pendingFactures = 0.obs;
  final pendingPaiements = 0.obs;
  final pendingDepenses = 0.obs;
  final pendingSalaires = 0.obs;
  final pendingReporting = 0.obs;
  final pendingPointages = 0.obs;
  final pendingInterventions = 0.obs;
  final pendingTaxes = 0.obs;
  final pendingRecruitments = 0.obs;
  final pendingSuppliers = 0.obs;
  final pendingStocks = 0.obs;

  // Deuxième partie - Métriques de performance
  final validatedClients = 0.obs;
  final totalEmployees = 0.obs;
  final totalSuppliers = 0.obs;
  final totalRevenue = 0.0.obs;

  // Statistiques originales
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
      requiredPermission: Permissions.VIEW_DEVIS,
    ),
    StatCard(
      title: "Bordereaux en attente",
      value: pendingBordereaux.value.toString(),
      icon: Icons.assignment_turned_in,
      color: Colors.orange,
      requiredPermission: Permissions.VIEW_SALES,
    ),
    StatCard(
      title: "Bons de commande en attente",
      value: pendingBonCommandes.value.toString(),
      icon: Icons.shopping_cart,
      color: Colors.purple,
      requiredPermission: Permissions.VIEW_SALES,
    ),
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
      color: Colors.indigo,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Salaires en attente",
      value: pendingSalaires.value.toString(),
      icon: Icons.account_balance_wallet,
      color: Colors.amber,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Rapports en attente",
      value: pendingReporting.value.toString(),
      icon: Icons.analytics,
      color: Colors.cyan,
      requiredPermission: Permissions.VIEW_REPORTS,
    ),
    StatCard(
      title: "Pointages en attente",
      value: pendingPointages.value.toString(),
      icon: Icons.access_time,
      color: Colors.brown,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Interventions en attente",
      value: pendingInterventions.value.toString(),
      icon: Icons.build,
      color: Colors.deepOrange,
      requiredPermission: Permissions.MANAGE_INTERVENTIONS,
    ),
    StatCard(
      title: "Taxes en attente",
      value: pendingTaxes.value.toString(),
      icon: Icons.account_balance,
      color: Colors.pink,
      requiredPermission: Permissions.VIEW_FINANCES,
    ),
    StatCard(
      title: "Recrutements en attente",
      value: pendingRecruitments.value.toString(),
      icon: Icons.person_add,
      color: Colors.lightBlue,
      requiredPermission: Permissions.MANAGE_EMPLOYEES,
    ),
    StatCard(
      title: "Fournisseurs en attente",
      value: pendingSuppliers.value.toString(),
      icon: Icons.business,
      color: Colors.grey,
      requiredPermission: Permissions.MANAGE_SUPPLIERS,
    ),
    StatCard(
      title: "Stocks en attente",
      value: pendingStocks.value.toString(),
      icon: Icons.inventory,
      color: Colors.deepPurple,
      requiredPermission: Permissions.MANAGE_STOCKS,
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
    print('🔄 PatronDashboardController.loadData - Début');
    if (isLoading.value) {
      print(
        '⚠️ PatronDashboardController.loadData - Déjà en cours de chargement',
      );
      return;
    }
    isLoading.value = true;

    try {
      print('⏳ PatronDashboardController.loadData - Attente de 1 seconde...');
      await Future.delayed(const Duration(seconds: 1));

      // Charger les données des validations en attente
      print(
        '📥 PatronDashboardController.loadData - Chargement des validations...',
      );
      await _loadPendingValidations();

      // Charger les métriques de performance
      print(
        '📥 PatronDashboardController.loadData - Chargement des métriques...',
      );
      await _loadPerformanceMetrics();

      // Simuler le chargement des données des graphiques
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

  Future<void> _loadPendingValidations() async {
    print('🎯 PatronDashboardController._loadPendingValidations - Début');
    try {
      // Charger les clients en attente (status = 0 ou null)
      await _loadPendingClients();

      // Charger les devis en attente (status = 1)
      await _loadPendingDevis();

      // Charger les bordereaux en attente (status = 1)
      await _loadPendingBordereaux();

      // Charger les bons de commande en attente (status = 0)
      await _loadPendingBonCommandes();

      // Charger les factures en attente (status = 'draft')
      await _loadPendingFactures();

      // Charger les paiements en attente (status = 'pending' ou 'submitted')
      await _loadPendingPaiements();

      // Charger les dépenses en attente (status = 'pending')
      await _loadPendingDepenses();

      // Charger les salaires en attente (status = 'pending')
      await _loadPendingSalaires();

      // Charger les rapports en attente (status = 'submitted')
      await _loadPendingReporting();

      // Charger les pointages en attente (status = 'pending')
      await _loadPendingPointages();

      // Charger les interventions en attente (status = 'pending')
      await _loadPendingInterventions();

      // Charger les taxes en attente (status = 'pending')
      await _loadPendingTaxes();

      // Charger les recrutements en attente (status = 'draft')
      await _loadPendingRecruitments();

      // Charger les fournisseurs en attente (status = 'pending')
      await _loadPendingSuppliers();

      // Charger les stocks en attente (status = 'pending')
      await _loadPendingStocks();

      print('🎯 PatronDashboardController - Toutes les validations chargées:');
      print('   - Clients: ${pendingClients.value}');
      print('   - Devis: ${pendingDevis.value}');
      print('   - Bordereaux: ${pendingBordereaux.value}');
      print('   - Bons de commande: ${pendingBonCommandes.value}');
      print('   - Factures: ${pendingFactures.value}');
      print('   - Paiements: ${pendingPaiements.value}');
      print('   - Dépenses: ${pendingDepenses.value}');
      print('   - Salaires: ${pendingSalaires.value}');
      print('   - Reporting: ${pendingReporting.value}');
      print('   - Pointages: ${pendingPointages.value}');
      print('   - Interventions: ${pendingInterventions.value}');
      print('   - Taxes: ${pendingTaxes.value}');
      print('   - Recrutements: ${pendingRecruitments.value}');
      print('   - Fournisseurs: ${pendingSuppliers.value}');
      print('   - Stocks: ${pendingStocks.value}');
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement des validations: $e');
      print('❌ Stack trace: $stackTrace');
      // Réinitialiser toutes les valeurs en cas d'erreur
      _resetAllPendingCounts();
    }
  }

  void _resetAllPendingCounts() {
    pendingClients.value = 0;
    pendingDevis.value = 0;
    pendingBordereaux.value = 0;
    pendingBonCommandes.value = 0;
    pendingFactures.value = 0;
    pendingPaiements.value = 0;
    pendingDepenses.value = 0;
    pendingSalaires.value = 0;
    pendingReporting.value = 0;
    pendingPointages.value = 0;
    pendingInterventions.value = 0;
    pendingTaxes.value = 0;
    pendingRecruitments.value = 0;
    pendingSuppliers.value = 0;
    pendingStocks.value = 0;
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      // Charger le chiffre d'affaires depuis les factures
      await _loadTotalRevenue();

      // Charger le nombre d'employés depuis les utilisateurs
      await _loadTotalEmployees();

      // Charger le nombre de fournisseurs
      await _loadTotalSuppliers();

      // Charger le nombre de clients validés
      await _loadValidatedClients();
    } catch (e) {
      print('❌ Erreur lors du chargement des métriques: $e');
      validatedClients.value = 0;
      totalEmployees.value = 0;
      totalSuppliers.value = 0;
      totalRevenue.value = 0.0;
    }
  }

  Future<void> _loadTotalRevenue() async {
    try {
      final factures = await _invoiceService.getAllInvoices();
      // Calculer le total des factures payées
      totalRevenue.value = factures
          .where((facture) => facture.status == 'paid')
          .fold(0.0, (sum, facture) => sum + facture.totalAmount);
      print('💰 Chiffre d\'affaires: ${totalRevenue.value} FCFA');
    } catch (e) {
      print('❌ Erreur chargement chiffre d\'affaires: $e');
      totalRevenue.value = 0.0;
    }
  }

  Future<void> _loadTotalEmployees() async {
    try {
      final employees = await _employeeService.getEmployees();
      totalEmployees.value = employees.length;
      print('👥 Nombre d\'employés: ${totalEmployees.value}');
    } catch (e) {
      print('❌ Erreur chargement employés: $e');
      totalEmployees.value = 0;
    }
  }

  Future<void> _loadTotalSuppliers() async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      totalSuppliers.value = suppliers.length;
      print('🏢 Nombre de fournisseurs: ${totalSuppliers.value}');
    } catch (e) {
      print('❌ Erreur chargement fournisseurs: $e');
      totalSuppliers.value = 0;
    }
  }

  Future<void> _loadValidatedClients() async {
    try {
      final clients = await _clientService.getClients();
      validatedClients.value =
          clients
              .where((client) => client.status == 1) // 1 = validé
              .length;
      print('✅ Clients validés: ${validatedClients.value}');
    } catch (e) {
      print('❌ Erreur chargement clients validés: $e');
      validatedClients.value = 0;
    }
  }

  // Méthodes de chargement individuelles pour chaque entité
  Future<void> _loadPendingClients() async {
    try {
      final clients = await _clientService.getClients();
      pendingClients.value =
          clients
              .where((client) => client.status == 0 || client.status == null)
              .length;
      print('📊 Clients en attente: ${pendingClients.value}');
    } catch (e) {
      print('❌ Erreur chargement clients: $e');
      pendingClients.value = 0;
    }
  }

  Future<void> _loadPendingDevis() async {
    try {
      final devis = await _devisService.getDevis();
      pendingDevis.value =
          devis
              .where(
                (devis) => devis.status == 1, // 1 = en attente
              )
              .length;
      print('📊 Devis en attente: ${pendingDevis.value}');
    } catch (e) {
      print('❌ Erreur chargement devis: $e');
      pendingDevis.value = 0;
    }
  }

  Future<void> _loadPendingBordereaux() async {
    try {
      final bordereaux = await _bordereauService.getBordereaux();
      pendingBordereaux.value =
          bordereaux
              .where(
                (bordereau) => bordereau.status == 1, // 1 = en attente
              )
              .length;
      print('📊 Bordereaux en attente: ${pendingBordereaux.value}');
    } catch (e) {
      print('❌ Erreur chargement bordereaux: $e');
      pendingBordereaux.value = 0;
    }
  }

  Future<void> _loadPendingBonCommandes() async {
    try {
      final bonCommandes = await _bonCommandeService.getBonCommandes();
      pendingBonCommandes.value =
          bonCommandes
              .where(
                (bon) => bon.status == 0, // 0 = en attente
              )
              .length;
      print('📊 Bons de commande en attente: ${pendingBonCommandes.value}');
    } catch (e) {
      print('❌ Erreur chargement bons de commande: $e');
      pendingBonCommandes.value = 0;
    }
  }

  Future<void> _loadPendingFactures() async {
    try {
      final factures = await _invoiceService.getAllInvoices();
      pendingFactures.value =
          factures
              .where(
                (facture) => facture.status == 'draft', // draft = en attente
              )
              .length;
      print('📊 Factures en attente: ${pendingFactures.value}');
    } catch (e) {
      print('❌ Erreur chargement factures: $e');
      pendingFactures.value = 0;
    }
  }

  Future<void> _loadPendingPaiements() async {
    try {
      final paiements = await _paymentService.getAllPayments();
      pendingPaiements.value =
          paiements
              .where(
                (paiement) =>
                    paiement.status == 'pending' ||
                    paiement.status == 'submitted',
              )
              .length;
      print('📊 Paiements en attente: ${pendingPaiements.value}');
    } catch (e) {
      print('❌ Erreur chargement paiements: $e');
      pendingPaiements.value = 0;
    }
  }

  Future<void> _loadPendingDepenses() async {
    try {
      final depenses = await _expenseService.getExpenses();
      pendingDepenses.value =
          depenses.where((depense) => depense.status == 'pending').length;
      print('📊 Dépenses en attente: ${pendingDepenses.value}');
    } catch (e) {
      print('❌ Erreur chargement dépenses: $e');
      pendingDepenses.value = 0;
    }
  }

  Future<void> _loadPendingSalaires() async {
    try {
      final salaires = await _salaryService.getSalaries();
      pendingSalaires.value =
          salaires.where((salaire) => salaire.status == 'pending').length;
      print('📊 Salaires en attente: ${pendingSalaires.value}');
    } catch (e) {
      print('❌ Erreur chargement salaires: $e');
      pendingSalaires.value = 0;
    }
  }

  Future<void> _loadPendingReporting() async {
    try {
      final reports = await _reportingService.getAllReports();
      pendingReporting.value =
          reports.where((report) => report.status == 'submitted').length;
      print('📊 Rapports en attente: ${pendingReporting.value}');
    } catch (e) {
      print('❌ Erreur chargement rapports: $e');
      pendingReporting.value = 0;
    }
  }

  Future<void> _loadPendingPointages() async {
    try {
      final pointages = await _attendanceService.getAttendances();
      pendingPointages.value =
          pointages
              .where((pointage) => pointage.status.toLowerCase() == 'pending')
              .length;
      print('📊 Pointages en attente: ${pendingPointages.value}');
    } catch (e) {
      print('❌ Erreur chargement pointages: $e');
      pendingPointages.value = 0;
    }
  }

  Future<void> _loadPendingInterventions() async {
    try {
      final interventions = await _interventionService.getInterventions();
      pendingInterventions.value =
          interventions
              .where(
                (intervention) =>
                    intervention.status.toLowerCase() == 'pending',
              )
              .length;
      print('📊 Interventions en attente: ${pendingInterventions.value}');
    } catch (e) {
      print('❌ Erreur chargement interventions: $e');
      pendingInterventions.value = 0;
    }
  }

  Future<void> _loadPendingTaxes() async {
    try {
      final taxes = await _taxService.getTaxes();
      pendingTaxes.value = taxes.where((tax) => tax.status == 'pending').length;
      print('📊 Taxes en attente: ${pendingTaxes.value}');
    } catch (e) {
      print('❌ Erreur chargement taxes: $e');
      pendingTaxes.value = 0;
    }
  }

  Future<void> _loadPendingRecruitments() async {
    try {
      final recruitments =
          await _recruitmentService.getAllRecruitmentRequests();
      pendingRecruitments.value =
          recruitments
              .where((recruitment) => recruitment.status == 'draft')
              .length;
      print('📊 Recrutements en attente: ${pendingRecruitments.value}');
    } catch (e) {
      print('❌ Erreur chargement recrutements: $e');
      pendingRecruitments.value = 0;
    }
  }

  Future<void> _loadPendingSuppliers() async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      pendingSuppliers.value =
          suppliers.where((supplier) => supplier.statut == 'pending').length;
      print('📊 Fournisseurs en attente: ${pendingSuppliers.value}');
    } catch (e) {
      print('❌ Erreur chargement fournisseurs: $e');
      pendingSuppliers.value = 0;
    }
  }

  Future<void> _loadPendingStocks() async {
    try {
      final stocks = await _stockService.getStocks();
      pendingStocks.value =
          stocks.where((stock) => stock.status == 'pending').length;
      print('📊 Stocks en attente: ${pendingStocks.value}');
    } catch (e) {
      print('❌ Erreur chargement stocks: $e');
      pendingStocks.value = 0;
    }
  }
}
