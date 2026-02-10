import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/equipment_controller.dart';
import 'package:easyconnect/Controllers/intervention_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/Controllers/task_controller.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/services/technicien_dashboard_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/task_service.dart';

class TechnicienBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION TECHNICIEN BINDING ===');

    // Services d'abord
    Get.put(TechnicienDashboardService(), permanent: true);
    Get.put(InterventionService(), permanent: true);
    Get.put(EquipmentService(), permanent: true);
    Get.put(ReportingService(), permanent: true);
    Get.put(TaskService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);

    // Contrôleur technicien
    Get.put(TechnicienDashboardController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(ReportingController(), permanent: true);
    Get.put(InterventionController(), permanent: true);
    Get.put(EquipmentController(), permanent: true);
    Get.put(TaskController(), permanent: true);
  }
}
