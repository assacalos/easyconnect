import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/invoice_controller.dart';
import 'package:easyconnect/Controllers/payment_controller.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
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
import 'package:easyconnect/services/task_service.dart';

class CommercialBinding extends Bindings {
  @override
  void dependencies() {
    // Idempotent : n'enregistrer que si pas déjà présent pour éviter
    // ré-initialisation à chaque navigation (doublons d'appels API).
    if (!Get.isRegistered<CommercialDashboardController>()) {
      print('=== INITIALISATION COMMERCIAL BINDING ===');
    }

    if (!Get.isRegistered<CommercialDashboardService>()) {
      Get.put(CommercialDashboardService(), permanent: true);
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
    if (!Get.isRegistered<InvoiceService>()) {
      Get.put(InvoiceService(), permanent: true);
    }
    if (!Get.isRegistered<PaymentService>()) {
      Get.put(PaymentService(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }
    if (!Get.isRegistered<ReportingService>()) {
      Get.put(ReportingService(), permanent: true);
    }
    if (!Get.isRegistered<AttendancePunchService>()) {
      Get.put(AttendancePunchService(), permanent: true);
    }
    if (!Get.isRegistered<InterventionService>()) {
      Get.put(InterventionService(), permanent: true);
    }

    if (!Get.isRegistered<ClientController>()) {
      Get.put(ClientController(), permanent: true);
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
    if (!Get.isRegistered<CommercialDashboardController>()) {
      Get.put(CommercialDashboardController(), permanent: true);
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
    if (!Get.isRegistered<PaymentController>()) {
      Get.put(PaymentController(), permanent: true);
    }
    if (!Get.isRegistered<InterventionController>()) {
      Get.put(InterventionController(), permanent: true);
    }
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }
  }
}
