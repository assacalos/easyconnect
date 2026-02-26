import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
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
import 'package:easyconnect/services/task_service.dart';

class PatronBinding extends Bindings {
  @override
  void dependencies() {
    // Idempotent : chaque dépendance n'est enregistrée que si pas déjà présente,
    // pour éviter ré-initialisation à chaque navigation (et doublons d'appels API).
    final alreadyInitialized = Get.isRegistered<PatronDashboardController>();
    if (!alreadyInitialized) {
      print('=== INITIALISATION PATRON BINDING ===');
    }

    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    if (!Get.isRegistered<PatronDashboardService>()) {
      Get.put(PatronDashboardService(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeService>()) {
      Get.put(EmployeeService(), permanent: true);
    }
    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService(), permanent: true);
    }
    if (!Get.isRegistered<SalaryService>()) {
      Get.put(SalaryService(), permanent: true);
    }
    if (!Get.isRegistered<TaxService>()) {
      Get.put(TaxService(), permanent: true);
    }
    if (!Get.isRegistered<ExpenseService>()) {
      Get.put(ExpenseService(), permanent: true);
    }
    if (!Get.isRegistered<InvoiceService>()) {
      Get.put(InvoiceService(), permanent: true);
    }
    if (!Get.isRegistered<SupplierService>()) {
      Get.put(SupplierService(), permanent: true);
    }
    if (!Get.isRegistered<StockService>()) {
      Get.put(StockService(), permanent: true);
    }
    if (!Get.isRegistered<InterventionService>()) {
      Get.put(InterventionService(), permanent: true);
    }
    if (!Get.isRegistered<ContractService>()) {
      Get.put(ContractService(), permanent: true);
    }
    if (!Get.isRegistered<EquipmentService>()) {
      Get.put(EquipmentService(), permanent: true);
    }
    if (!Get.isRegistered<AttendancePunchService>()) {
      Get.put(AttendancePunchService(), permanent: true);
    }
    if (!Get.isRegistered<ReportingService>()) {
      Get.put(ReportingService(), permanent: true);
    }
    if (!Get.isRegistered<ClientService>()) {
      Get.put(ClientService(), permanent: true);
    }
    if (!Get.isRegistered<DevisService>()) {
      Get.put(DevisService(), permanent: true);
    }
    if (!Get.isRegistered<BordereauService>()) {
      Get.put(BordereauService(), permanent: true);
    }
    if (!Get.isRegistered<BonCommandeService>()) {
      Get.put(BonCommandeService(), permanent: true);
    }
    if (!Get.isRegistered<BonDeCommandeFournisseurService>()) {
      Get.put(BonDeCommandeFournisseurService(), permanent: true);
    }
    if (!Get.isRegistered<RecruitmentService>()) {
      Get.put(RecruitmentService(), permanent: true);
    }
    if (!Get.isRegistered<LeaveService>()) {
      Get.put(LeaveService(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }

    if (!Get.isRegistered<PatronDashboardController>()) {
      Get.put(PatronDashboardController(), permanent: true);
    }

    if (!Get.isRegistered<NotificationController>()) {
      Get.put(NotificationController(), permanent: true);
      print('NotificationController initialisé dans PatronBinding');
    } else {
      print(
        'NotificationController déjà enregistré, réutilisation de l\'instance existante',
      );
    }

    if (!Get.isRegistered<DevisController>()) {
      Get.put(DevisController(), permanent: true);
    }
    if (!Get.isRegistered<BordereauxController>()) {
      Get.put(BordereauxController(), permanent: true);
    }
    if (!Get.isRegistered<BonCommandeController>()) {
      Get.put(BonCommandeController(), permanent: true);
    }
    if (!Get.isRegistered<BonDeCommandeFournisseurController>()) {
      Get.put(BonDeCommandeFournisseurController(), permanent: true);
    }
    if (!Get.isRegistered<ClientController>()) {
      Get.put(ClientController(), permanent: true);
    }
    if (!Get.isRegistered<TaxController>()) {
      Get.put(TaxController(), permanent: true);
    }
    if (!Get.isRegistered<ExpenseController>()) {
      Get.put(ExpenseController(), permanent: true);
    }
    if (!Get.isRegistered<SalaryController>()) {
      Get.put(SalaryController(), permanent: true);
    }
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController(), permanent: true);
    }
    if (!Get.isRegistered<ReportingController>()) {
      Get.put(ReportingController(), permanent: true);
    }
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController(), permanent: true);
    }
    if (!Get.isRegistered<InvoiceController>()) {
      Get.put(InvoiceController(), permanent: true);
    }
    if (!Get.isRegistered<SupplierController>()) {
      Get.put(SupplierController(), permanent: true);
    }
    if (!Get.isRegistered<StockController>()) {
      Get.put(StockController(), permanent: true);
    }
    if (!Get.isRegistered<InterventionController>()) {
      Get.put(InterventionController(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeController>()) {
      Get.put(EmployeeController(), permanent: true);
    }
    if (!Get.isRegistered<ContractController>()) {
      Get.put(ContractController(), permanent: true);
    }
    if (!Get.isRegistered<EquipmentController>()) {
      Get.put(EquipmentController(), permanent: true);
    }
    if (!Get.isRegistered<RecruitmentController>()) {
      Get.put(RecruitmentController(), permanent: true);
    }
    if (!Get.isRegistered<LeaveController>()) {
      Get.put(LeaveController(), permanent: true);
    }
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }
  }
}
