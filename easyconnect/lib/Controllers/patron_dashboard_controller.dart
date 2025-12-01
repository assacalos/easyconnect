import 'package:easyconnect/utils/dashboard_filters.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/stats_grid.dart';
import 'package:easyconnect/Views/Patron/patron_permissions.dart';
import 'package:easyconnect/utils/roles.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/utils/cache_helper.dart';
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
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/leave_service.dart';
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
  final ContractService _contractService = Get.find<ContractService>();
  final LeaveService _leaveService = Get.find<LeaveService>();

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
  final pendingContracts = 0.obs;
  final pendingLeaves = 0.obs;
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
  void loadCachedData() {
    // Charger les données depuis le cache pour un affichage instantané
    final cachedPendingClients = CacheHelper.get<int>(
      'dashboard_patron_pendingClients',
    );
    if (cachedPendingClients != null)
      pendingClients.value = cachedPendingClients;

    final cachedPendingDevis = CacheHelper.get<int>(
      'dashboard_patron_pendingDevis',
    );
    if (cachedPendingDevis != null) pendingDevis.value = cachedPendingDevis;

    final cachedPendingBordereaux = CacheHelper.get<int>(
      'dashboard_patron_pendingBordereaux',
    );
    if (cachedPendingBordereaux != null)
      pendingBordereaux.value = cachedPendingBordereaux;

    final cachedPendingBonCommandes = CacheHelper.get<int>(
      'dashboard_patron_pendingBonCommandes',
    );
    if (cachedPendingBonCommandes != null)
      pendingBonCommandes.value = cachedPendingBonCommandes;

    final cachedPendingFactures = CacheHelper.get<int>(
      'dashboard_patron_pendingFactures',
    );
    if (cachedPendingFactures != null)
      pendingFactures.value = cachedPendingFactures;

    final cachedPendingPaiements = CacheHelper.get<int>(
      'dashboard_patron_pendingPaiements',
    );
    if (cachedPendingPaiements != null)
      pendingPaiements.value = cachedPendingPaiements;

    final cachedPendingDepenses = CacheHelper.get<int>(
      'dashboard_patron_pendingDepenses',
    );
    if (cachedPendingDepenses != null)
      pendingDepenses.value = cachedPendingDepenses;

    final cachedPendingSalaires = CacheHelper.get<int>(
      'dashboard_patron_pendingSalaires',
    );
    if (cachedPendingSalaires != null)
      pendingSalaires.value = cachedPendingSalaires;

    final cachedPendingInterventions = CacheHelper.get<int>(
      'dashboard_patron_pendingInterventions',
    );
    if (cachedPendingInterventions != null)
      pendingInterventions.value = cachedPendingInterventions;

    final cachedPendingTaxes = CacheHelper.get<int>(
      'dashboard_patron_pendingTaxes',
    );
    if (cachedPendingTaxes != null) pendingTaxes.value = cachedPendingTaxes;

    final cachedValidatedClients = CacheHelper.get<int>(
      'dashboard_patron_validatedClients',
    );
    if (cachedValidatedClients != null)
      validatedClients.value = cachedValidatedClients;

    final cachedTotalRevenue = CacheHelper.get<double>(
      'dashboard_patron_totalRevenue',
    );
    if (cachedTotalRevenue != null) totalRevenue.value = cachedTotalRevenue;
  }

  @override
  Future<void> loadData() async {
    if (isLoading.value) {
      return;
    }
    // Ne pas bloquer l'UI - charger en arrière-plan
    isLoading.value = false; // Permettre l'affichage immédiat

    try {
      // Charger les données des validations en attente (non-bloquant)
      _loadPendingValidations().catchError((e) {
        AppLogger.error(
          'Erreur lors du chargement des validations: $e',
          tag: 'PATRON_DASHBOARD',
        );
      });

      // Charger les métriques de performance (non-bloquant)
      _loadPerformanceMetrics().catchError((e) {
        AppLogger.error(
          'Erreur lors du chargement des métriques: $e',
          tag: 'PATRON_DASHBOARD',
        );
      });

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
      // Logger l'erreur pour le débogage
      AppLogger.error(
        'Erreur lors du chargement des données du dashboard: $e',
        tag: 'PATRON_DASHBOARD',
        error: e,
      );

      // Afficher un message à l'utilisateur seulement si c'est une erreur critique
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        Get.snackbar(
          'Erreur d\'authentification',
          'Votre session a expiré. Veuillez vous reconnecter.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 5),
        );
      }
    }
    // Ne pas mettre isLoading à false ici car on charge en arrière-plan
  }

  Future<void> _loadPendingValidations() async {
    // OPTIMISATION : Charger toutes les entités en parallèle au lieu de séquentiellement
    // Cela réduit le temps de chargement de ~15s à ~2-3s
    await Future.wait([
      // Charger les clients en attente (status = 0 ou null)
      _loadPendingClients(),

      // Charger les devis en attente (status = 1)
      _loadPendingDevis(),

      // Charger les bordereaux en attente (status = 1)
      _loadPendingBordereaux(),

      // Charger les bons de commande en attente (status = 0)
      _loadPendingBonCommandes(),

      // Charger les factures en attente (status = 'draft' ou 'en_attente')
      _loadPendingFactures(),

      // Charger les paiements en attente (status = 'pending' ou 'submitted' ou 'draft')
      _loadPendingPaiements(),

      // Charger les dépenses en attente (status = 'pending')
      _loadPendingDepenses(),

      // Charger les salaires en attente (status = 'pending')
      _loadPendingSalaires(),

      // Charger les rapports en attente (status = 'submitted')
      _loadPendingReporting(),

      // Charger les pointages en attente (status = 'pending')
      _loadPendingPointages(),

      // Charger les interventions en attente (status = 'pending')
      _loadPendingInterventions(),

      // Charger les taxes en attente (status = 'pending')
      _loadPendingTaxes(),

      // Charger les recrutements en attente (status = 'draft')
      _loadPendingRecruitments(),

      // Charger les contrats en attente (status = 'pending')
      _loadPendingContracts(),

      // Charger les congés en attente (status = 'pending')
      _loadPendingLeaves(),

      // Charger les fournisseurs en attente (status = 'pending')
      _loadPendingSuppliers(),

      // Charger les stocks en attente (status = 'pending')
      _loadPendingStocks(),
    ], eagerError: false); // Continuer même si une requête échoue
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      // OPTIMISATION : Charger toutes les métriques en parallèle
      await Future.wait([
        _loadTotalRevenue(),
        _loadTotalEmployees(),
        _loadTotalSuppliers(),
        _loadValidatedClients(),
      ], eagerError: false);
    } catch (e) {
      validatedClients.value = 0;
      totalEmployees.value = 0;
      totalSuppliers.value = 0;
      totalRevenue.value = 0.0;
    }
  }

  Future<void> _loadTotalRevenue() async {
    try {
      final factures = await _invoiceService.getAllInvoices();
      // Calculer le total des factures validées (chiffre d'affaires)
      final statusLower = (String status) => status.toLowerCase().trim();
      final revenue = factures
          .where((facture) {
            final status = statusLower(facture.status);
            return status == 'valide' ||
                status == 'validated' ||
                status == 'approved';
          })
          .fold(0.0, (sum, facture) => sum + facture.totalAmount);
      totalRevenue.value = revenue;
      CacheHelper.set('dashboard_patron_totalRevenue', revenue);
    } catch (e) {
      totalRevenue.value = 0.0;
    }
  }

  Future<void> _loadTotalEmployees() async {
    try {
      final employees = await _employeeService.getEmployees();
      totalEmployees.value = employees.length;
    } catch (e) {
      totalEmployees.value = 0;
    }
  }

  Future<void> _loadTotalSuppliers() async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      totalSuppliers.value = suppliers.length;
    } catch (e) {
      totalSuppliers.value = 0;
    }
  }

  Future<void> _loadValidatedClients() async {
    try {
      final clients = await _clientService.getClients();
      final count =
          clients
              .where((client) => client.status == 1) // 1 = validé
              .length;
      validatedClients.value = count;
      CacheHelper.set('dashboard_patron_validatedClients', count);
    } catch (e) {
      validatedClients.value = 0;
    }
  }

  // Méthodes de chargement individuelles pour chaque entité
  Future<void> _loadPendingClients() async {
    try {
      final clients = await _clientService.getClients();
      final count =
          clients
              .where((client) => client.status == 0 || client.status == null)
              .length;
      pendingClients.value = count;
      // Sauvegarder dans le cache pour un affichage instantané la prochaine fois
      CacheHelper.set('dashboard_patron_pendingClients', count);
    } catch (e) {
      pendingClients.value = 0;
    }
  }

  Future<void> _loadPendingDevis() async {
    try {
      final devis = await _devisService.getDevis();
      final count =
          devis
              .where(
                (devis) => devis.status == 1, // 1 = en attente
              )
              .length;
      pendingDevis.value = count;
      CacheHelper.set('dashboard_patron_pendingDevis', count);
    } catch (e) {
      pendingDevis.value = 0;
    }
  }

  Future<void> _loadPendingBordereaux() async {
    try {
      final bordereaux = await _bordereauService.getBordereaux();
      final count =
          bordereaux
              .where(
                (bordereau) => bordereau.status == 1, // 1 = en attente
              )
              .length;
      pendingBordereaux.value = count;
      CacheHelper.set('dashboard_patron_pendingBordereaux', count);
    } catch (e) {
      pendingBordereaux.value = 0;
    }
  }

  Future<void> _loadPendingBonCommandes() async {
    try {
      final bonCommandes = await _bonCommandeService.getBonCommandes();
      final count =
          bonCommandes
              .where(
                (bon) => bon.status == 1, // 1 = en attente
              )
              .length;
      pendingBonCommandes.value = count;
      CacheHelper.set('dashboard_patron_pendingBonCommandes', count);
    } catch (e) {
      pendingBonCommandes.value = 0;
    }
  }

  Future<void> _loadPendingFactures() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<InvoiceService>()) {
        pendingFactures.value = 0;
        return;
      }

      final factures = await _invoiceService.getAllInvoices();
      final statusLower = (String status) => status.toLowerCase().trim();
      final count =
          factures.where(
            (facture) {
              final status = statusLower(facture.status);
              return status == 'draft' ||
                  status == 'en_attente' ||
                  status == 'pending' ||
                  status == 'en attente';
            }, // draft, en_attente, pending ou en attente = en attente
          ).length;
      pendingFactures.value = count;
      CacheHelper.set('dashboard_patron_pendingFactures', count);
    } catch (e, stackTrace) {
      pendingFactures.value = 0;
    }
  }

  Future<void> _loadPendingPaiements() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<PaymentService>()) {
        pendingPaiements.value = 0;
        return;
      }

      final paiements = await _paymentService.getAllPayments();
      // Utiliser la propriété isPending du modèle qui gère tous les cas (pending, submitted, draft)
      final count = paiements.where((paiement) => paiement.isPending).length;
      pendingPaiements.value = count;
      CacheHelper.set('dashboard_patron_pendingPaiements', count);
    } catch (e, stackTrace) {
      pendingPaiements.value = 0;
    }
  }

  Future<void> _loadPendingDepenses() async {
    try {
      final depenses = await _expenseService.getExpenses();
      final count =
          depenses.where((depense) => depense.status == 'pending').length;
      pendingDepenses.value = count;
      CacheHelper.set('dashboard_patron_pendingDepenses', count);
    } catch (e) {
      pendingDepenses.value = 0;
    }
  }

  Future<void> _loadPendingSalaires() async {
    try {
      final salaires = await _salaryService.getSalaries();
      final count =
          salaires.where((salaire) => salaire.status == 'pending').length;
      pendingSalaires.value = count;
      CacheHelper.set('dashboard_patron_pendingSalaires', count);
    } catch (e) {
      pendingSalaires.value = 0;
    }
  }

  Future<void> _loadPendingReporting() async {
    try {
      final reports = await _reportingService.getAllReports();
      final count =
          reports.where((report) => report.status == 'submitted').length;
      pendingReporting.value = count;
      CacheHelper.set('dashboard_patron_pendingReporting', count);
    } catch (e) {
      pendingReporting.value = 0;
    }
  }

  Future<void> _loadPendingPointages() async {
    try {
      final pointages = await _attendanceService.getAttendances();
      final count =
          pointages
              .where((pointage) => pointage.status.toLowerCase() == 'pending')
              .length;
      pendingPointages.value = count;
      CacheHelper.set('dashboard_patron_pendingPointages', count);
    } catch (e) {
      pendingPointages.value = 0;
    }
  }

  Future<void> _loadPendingInterventions() async {
    try {
      final interventions = await _interventionService.getInterventions();
      final count =
          interventions
              .where(
                (intervention) =>
                    intervention.status.toLowerCase() == 'pending',
              )
              .length;
      pendingInterventions.value = count;
      CacheHelper.set('dashboard_patron_pendingInterventions', count);
    } catch (e) {
      pendingInterventions.value = 0;
    }
  }

  Future<void> _loadPendingTaxes() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<TaxService>()) {
        pendingTaxes.value = 0;
        return;
      }

      final taxes = await _taxService.getTaxes();
      // Utiliser la propriété isPending du modèle qui gère tous les cas
      final count = taxes.where((tax) => tax.isPending).length;
      pendingTaxes.value = count;
      CacheHelper.set('dashboard_patron_pendingTaxes', count);
    } catch (e, stackTrace) {
      pendingTaxes.value = 0;
    }
  }

  Future<void> _loadPendingRecruitments() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<RecruitmentService>()) {
        pendingRecruitments.value = 0;
        return;
      }

      final recruitments =
          await _recruitmentService.getAllRecruitmentRequests();
      // Les recrutements en attente peuvent avoir le statut 'draft' ou 'published'
      pendingRecruitments.value =
          recruitments
              .where(
                (recruitment) =>
                    recruitment.status.toLowerCase() == 'draft' ||
                    recruitment.status.toLowerCase() == 'published',
              )
              .length;
    } catch (e, stackTrace) {
      pendingRecruitments.value = 0;
    }
  }

  Future<void> _loadPendingSuppliers() async {
    try {
      final suppliers = await _supplierService.getSuppliers();
      pendingSuppliers.value =
          suppliers.where((supplier) => supplier.statut == 'pending').length;
    } catch (e) {
      pendingSuppliers.value = 0;
    }
  }

  Future<void> _loadPendingContracts() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<ContractService>()) {
        pendingContracts.value = 0;
        return;
      }

      final contracts = await _contractService.getAllContracts();
      pendingContracts.value =
          contracts
              .where(
                (contract) =>
                    contract.status.toLowerCase() == 'pending' ||
                    contract.status.toLowerCase() == 'draft',
              )
              .length;
    } catch (e, stackTrace) {
      pendingContracts.value = 0;
    }
  }

  Future<void> _loadPendingLeaves() async {
    try {
      // Vérifier que le service est bien initialisé
      if (!Get.isRegistered<LeaveService>()) {
        pendingLeaves.value = 0;
        return;
      }

      final leaves = await _leaveService.getAllLeaveRequests();
      pendingLeaves.value =
          leaves
              .where(
                (leave) =>
                    leave.status.toLowerCase() == 'pending' ||
                    leave.status.toLowerCase() == 'submitted',
              )
              .length;
    } catch (e, stackTrace) {
      pendingLeaves.value = 0;
    }
  }

  Future<void> _loadPendingStocks() async {
    try {
      final stocks = await _stockService.getStocks();
      pendingStocks.value =
          stocks.where((stock) => stock.status == 'pending').length;
    } catch (e) {
      pendingStocks.value = 0;
    }
  }

  // Méthode publique pour rafraîchir uniquement les compteurs en attente
  // À appeler après chaque validation/rejet d'une entité
  Future<void> refreshPendingCounters() async {
    try {
      await _loadPendingValidations();
    } catch (e) {
      print(
        '❌ [PATRON DASHBOARD] Erreur lors du rafraîchissement des compteurs: $e',
      );
    }
  }

  // Méthode pour rafraîchir un compteur spécifique
  Future<void> refreshSpecificCounter(String entityType) async {
    try {
      switch (entityType.toLowerCase()) {
        case 'client':
        case 'clients':
          await _loadPendingClients();
          break;
        case 'devis':
          await _loadPendingDevis();
          break;
        case 'bordereau':
        case 'bordereaux':
          await _loadPendingBordereaux();
          break;
        case 'boncommande':
        case 'bon_commande':
        case 'bon_commandes':
        case 'boncommandes':
          await _loadPendingBonCommandes();
          break;
        case 'facture':
        case 'factures':
        case 'invoice':
        case 'invoices':
          await _loadPendingFactures();
          break;
        case 'paiement':
        case 'paiements':
        case 'payment':
        case 'payments':
          await _loadPendingPaiements();
          break;
        case 'depense':
        case 'depenses':
        case 'expense':
        case 'expenses':
          await _loadPendingDepenses();
          break;
        case 'salaire':
        case 'salaires':
        case 'salary':
        case 'salaries':
          await _loadPendingSalaires();
          break;
        case 'reporting':
        case 'reports':
          await _loadPendingReporting();
          break;
        case 'pointage':
        case 'pointages':
          await _loadPendingPointages();
          break;
        case 'intervention':
        case 'interventions':
          await _loadPendingInterventions();
          break;
        case 'taxe':
        case 'taxes':
          await _loadPendingTaxes();
          break;
        case 'recruitment':
        case 'recruitments':
          await _loadPendingRecruitments();
          break;
        case 'contract':
        case 'contracts':
          await _loadPendingContracts();
          break;
        case 'leave':
        case 'leaves':
          await _loadPendingLeaves();
          break;
        case 'supplier':
        case 'suppliers':
          await _loadPendingSuppliers();
          break;
        case 'stock':
        case 'stocks':
          await _loadPendingStocks();
          break;
        default:
          // Si le type n'est pas reconnu, rafraîchir tous les compteurs
          await _loadPendingValidations();
      }
    } catch (e) {
      print(
        '❌ [PATRON DASHBOARD] Erreur lors du rafraîchissement du compteur $entityType: $e',
      );
    }
  }
}
