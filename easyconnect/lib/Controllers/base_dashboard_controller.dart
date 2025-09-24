import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:get/get.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';

abstract class BaseDashboardController extends GetxController {
  final AuthController l = Get.put(AuthController());
  final NotificationService notificationService =
      Get.find<NotificationService>();

  final isLoading = false.obs;
  final activeFilters = <Filter>[].obs;
  final currentPage = 1.obs;
  final hasMoreData = true.obs;

  // Données des graphiques
  final chartData = <String, RxList<ChartData>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadInitialData();
  }

  void loadInitialData() {
    loadData();
  }

  Future<void> loadData();

  void onFilterChanged(Filter filter) {
    if (activeFilters.contains(filter)) {
      activeFilters.remove(filter);
    } else {
      activeFilters.add(filter);
    }
    loadInitialData();
  }

  void resetFilters() {
    activeFilters.clear();
    loadInitialData();
  }

  Future<void> loadNextPage() async {
    if (isLoading.value || !hasMoreData.value) return;

    isLoading.value = true;
    currentPage.value++;
    await loadData();
    isLoading.value = false;
  }

  void updateChartData(String chartId, List<ChartData> newData) {
    if (!chartData.containsKey(chartId)) {
      chartData[chartId] = <ChartData>[].obs;
    }
    chartData[chartId]!.value = newData;
  }
}
