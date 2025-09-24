import 'package:get/get.dart';
import 'package:easyconnect/Controllers/comptable_dashboard_controller.dart';

class ComptableBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION COMPTABLE BINDING ===');
    
    // Contrôleur comptable
    Get.lazyPut(() => ComptableDashboardController());
  }
}
