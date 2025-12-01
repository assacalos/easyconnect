import 'package:easyconnect/Views/Components/filter_bar.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:easyconnect/services/notification_service.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Views/Components/data_chart.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/cache_helper.dart';

abstract class BaseDashboardController extends GetxController {
  final AuthController l = Get.find<AuthController>();
  final NotificationService notificationService =
      Get.find<NotificationService>();
  final _storage = GetStorage();

  final isLoading = false.obs;
  final activeFilters = <Filter>[].obs;
  final currentPage = 1.obs;
  final hasMoreData = true.obs;

  // Données des graphiques
  final chartData = <String, RxList<ChartData>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // Attendre que le token soit disponible avant de charger les données
    _waitForTokenAndLoad();
  }

  Future<void> _waitForTokenAndLoad() async {
    // Attendre jusqu'à 3 secondes que le token soit disponible
    for (int i = 0; i < 30; i++) {
      // Vérifier si l'utilisateur est toujours connecté
      final token = _storage.read<String?>('token');
      final user = l.userAuth.value;

      // Si l'utilisateur s'est déconnecté, arrêter le chargement
      if (token == null || user == null) {
        // Vérifier si c'est une déconnexion ou juste un chargement initial
        if (i > 0) {
          // Si on a attendu un peu, c'est probablement une déconnexion
          AppLogger.info(
            'Utilisateur déconnecté, arrêt du chargement',
            tag: 'BASE_DASHBOARD',
          );
          return;
        }
      }

      if (token != null && user != null) {
        AppLogger.info(
          'Token disponible, chargement des données',
          tag: 'BASE_DASHBOARD',
        );
        loadInitialData();
        return;
      }

      // Attendre 100ms avant de réessayer
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // Vérifier une dernière fois si l'utilisateur est toujours connecté
    final token = _storage.read<String?>('token');
    final user = l.userAuth.value;

    if (token == null || user == null) {
      AppLogger.info(
        'Utilisateur déconnecté, arrêt du chargement',
        tag: 'BASE_DASHBOARD',
      );
      return;
    }

    // Si le token n'est toujours pas disponible après 3 secondes, essayer quand même
    AppLogger.warning(
      'Token non disponible après 3 secondes, chargement des données quand même',
      tag: 'BASE_DASHBOARD',
    );
    loadInitialData();
  }

  void loadInitialData() {
    // Vérifier que l'utilisateur est toujours connecté avant de charger
    final token = _storage.read<String?>('token');
    final user = l.userAuth.value;

    if (token == null || user == null) {
      AppLogger.info(
        'Utilisateur déconnecté, arrêt du chargement des données',
        tag: 'BASE_DASHBOARD',
      );
      return;
    }

    // Afficher immédiatement les données du cache si disponibles
    loadCachedData();
    // Charger les données fraîches en arrière-plan
    _loadDataWithRetry();
  }

  /// Charge les données depuis le cache pour un affichage instantané
  /// Cette méthode peut être surchargée par les contrôleurs enfants
  void loadCachedData() {
    // Par défaut, ne rien faire - sera surchargée par les enfants
  }

  Future<void> _loadDataWithRetry({int maxRetries = 3}) async {
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        // Vérifier que le token est toujours disponible
        final token = _storage.read<String?>('token');
        final user = l.userAuth.value;

        if (token == null || user == null) {
          AppLogger.warning(
            'Token ou utilisateur non disponible, tentative ${retryCount + 1}/$maxRetries',
            tag: 'BASE_DASHBOARD',
          );

          if (retryCount < maxRetries - 1) {
            // Attendre avant de réessayer
            await Future.delayed(
              Duration(milliseconds: 500 * (retryCount + 1)),
            );
            retryCount++;
            continue;
          } else {
            AppLogger.error(
              'Impossible de charger les données: token ou utilisateur non disponible après $maxRetries tentatives',
              tag: 'BASE_DASHBOARD',
            );
            return;
          }
        }

        // Charger les données
        await loadData();
        return; // Succès, sortir de la boucle
      } catch (e) {
        retryCount++;
        AppLogger.warning(
          'Erreur lors du chargement (tentative $retryCount/$maxRetries): $e',
          tag: 'BASE_DASHBOARD',
        );

        if (retryCount < maxRetries) {
          // Attendre avant de réessayer (backoff exponentiel)
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
