import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/roles.dart';

class RhDashboardController extends BaseDashboardController {
  // Données des graphiques
  final headcountData = <ChartData>[].obs;
  final departmentsData = <ChartData>[].obs;
  final attendanceData = <ChartData>[].obs;
  final leavesData = <ChartData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  @override
  Future<void> loadData() async {
    if (isLoading.value) return;
    isLoading.value = true;

    try {
      // Simuler le chargement des données
      await Future.delayed(const Duration(seconds: 1));

      // Données de test
      headcountData.value = [
        ChartData(1, 75, "Janvier"),
        ChartData(2, 78, "Février"),
        ChartData(3, 80, "Mars"),
        ChartData(4, 82, "Avril"),
        ChartData(5, 85, "Mai"),
        ChartData(6, 85, "Juin"),
      ];

      departmentsData.value = [
        ChartData(1, 25, "Commercial"),
        ChartData(2, 20, "Technique"),
        ChartData(3, 15, "Support"),
        ChartData(4, 25, "Autres"),
      ];

      attendanceData.value = [
        ChartData(1, 95, "Commercial"),
        ChartData(2, 92, "Technique"),
        ChartData(3, 94, "Support"),
        ChartData(4, 93, "Autres"),
      ];

      leavesData.value = [
        ChartData(1, 15, "Congés payés"),
        ChartData(2, 5, "Maladie"),
        ChartData(3, 3, "Formation"),
        ChartData(4, 2, "Autres"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('headcount', headcountData);
      updateChartData('departments', departmentsData);
      updateChartData('attendance', attendanceData);
      updateChartData('leaves', leavesData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Actions spécifiques RH
  void createNewEmployee() {
    Get.toNamed('/rh/employees/new');
  }

  void showEmployees() {
    Get.toNamed('/rh/employees');
  }

  void showLeaves() {
    Get.toNamed('/rh/leaves');
  }

  void showAttendance() {
    Get.toNamed('/rh/attendance');
  }

  void showTraining() {
    Get.toNamed('/rh/training');
  }

  void showRecruitment() {
    Get.toNamed('/rh/recruitment');
  }

  void showReports() {
    Get.toNamed('/rh/reports');
  }

  void createNewLeave() {
    Get.toNamed('/rh/leaves/new');
  }

  void startNewRecruitment() {
    Get.toNamed('/rh/recruitment/new');
  }
}