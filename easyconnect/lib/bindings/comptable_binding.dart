import 'package:easyconnect/Controllers/stock_controller.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/stock_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/tax_service.dart';
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
    print('=== INITIALISATION COMPTABLE BINDING ===');

    // Services d'abord
    Get.put(InvoiceService(), permanent: true);
    Get.put(StockService(), permanent: true);
    Get.put(SupplierService(), permanent: true);
    Get.put(TaxService(), permanent: true);
    Get.put(PaymentService(), permanent: true);

    // Contrôleurs ensuite
    Get.put(ComptableDashboardController(), permanent: true);
    Get.put(SupplierController(), permanent: true);
    Get.put(StockController(), permanent: true);
    Get.put(TaxController(), permanent: true);
    Get.put(ExpenseController(), permanent: true);
    Get.put(SalaryController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    print('✅ PaymentController enregistré dans ComptableBinding');
  }
}
