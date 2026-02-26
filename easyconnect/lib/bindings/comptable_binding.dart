import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
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
import 'package:easyconnect/services/task_service.dart';
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
    if (!Get.isRegistered<InvoiceService>()) {
      Get.put(InvoiceService(), permanent: true);
    }
    if (!Get.isRegistered<StockService>()) {
      Get.put(StockService(), permanent: true);
    }
    if (!Get.isRegistered<SupplierService>()) {
      Get.put(SupplierService(), permanent: true);
    }
    if (!Get.isRegistered<TaxService>()) {
      Get.put(TaxService(), permanent: true);
    }
    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService(), permanent: true);
    }
    if (!Get.isRegistered<ExpenseService>()) {
      Get.put(ExpenseService(), permanent: true);
    }
    if (!Get.isRegistered<SalaryService>()) {
      Get.put(SalaryService(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }
    if (!Get.isRegistered<ComptableDashboardService>()) {
      Get.put(ComptableDashboardService(), permanent: true);
    }
    if (!Get.isRegistered<AttendancePunchService>()) {
      Get.put(AttendancePunchService(), permanent: true);
    }
    if (!Get.isRegistered<ReportingService>()) {
      Get.put(ReportingService(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeService>()) {
      Get.put(EmployeeService(), permanent: true);
    }

    if (!Get.isRegistered<ComptableDashboardController>()) {
      Get.put(ComptableDashboardController(), permanent: true);
    }
    if (!Get.isRegistered<SupplierController>()) {
      Get.put(SupplierController(), permanent: true);
    }
    if (!Get.isRegistered<StockController>()) {
      Get.put(StockController(), permanent: true);
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
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController(), permanent: true);
    }
    if (!Get.isRegistered<InvoiceController>()) {
      Get.put(InvoiceController(), permanent: true);
    }
    if (!Get.isRegistered<ReportingController>()) {
      Get.put(ReportingController(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeController>()) {
      Get.put(EmployeeController(), permanent: true);
    }
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }
  }
}
