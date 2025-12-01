import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/payment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/bon_de_commande_fournisseur_controller.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/services/commercial_dashboard_service.dart';
import 'package:easyconnect/services/client_service.dart';
import 'package:easyconnect/services/devis_service.dart';
import 'package:easyconnect/services/bordereau_service.dart';
import 'package:easyconnect/services/bon_commande_service.dart';
import 'package:easyconnect/services/bon_de_commande_fournisseur_service.dart';
import 'package:easyconnect/services/invoice_service.dart';

class CommercialBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION COMMERCIAL BINDING ===');

    // Services d'abord
    Get.put(CommercialDashboardService(), permanent: true);
    Get.put(ClientService(), permanent: true);
    Get.put(DevisService(), permanent: true);
    Get.put(BordereauService(), permanent: true);
    Get.put(BonCommandeService(), permanent: true);
    Get.put(BonDeCommandeFournisseurService(), permanent: true);
    Get.put(InvoiceService(), permanent: true);
    Get.put(PaymentService(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(ReportingService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);
    Get.put(InterventionService(), permanent: true);

    // Contrôleurs commerciaux
    Get.put(ClientController(), permanent: true);
    Get.put(DevisController(), permanent: true);
    Get.put(BordereauxController(), permanent: true);
    Get.put(BonCommandeController(), permanent: true);
    Get.put(BonDeCommandeFournisseurController(), permanent: true);
    Get.put(CommercialDashboardController(), permanent: true);
    Get.put(ReportingController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(InvoiceController(), permanent: true);
    Get.put(PaymentController(), permanent: true);
    Get.put(InterventionController(), permanent: true);
  }
}
