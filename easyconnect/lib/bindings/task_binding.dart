import 'package:get/get.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/services/task_service.dart';

class TaskBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<AuthController>()) {
      Get.put(AuthController(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }
  }
}
