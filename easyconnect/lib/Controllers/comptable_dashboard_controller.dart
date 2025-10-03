import 'package:get/get.dart';
import 'package:easyconnect/Controllers/base_dashboard_controller.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/roles.dart';

class ComptableDashboardController extends BaseDashboardController {
  // Données des graphiques
  final revenueData = <ChartData>[].obs;
  final expensesData = <ChartData>[].obs;
  final cashflowData = <ChartData>[].obs;
  final invoicesData = <ChartData>[].obs;

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
      revenueData.value = [
        ChartData(1, 85000, "Janvier"),
        ChartData(2, 92000, "Février"),
        ChartData(3, 88000, "Mars"),
        ChartData(4, 95000, "Avril"),
        ChartData(5, 103000, "Mai"),
        ChartData(6, 110000, "Juin"),
      ];

      expensesData.value = [
        ChartData(1, 35, "Salaires"),
        ChartData(2, 25, "Loyer"),
        ChartData(3, 20, "Marketing"),
        ChartData(4, 20, "Autres"),
      ];

      cashflowData.value = [
        ChartData(1, 50000, "Janvier"),
        ChartData(2, 55000, "Février"),
        ChartData(3, 48000, "Mars"),
        ChartData(4, 52000, "Avril"),
        ChartData(5, 58000, "Mai"),
        ChartData(6, 62000, "Juin"),
      ];

      invoicesData.value = [
        ChartData(1, 45, "Payées"),
        ChartData(2, 15, "En attente"),
        ChartData(3, 8, "En retard"),
        ChartData(4, 2, "Litige"),
      ];

      // Mettre à jour les données des graphiques
      updateChartData('revenue', revenueData);
      updateChartData('expenses', expensesData);
      updateChartData('cashflow', cashflowData);
      updateChartData('invoices', invoicesData);
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Actions spécifiques au comptable
  void createNewInvoice() {
    Get.toNamed('/invoices/new');
  }

  void showInvoices() {
    Get.toNamed('/invoices');
  }

  void showExpenses() {
    Get.toNamed('/expenses');
  }

  void showBalance() {
    Get.toNamed('/payments');
  }

  void showReports() {
    Get.toNamed('/reporting');
  }

  void createNewExpense() {
    Get.toNamed('/expenses/new');
  }

  void startBankReconciliation() {
    Get.toNamed('/payments');
  }
}
