import 'package:get/get.dart';
import 'package:easyconnect/Controllers/user_management_controller.dart';

class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION USER MANAGEMENT BINDING ===');

    // Contrôleur de gestion des utilisateurs
    Get.put(UserManagementController(), permanent: true);

    print('User management binding initialisé avec succès');
  }
}
