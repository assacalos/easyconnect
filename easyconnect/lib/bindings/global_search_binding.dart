import 'package:get/get.dart';
import 'package:easyconnect/Controllers/global_search_controller.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/invoice_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/supplier_service.dart';
import 'package:easyconnect/services/stock_service.dart';

class GlobalSearchBinding extends Bindings {
  @override
  void dependencies() {
    // S'assurer que les services sont enregistrés
    if (!Get.isRegistered<ClientService>()) {
      Get.put<ClientService>(ClientService(), permanent: true);
    }
    if (!Get.isRegistered<InvoiceService>()) {
      Get.put<InvoiceService>(InvoiceService(), permanent: true);
    }
    if (!Get.isRegistered<PaymentService>()) {
      Get.put<PaymentService>(PaymentService(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeService>()) {
      Get.put<EmployeeService>(EmployeeService(), permanent: true);
    }
    if (!Get.isRegistered<SupplierService>()) {
      Get.put<SupplierService>(SupplierService(), permanent: true);
    }
    if (!Get.isRegistered<StockService>()) {
      Get.put<StockService>(StockService(), permanent: true);
    }

    // Enregistrer le contrôleur de recherche globale
    Get.lazyPut<GlobalSearchController>(
      () => GlobalSearchController(),
      fenix: true,
    );
  }
}
