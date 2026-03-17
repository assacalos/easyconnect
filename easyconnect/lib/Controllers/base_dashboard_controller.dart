import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/utils/logger.dart';

abstract class BaseDashboardController {
  final AuthController l = AuthController.to;
  final NotificationService notificationService = NotificationService.to;
  final _storage = GetStorage();

  bool isLoading = false;
  final List<Filter> activeFilters = [];
  int currentPage = 1;
  bool hasMoreData = true;
  final Map<String, List<ChartData>> chartData = {};

  BaseDashboardController() {
    _waitForTokenAndLoad();
  }

  Future<void> _waitForTokenAndLoad() async {
    for (int i = 0; i < 30; i++) {
      final token = _storage.read<String?>('token');
      final user = l.userAuth;

      if (token == null || user == null) {
        if (i > 0) {
          AppLogger.info('Utilisateur déconnecté, arrêt du chargement', tag: 'BASE_DASHBOARD');
          return;
        }
      }

      if (token != null && user != null) {
        AppLogger.info('Token disponible, chargement des données', tag: 'BASE_DASHBOARD');
        loadInitialData();
        return;
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final token = _storage.read<String?>('token');
    final user = l.userAuth;
    if (token == null || user == null) {
      AppLogger.info('Utilisateur déconnecté, arrêt du chargement', tag: 'BASE_DASHBOARD');
      return;
    }
    AppLogger.warning(
      'Token non disponible après 3 secondes, chargement des données quand même',
      tag: 'BASE_DASHBOARD',
    );
    loadInitialData();
  }

  void loadInitialData() {
    final token = _storage.read<String?>('token');
    final user = l.userAuth;
    if (token == null || user == null) {
      AppLogger.info('Utilisateur déconnecté, arrêt du chargement des données', tag: 'BASE_DASHBOARD');
      return;
    }
    loadCachedData();
    _loadDataWithRetry();
  }

  void loadCachedData() {}

  Future<void> _loadDataWithRetry({int maxRetries = 3}) async {
    int retryCount = 0;
    while (retryCount < maxRetries) {
      try {
        final token = _storage.read<String?>('token');
        final user = l.userAuth;
        if (token == null || user == null) {
          if (retryCount < maxRetries - 1) {
            await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
            retryCount++;
            continue;
          }
          return;
        }
        await loadData();
        return;
      } catch (e) {
        retryCount++;
        if (retryCount < maxRetries) {
          await Future.delayed(Duration(milliseconds: 500 * retryCount));
        } else {
          AppLogger.error(
            'Échec du chargement des données après $maxRetries tentatives: $e',
            tag: 'BASE_DASHBOARD',
            error: e,
          );
        }
      }
    }
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
    if (isLoading || !hasMoreData) return;
    isLoading = true;
    currentPage++;
    await loadData();
    isLoading = false;
  }

  void updateChartData(String chartId, List<ChartData> newData) {
    chartData[chartId] = newData;
  }
}
