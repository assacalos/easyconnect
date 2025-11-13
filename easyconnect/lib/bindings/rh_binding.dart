import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Controllers/salary_controller.dart';
import 'package:easyconnect/services/contract_service.dart';
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
    Get.put(ContractService(), permanent: true);

    // Contrôleur RH
    Get.put(RhDashboardController(), permanent: true);
    Get.put(EmployeeController(), permanent: true);
    Get.put(LeaveController(), permanent: true);
    Get.put(AttendanceController(), permanent: true);
    Get.put(RecruitmentController(), permanent: true);
    Get.put(ContractController(), permanent: true);
  }
}
