import 'package:get/get.dart';
import 'package:easyconnect/Controllers/client_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/commercial_dashboard_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';

class CommercialBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION COMMERCIAL BINDING ===');

    // Contrôleurs commerciaux
    Get.put(ClientController(), permanent: true);
    Get.put(DevisController(), permanent: true);
    Get.put(BordereauxController(), permanent: true);
    Get.put(BonCommandeController(), permanent: true);
    Get.put(CommercialDashboardController(), permanent: true);
    Get.put(ReportingController(), permanent: true);
  }
}
