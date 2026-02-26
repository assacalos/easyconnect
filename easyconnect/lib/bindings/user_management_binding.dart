import 'package:get/get.dart';
import 'package:easyconnect/Controllers/user_management_controller.dart';

class UserManagementBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<UserManagementController>()) {
      print('=== INITIALISATION USER MANAGEMENT BINDING ===');
      Get.put(UserManagementController(), permanent: true);
      print('User management binding initialisé avec succès');
    }
  }
}
