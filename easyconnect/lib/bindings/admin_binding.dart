import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION ADMIN BINDING ===');

    // S'assurer que l'AuthController est disponible
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }

    print('Admin binding initialisé avec succès');
  }
}
