import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/besoin_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/services/technicien_dashboard_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/besoin_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/task_service.dart';

class TechnicienBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<TechnicienDashboardController>()) {
      print('=== INITIALISATION TECHNICIEN BINDING ===');
    }

    if (!Get.isRegistered<TechnicienDashboardService>()) {
      Get.put(TechnicienDashboardService(), permanent: true);
    }
    if (!Get.isRegistered<InterventionService>()) {
      Get.put(InterventionService(), permanent: true);
    }
    if (!Get.isRegistered<BesoinService>()) {
      Get.put(BesoinService(), permanent: true);
    }
    if (!Get.isRegistered<EquipmentService>()) {
      Get.put(EquipmentService(), permanent: true);
    }
    if (!Get.isRegistered<ReportingService>()) {
      Get.put(ReportingService(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }
    if (!Get.isRegistered<AttendancePunchService>()) {
      Get.put(AttendancePunchService(), permanent: true);
    }

    if (!Get.isRegistered<TechnicienDashboardController>()) {
      Get.put(TechnicienDashboardController(), permanent: true);
    }
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController(), permanent: true);
    }
    if (!Get.isRegistered<ReportingController>()) {
      Get.put(ReportingController(), permanent: true);
    }
    if (!Get.isRegistered<InterventionController>()) {
      Get.put(InterventionController(), permanent: true);
    }
    if (!Get.isRegistered<BesoinController>()) {
      Get.put(BesoinController(), permanent: true);
    }
    if (!Get.isRegistered<EquipmentController>()) {
      Get.put(EquipmentController(), permanent: true);
    }
    if (!Get.isRegistered<TaskController>()) {
      Get.put(TaskController(), permanent: true);
    }
  }
}
