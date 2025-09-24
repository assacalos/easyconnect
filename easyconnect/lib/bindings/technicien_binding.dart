import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';

class TechnicienBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION TECHNICIEN BINDING ===');

    // Contrôleur technicien
    Get.put(TechnicienDashboardController(), permanent: true);
  }
}
