import 'package:get/get.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';
import 'package:easyconnect/services/rh_dashboard_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';
import 'package:easyconnect/services/salary_service.dart';

class RhBinding extends Bindings {
  @override
  void dependencies() {
    print('=== INITIALISATION RH BINDING ===');

    // Services d'abord
    Get.put(RhDashboardService(), permanent: true);
    Get.put(EmployeeService(), permanent: true);
    Get.put(LeaveService(), permanent: true);
    Get.put(AttendancePunchService(), permanent: true);
    Get.put(RecruitmentService(), permanent: true);
    Get.put(SalaryService(), permanent: true);

    // Contrôleur RH
    Get.put(RhDashboardController(), permanent: true);
  }
}
