import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/services/patron_dashboard_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';

class PatronBinding extends Bindings {
  @override
  void dependencies() {
    // S'assurer que l'AuthController est disponible
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    // Services d'abord (instanciation immédiate, pas de chargement de données)
    Get.put(PatronDashboardService(), permanent: true);
    Get.put(EmployeeService(), permanent: true);
    Get.put(PaymentService(), permanent: true);
    Get.put(SalaryService(), permanent: true);
    Get.put(TaxService(), permanent: true);
    Get.put(ExpenseService(), permanent: true);
    Get.put(InvoiceService(), permanent: true);
    Get.put(SupplierService(), permanent: true);
    Get.put(StockService(), permanent: true);
    Get.put(InterventionService(), permanent: true);
    Get.put(ContractService(), permanent: true);
    Get.put(EquipmentService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);
    Get.put(ReportingService(), permanent: true);
    Get.put(ClientService(), permanent: true);
    Get.put(DevisService(), permanent: true);
    Get.put(BordereauService(), permanent: true);
    Get.put(BonCommandeService(), permanent: true);
    Get.put(BonDeCommandeFournisseurService(), permanent: true);
    Get.put(RecruitmentService(), permanent: true);
    Get.put(LeaveService(), permanent: true);

    // Contrôleur patron (chargera les données avec délai)
    Get.put(PatronDashboardController(), permanent: true);

    // Contrôleurs nécessaires pour les validations (chargement différé)
    // Ces contrôleurs ne chargent pas de données au démarrage, seulement quand nécessaire
    Get.put(DevisController(), permanent: true);
    Get.put(BordereauxController(), permanent: true);
    Get.put(BonCommandeController(), permanent: true);
    Get.put(BonDeCommandeFournisseurController(), permanent: true);
    Get.put(ClientController(), permanent: true);
    Get.put(TaxController(), permanent: true);
    Get.put(ExpenseController(), permanent: true);
    Get.put(SalaryController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    Get.put(ReportingController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(SupplierController(), permanent: true);
    Get.put(StockController(), permanent: true);
    Get.put(InterventionController(), permanent: true);
    Get.put(EmployeeController(), permanent: true);
    Get.put(ContractController(), permanent: true);
    Get.put(EquipmentController(), permanent: true);
    Get.put(RecruitmentController(), permanent: true);
    Get.put(LeaveController(), permanent: true);
  }
}
