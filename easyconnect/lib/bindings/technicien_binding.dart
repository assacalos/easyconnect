import 'package:get/get.dart';
import 'package:easyconnect/Controllers/technicien_dashboard_controller.dart';
import 'package:easyconnect/services/technicien_dashboard_service.dart';
import 'package:easyconnect/services/intervention_service.dart';
import 'package:easyconnect/services/equipment_service.dart';
import 'package:easyconnect/services/reporting_service.dart';

class TechnicienBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION TECHNICIEN BINDING ===');

    // Services d'abord
    Get.put(TechnicienDashboardService(), permanent: true);
    Get.put(InterventionService(), permanent: true);
    Get.put(EquipmentService(), permanent: true);
    Get.put(ReportingService(), permanent: true);

    // Contrôleur technicien
    Get.put(TechnicienDashboardController(), permanent: true);
  }
}
