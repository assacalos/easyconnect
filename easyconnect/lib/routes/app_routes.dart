import 'package:easyconnect/Views/Commercial/client_details_page.dart';
import 'package:easyconnect/Views/Commercial/client_list_page.dart';
import 'package:easyconnect/Views/Commercial/client_form_page.dart';
import 'package:easyconnect/Views/Commercial/devis_list_page.dart';
import 'package:easyconnect/Views/Commercial/devis_form_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_list_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_list_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_list_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_form_page.dart';
import 'package:easyconnect/Views/Commercial/bon_de_commande_fournisseur_detail_page.dart';
import 'package:easyconnect/Views/Components/notifications_page.dart';
import 'package:easyconnect/Views/Patron/client_validation_page.dart';
import 'package:easyconnect/Views/Patron/bordereau_validation_page.dart';
import 'package:easyconnect/Views/Patron/bon_commande_validation_page.dart';
import 'package:easyconnect/Views/Patron/bon_de_commande_fournisseur_validation_page.dart';
import 'package:easyconnect/Views/Patron/devis_validation_page.dart';
import 'package:easyconnect/Views/Patron/facture_validation_page.dart';
import 'package:easyconnect/Views/Patron/paiement_validation_page.dart';
import 'package:easyconnect/Views/Patron/depense_validation_page.dart';
import 'package:easyconnect/Views/Patron/salaire_validation_page.dart';
import 'package:easyconnect/Views/Patron/pointage_validation_page.dart';
import 'package:easyconnect/Views/Patron/stock_validation_page.dart';
import 'package:easyconnect/Views/Patron/intervention_validation_page.dart';
import 'package:easyconnect/Views/Patron/recruitment_validation_page.dart';
import 'package:easyconnect/Views/Patron/contract_validation_page.dart';
import 'package:easyconnect/Views/Patron/leave_validation_page.dart';
import 'package:easyconnect/Views/Patron/taxe_validation_page.dart';
import 'package:easyconnect/Views/Patron/reporting_validation_page.dart';
import 'package:easyconnect/Views/Patron/supplier_validation_page.dart';
import 'package:easyconnect/Views/Patron/employee_validation_page.dart';
import 'package:easyconnect/Views/Patron/patron_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Admin/admin_dashboard.dart';
import 'package:easyconnect/Views/Components/global_search_page.dart';
import 'package:easyconnect/Views/Components/profile_page.dart';
import 'package:easyconnect/Views/Admin/user_management_page.dart';
import 'package:easyconnect/Views/Admin/user_form_page.dart';
import 'package:easyconnect/Views/Admin/app_settings_page.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Views/Auth/login_page.dart';
import 'package:easyconnect/Views/Auth/unauthorized_page.dart';
import 'package:easyconnect/Views/Commercial/commercial_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Comptable/comptable_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Rh/rh_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Technicien/technicien_dashboard_enhanced.dart';
import 'package:easyconnect/Views/Components/splash_screen.dart';
import 'package:easyconnect/middleware/auth_middleware.dart';
import 'package:easyconnect/bindings/commercial_binding.dart';
import 'package:easyconnect/bindings/patron_binding.dart';
import 'package:easyconnect/bindings/comptable_binding.dart';
import 'package:easyconnect/bindings/rh_binding.dart';
import 'package:easyconnect/bindings/technicien_binding.dart';
import 'package:easyconnect/bindings/global_search_binding.dart';
import 'package:easyconnect/bindings/admin_binding.dart';
import 'package:easyconnect/bindings/user_management_binding.dart';
import 'package:easyconnect/Views/Components/reporting_list.dart';
import 'package:easyconnect/Views/Components/reporting_form.dart';
import 'package:easyconnect/Views/Components/reporting_detail.dart';
import 'package:easyconnect/Models/reporting_model.dart';
import 'package:easyconnect/Views/Components/attendance_punch_page.dart';
import 'package:easyconnect/Views/Components/attendance_validation_page.dart';
import 'package:easyconnect/Views/Comptable/invoice_list_page.dart';
import 'package:easyconnect/Views/Comptable/invoice_form.dart';
import 'package:easyconnect/Views/Comptable/payment_list.dart';
import 'package:easyconnect/Views/Comptable/payment_form.dart';
import 'package:easyconnect/Views/Comptable/payment_detail.dart';
import 'package:easyconnect/Views/Comptable/supplier_list.dart';
import 'package:easyconnect/Views/Comptable/supplier_form.dart';
import 'package:easyconnect/Views/Comptable/supplier_detail.dart';
import 'package:easyconnect/Views/Comptable/tax_list.dart';
import 'package:easyconnect/Views/Comptable/tax_form.dart';
import 'package:easyconnect/Views/Comptable/tax_detail.dart';
import 'package:easyconnect/Views/Comptable/expense_list.dart';
import 'package:easyconnect/Views/Comptable/expense_form.dart';
import 'package:easyconnect/Views/Comptable/expense_detail.dart';
import 'package:easyconnect/Views/Comptable/salary_list.dart';
import 'package:easyconnect/Views/Comptable/salary_form.dart';
import 'package:easyconnect/Views/Comptable/salary_detail.dart';
import 'package:easyconnect/Views/Technicien/intervention_list.dart';
import 'package:easyconnect/Views/Technicien/intervention_form.dart';
import 'package:easyconnect/Views/Technicien/intervention_detail.dart';
import 'package:easyconnect/Views/Commercial/devis_detail_page.dart';
import 'package:easyconnect/Views/Commercial/bordereau_detail_page.dart';
import 'package:easyconnect/Views/Commercial/bon_commande_detail_page.dart';
import 'package:easyconnect/Views/Technicien/equipment_list.dart';
import 'package:easyconnect/Views/Technicien/equipment_form.dart';
import 'package:easyconnect/Views/Technicien/equipment_detail.dart';
import 'package:easyconnect/Views/Comptable/stock_list.dart';
import 'package:easyconnect/Views/Comptable/stock_form.dart';
import 'package:easyconnect/Views/Comptable/stock_detail.dart';
import 'package:easyconnect/Views/Rh/employee_list.dart';
import 'package:easyconnect/Views/Rh/employee_form.dart';
import 'package:easyconnect/Views/Rh/employee_detail.dart';
import 'package:easyconnect/Views/Rh/leave_list.dart';
import 'package:easyconnect/Views/Rh/leave_form.dart';
import 'package:easyconnect/Views/Rh/leave_detail.dart';
import 'package:easyconnect/Views/Rh/recruitment_list.dart';
import 'package:easyconnect/Views/Rh/recruitment_form.dart';
import 'package:easyconnect/Views/Rh/recruitment_detail.dart';
import 'package:easyconnect/Views/Rh/contract_list.dart';
import 'package:easyconnect/Views/Rh/contract_form.dart';
import 'package:easyconnect/Views/Rh/contract_detail.dart';
import 'package:easyconnect/Views/Patron/finances_page.dart';
import 'package:easyconnect/Views/Patron/patron_reports_page.dart';
import 'package:easyconnect/Views/Components/media_page.dart';

