import 'package:easyconnect/Controllers/attendance_controller.dart';
import 'package:easyconnect/Controllers/contract_controller.dart';
import 'package:easyconnect/Controllers/employee_controller.dart';
import 'package:easyconnect/Controllers/leave_controller.dart';
import 'package:easyconnect/Controllers/recruitment_controller.dart';
import 'package:easyconnect/Controllers/reporting_controller.dart';
import 'package:easyconnect/services/contract_service.dart';
import 'package:easyconnect/services/reporting_service.dart';
import 'package:easyconnect/services/task_service.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/rh_dashboard_controller.dart';
import 'package:easyconnect/services/rh_dashboard_service.dart';
import 'package:easyconnect/services/employee_service.dart';
import 'package:easyconnect/services/leave_service.dart';
import 'package:easyconnect/services/attendance_punch_service.dart';
import 'package:easyconnect/services/recruitment_service.dart';

class RhBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<RhDashboardController>()) {
      print('=== INITIALISATION RH BINDING ===');
    }

    if (!Get.isRegistered<RhDashboardService>()) {
      Get.put(RhDashboardService(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeService>()) {
      Get.put(EmployeeService(), permanent: true);
    }
    if (!Get.isRegistered<LeaveService>()) {
      Get.put(LeaveService(), permanent: true);
    }
    if (!Get.isRegistered<AttendancePunchService>()) {
      Get.put(AttendancePunchService(), permanent: true);
    }
    if (!Get.isRegistered<RecruitmentService>()) {
      Get.put(RecruitmentService(), permanent: true);
    }
    if (!Get.isRegistered<ContractService>()) {
      Get.put(ContractService(), permanent: true);
    }
    if (!Get.isRegistered<ReportingService>()) {
      Get.put(ReportingService(), permanent: true);
    }
    if (!Get.isRegistered<TaskService>()) {
      Get.put(TaskService(), permanent: true);
    }

    if (!Get.isRegistered<RhDashboardController>()) {
      Get.put(RhDashboardController(), permanent: true);
    }
    if (!Get.isRegistered<EmployeeController>()) {
      Get.put(EmployeeController(), permanent: true);
    }
    if (!Get.isRegistered<LeaveController>()) {
      Get.put(LeaveController(), permanent: true);
    }
    if (!Get.isRegistered<AttendanceController>()) {
      Get.put(AttendanceController(), permanent: true);
    }
    if (!Get.isRegistered<RecruitmentController>()) {
      Get.put(RecruitmentController(), permanent: true);
    }
    if (!Get.isRegistered<ContractController>()) {
      Get.put(ContractController(), permanent: true);
    }
    if (!Get.isRegistered<ReportingController>()) {
      Get.put(ReportingController(), permanent: true);
    }
  }
}
