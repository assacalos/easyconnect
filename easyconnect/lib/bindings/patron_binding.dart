import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';
import 'package:easyconnect/Controllers/devis_controller.dart';
import 'package:easyconnect/Controllers/bordereau_controller.dart';
import 'package:easyconnect/Controllers/bon_commande_controller.dart';
import 'package:easyconnect/Controllers/client_controller.dart';

class PatronBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION PATRON BINDING ===');

    // Contrôleur patron
    Get.put(PatronDashboardController(), permanent: true);

    // Contrôleurs nécessaires pour les validations
    Get.put(DevisController(), permanent: true);
    Get.put(BordereauxController(), permanent: true);
    Get.put(BonCommandeController(), permanent: true);
    Get.put(ClientController(), permanent: true);
  }
}
