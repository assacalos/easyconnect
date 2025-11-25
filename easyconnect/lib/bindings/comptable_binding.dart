import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/expense_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/salary_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/tax_service.dart';
import 'package:easyconnect/services/comptable_dashboard_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';
import 'package:easyconnect/Controllers/supplier_controller.dart';
import 'package:easyconnect/Controllers/tax_controller.dart';
import 'package:easyconnect/Controllers/expense_controller.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';

class ComptableBinding extends Bindings {
  @override
  void dependencies() {
    // Services d'abord
    Get.put(InvoiceService(), permanent: true);
    Get.put(StockService(), permanent: true);
    Get.put(SupplierService(), permanent: true);
    Get.put(TaxService(), permanent: true);
    Get.put(PaymentService(), permanent: true);
    Get.put(ExpenseService(), permanent: true);
    Get.put(SalaryService(), permanent: true);
    Get.put(ComptableDashboardService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);
    Get.put(ReportingService(), permanent: true);
    Get.put(EmployeeService(), permanent: true);

    // Contrôleurs ensuite
    Get.put(ComptableDashboardController(), permanent: true);
    Get.put(SupplierController(), permanent: true);
    Get.put(StockController(), permanent: true);
    Get.put(TaxController(), permanent: true);
    Get.put(ExpenseController(), permanent: true);
    Get.put(SalaryController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(ReportingController(), permanent: true);
    Get.put(EmployeeController(), permanent: true);
  }
}
