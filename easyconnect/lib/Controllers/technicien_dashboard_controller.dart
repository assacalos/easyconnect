import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/roles.dart';

class TechnicienDashboardController extends BaseDashboardController {
  // Données des graphiques
  final ticketsData = <ChartData>[].obs;
  final categoriesData = <ChartData>[].obs;
  final resolutionData = <ChartData>[].obs;
  final equipmentData = <ChartData>[].obs;

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
      ticketsData.value = [
        ChartData(1, 12, "Lundi"),
        ChartData(2, 15, "Mardi"),
        ChartData(3, 10, "Mercredi"),
        ChartData(4, 8, "Jeudi"),
        ChartData(5, 14, "Vendredi"),
      ];

      categoriesData.value = [
        ChartData(1, 35, "Matériel"),
        ChartData(2, 25, "Logiciel"),
        ChartData(3, 20, "Réseau"),
        ChartData(4, 20, "Autres"),
      ];

      resolutionData.value = [
        ChartData(1, 4, "Urgent"),
        ChartData(2, 8, "Élevé"),
        ChartData(3, 12, "Normal"),
        ChartData(4, 24, "Faible"),
      ];

      equipmentData.value = [
        ChartData(1, 45, "Opérationnel"),
        ChartData(2, 15, "En maintenance"),
        ChartData(3, 8, "En panne"),
        ChartData(4, 2, "Obsolète"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('tickets', ticketsData);
      updateChartData('categories', categoriesData);
      updateChartData('resolution', resolutionData);
      updateChartData('equipment', equipmentData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Actions spécifiques technicien
  void createNewTicket() {
    Get.toNamed('/technicien/tickets/new');
  }

  void showTickets() {
    Get.toNamed('/technicien/tickets');
  }

  void showMaintenance() {
    Get.toNamed('/technicien/maintenance');
  }

  void showEquipment() {
    Get.toNamed('/technicien/equipment');
  }

  void showInventory() {
    Get.toNamed('/technicien/inventory');
  }

  void showReports() {
    Get.toNamed('/technicien/reports');
  }

  void scheduleMaintenance() {
    Get.toNamed('/technicien/maintenance/schedule');
  }

  void checkInventory() {
    Get.toNamed('/technicien/inventory/check');
  }

  void manageEquipment() {
    Get.toNamed('/technicien/equipment');
  }
}