class AppRoutes {
  static final routes = [
    GetPage(name: '/splash', page: () => const SplashScreen()),
    GetPage(name: '/login', page: () => LoginPage()),
    GetPage(name: '/unauthorized', page: () => UnauthorizedPage()),
    GetPage(
      name: '/commercial',
      page: () => CommercialDashboardEnhanced(),
      binding: CommercialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/comptable',
      page: () => ComptableDashboardEnhanced(),
      binding: ComptableBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/patron',
      page: () => PatronDashboardEnhanced(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/patron/finances',
      page: () => const FinancesPage(),
      binding: ComptableBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/patron/reports',
      page: () => const PatronReportsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/rh',
      page: () => RhDashboardEnhanced(),
      binding: RhBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/technicien',
      page: () => TechnicienDashboardEnhanced(),
      binding: TechnicienBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour l'administrateur
    GetPage(
      name: '/admin',
      page: () => const AdminDashboard(),
      binding: AdminBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/admin/users',
      page: () => const UserManagementPage(),
      binding: UserManagementBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/admin/users/new',
      page: () => const UserFormPage(),
      binding: UserManagementBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/admin/users/:id/edit',
      page:
          () => UserFormPage(
            isEditing: true,
            userId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      binding: UserManagementBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/admin/settings',
      page: () => const AppSettingsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients',
      page: () => ClientsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients/new',
      page: () => ClientFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients/validation',
      page: () => ClientValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/clients/:id',
      page:
          () => ClientDetailsPage(
            clientId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis',
      page: () => DevisListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/new',
      page: () => DevisFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/validation',
      page: () => const DevisValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/:id/edit',
      page:
          () => DevisFormPage(
            isEditing: true,
            devisId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis/:id',
      page:
          () => DevisDetailPage(
            devisId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      binding: CommercialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux',
      page: () => BordereauListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/new',
      page: () => BordereauFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/validation',
      page: () => const BordereauValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/:id/edit',
      page:
          () => BordereauFormPage(
            isEditing: true,
            bordereauId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bordereaux/:id',
      page:
          () => BordereauDetailPage(
            bordereauId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      binding: CommercialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes',
      page: () => BonCommandeListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/new',
      page: () => BonCommandeFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/validation',
      page: () => const BonCommandeValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/:id/edit',
      page:
          () => BonCommandeFormPage(
            isEditing: true,
            bonCommandeId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bon-commandes/:id',
      page:
          () => BonCommandeDetailPage(
            bonCommandeId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      binding: CommercialBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les bons de commande fournisseur
    GetPage(
      name: '/bons-de-commande-fournisseur',
      page: () => BonDeCommandeFournisseurListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bons-de-commande-fournisseur/new',
      page: () => BonDeCommandeFournisseurFormPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bons-de-commande-fournisseur/validation',
      page: () => const BonDeCommandeFournisseurValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bons-de-commande-fournisseur/:id/edit',
      page:
          () => BonDeCommandeFournisseurFormPage(
            isEditing: true,
            bonDeCommandeId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/bons-de-commande-fournisseur/:id',
      page:
          () => BonDeCommandeFournisseurDetailPage(
            bonDeCommandeId: int.tryParse(Get.parameters['id'] ?? '0') ?? 0,
          ),
      middlewares: [AuthMiddleware()],
    ),
    // Routes de validation pour le patron
    GetPage(
      name: '/factures/validation',
      page: () => const FactureValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/paiements/validation',
      page: () => const PaiementValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/depenses/validation',
      page: () => const DepenseValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/stock/validation',
      page: () => const StockValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/interventions/validation',
      page: () => const InterventionValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/salaires/validation',
      page: () => const SalaireValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/recrutement/validation',
      page: () => const RecruitmentValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/contrats/validation',
      page: () => const ContractValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/conges/validation',
      page: () => const LeaveValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/pointage/validation',
      page: () => const PointageValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/taxes/validation',
      page: () => const TaxeValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/reporting/validation',
      page: () => const ReportingValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/employees/validation',
      page: () => const EmployeeValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Routes de reporting
    GetPage(
      name: '/reporting',
      page: () => const ReportingList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/reporting/new',
      page: () => const ReportingForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/user-reportings/:id',
      page: () => ReportingDetail(
        reporting: Get.arguments as ReportingModel,
      ),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/attendance-punch',
      page: () => const AttendancePunchPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/attendance-validation',
      page: () => const AttendanceValidationPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/invoices',
      page: () => const InvoiceListPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/invoices/new',
      page: () => const InvoiceForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments',
      page: () => const PaymentList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments/new',
      page: () => const PaymentForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments/detail',
      page: () => PaymentDetail(paymentId: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/payments/edit',
      page: () => PaymentForm(paymentId: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les fournisseurs
    GetPage(
      name: '/suppliers',
      page: () => const SupplierList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/suppliers/validation',
      page: () => const SupplierValidationPage(),
      binding: PatronBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/suppliers/new',
      page: () => const SupplierForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/suppliers/:id/edit',
      page: () => SupplierForm(supplier: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/suppliers/:id',
      page: () => SupplierDetail(supplier: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les impôts et taxes
    GetPage(
      name: '/taxes',
      page: () => const TaxList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/taxes/new',
      page: () => const TaxForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/taxes/:id/edit',
      page: () => TaxForm(tax: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/taxes/:id',
      page: () => TaxDetail(tax: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les dépenses
    GetPage(
      name: '/expenses',
      page: () => const ExpenseList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/expenses/new',
      page: () => const ExpenseForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/expenses/:id/edit',
      page: () => ExpenseForm(expense: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/expenses/:id',
      page: () => ExpenseDetail(expense: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les salaires
    GetPage(
      name: '/salaries',
      page: () => const SalaryList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/salaries/new',
      page: () => const SalaryForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/salaries/:id/edit',
      page: () => SalaryForm(salary: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/salaries/:id',
      page: () => SalaryDetail(salary: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les interventions
    GetPage(
      name: '/interventions',
      page: () => const InterventionList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/interventions/new',
      page: () => const InterventionForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/interventions/:id/edit',
      page: () => InterventionForm(intervention: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/interventions/:id',
      page: () => InterventionDetail(intervention: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour les équipements
    GetPage(
      name: '/equipments',
      page: () => const EquipmentList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/equipments/new',
      page: () => const EquipmentForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/equipments/:id/edit',
      page: () => EquipmentForm(equipment: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/equipments/:id',
      page: () => EquipmentDetail(equipment: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour la gestion de stock
    GetPage(
      name: '/stocks',
      page: () => const StockList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/stocks/new',
      page: () => const StockForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/stocks/:id/edit',
      page: () => StockForm(stock: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/stocks/:id',
      page: () => StockDetail(stock: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour la gestion des employés
    GetPage(
      name: '/employees',
      page: () => const EmployeeList(),
      binding: RhBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/employees/new',
      page: () => const EmployeeForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/employees/:id/edit',
      page: () => EmployeeForm(employee: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/employees/:id',
      page: () => EmployeeDetail(employee: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour la gestion des congés
    GetPage(
      name: '/leaves',
      page: () => const LeaveList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/leaves/new',
      page: () => const LeaveForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/leaves/:id/edit',
      page: () => LeaveForm(request: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/leaves/:id',
      page: () => LeaveDetail(request: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour la gestion des recrutements
    GetPage(
      name: '/recruitment',
      page: () => const RecruitmentList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/recruitment/new',
      page: () => const RecruitmentForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/recruitment/:id/edit',
      page: () => RecruitmentForm(request: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/recruitment/:id',
      page: () => RecruitmentDetail(request: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Routes pour la gestion des contrats
    GetPage(
      name: '/contracts',
      page: () => const ContractList(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/contracts/new',
      page: () => const ContractForm(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/contracts/:id/edit',
      page: () => ContractForm(contract: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/contracts/:id',
      page: () => ContractDetail(contract: Get.arguments),
      middlewares: [AuthMiddleware()],
    ),
    // Pages avec bottom navigation
    GetPage(
      name: '/clients-page',
      page: () => ClientsPage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/devis-page',
      page: () => DevisListPage(),
      middlewares: [AuthMiddleware()],
    ),
    // Recherche globale
    GetPage(
      name: '/search',
      page: () => const GlobalSearchPage(),
      binding: GlobalSearchBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Page de profil
    GetPage(
      name: '/profile',
      page: () => const ProfilePage(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: '/notifications',
      page: () => const NotificationsPage(),
      middlewares: [AuthMiddleware()],
    ),
    // Page des médias
    GetPage(
      name: '/media',
      page: () => const MediaPage(),
      middlewares: [AuthMiddleware()],
    ),
  ];

  static String getInitialRoute(int? userRole) {
    // Si pas de rôle ou utilisateur non connecté, aller à la page de connexion
    if (userRole == null) return '/login';

    // Rediriger vers la page appropriée selon le rôle
    switch (userRole) {
      case 1: // Admin
        return '/admin'; // Admin va vers le dashboard admin
      case 2: // Commercial
        return '/commercial';
      case 3: // Comptable
        return '/comptable';
      case 4: // RH
        return '/rh';
      case 5: // Technicien
        return '/technicien';
      case 6: // Patron
        return '/patron';
      default:
        return '/login';
    }
  }
}
