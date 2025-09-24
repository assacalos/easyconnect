import 'package:get/get.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';

class RhBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION RH BINDING ===');

    // Contrôleur RH
    Get.put(RhDashboardController(), permanent: true);
  }
}
