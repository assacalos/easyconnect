import 'package:get/get.dart';
import 'package:easyconnect/Controllers/patron_dashboard_controller.dart';

class PatronBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION PATRON BINDING ===');
    
    // Contrôleur patron
    Get.put(PatronDashboardController(), permanent: true);
  }
}
