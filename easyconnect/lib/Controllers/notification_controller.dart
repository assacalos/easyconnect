import 'dart:async';
import 'package:get/get.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/services/notification_api_service.dart';
import 'package:easyconnect/utils/logger.dart';

/// Contrôleur pour gérer les notifications avec polling
class NotificationController extends GetxController {
  final NotificationApiService _apiService = NotificationApiService();

  // Liste des notifications
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  // Compteur de notifications non lues
  final RxInt unreadCount = 0.obs;

  // État de chargement
  final RxBool isLoading = false.obs;

  // Filtres
  final RxBool unreadOnly = false.obs;
  final Rx<String?> selectedType = Rx<String?>(null);
  final Rx<String?> selectedEntityType = Rx<String?>(null);

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt totalPages = 1.obs;
  final RxInt totalItems = 0.obs;
  final RxBool hasNextPage = false.obs;
  final RxBool hasPreviousPage = false.obs;
  final RxInt perPage = 20.obs;

  // Timer pour le polling
  Timer? _pollingTimer;
  bool _isPolling = false;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
    startPolling();
  }

  @override
  void onClose() {
    stopPolling();
    super.onClose();
  }

  /// Charger les notifications
  Future<void> loadNotifications({
    bool forceRefresh = false,
    int page = 1,
  }) async {
    try {
      if (!forceRefresh && isLoading.value) return;

      isLoading.value = true;
      currentPage.value = page;

      final loadedNotifications = await _apiService.getNotifications(
        unreadOnly: unreadOnly.value,
        type: selectedType.value,
        entityType: selectedEntityType.value,
        page: page,
        perPage: perPage.value,
      );

      if (page == 1) {
        notifications.value = loadedNotifications;
      } else {
        notifications.addAll(loadedNotifications);
      }

      // Mettre à jour le compteur de non lues
      await refreshUnreadCount();

      isLoading.value = false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du chargement des notifications: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
      isLoading.value = false;
    }
  }

  /// Actualiser le compteur de notifications non lues
  Future<void> refreshUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      unreadCount.value = count;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération du compteur: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

  /// Marquer une notification comme lue
  Future<void> markAsRead(String notificationId) async {
    try {
      final success = await _apiService.markAsRead(notificationId);
      if (success) {
        final index = notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          notifications[index] = notifications[index].copyWith(isRead: true);
          await refreshUnreadCount();
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage comme lue: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        for (var i = 0; i < notifications.length; i++) {
          if (!notifications[i].isRead) {
            notifications[i] = notifications[i].copyWith(isRead: true);
          }
        }
        unreadCount.value = 0;
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de toutes comme lues: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

  /// Supprimer une notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final success = await _apiService.deleteNotification(notificationId);
      if (success) {
        notifications.removeWhere((n) => n.id == notificationId);
        await refreshUnreadCount();
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la suppression: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

  /// Démarrer le polling
  void startPolling({Duration interval = const Duration(seconds: 30)}) {
    if (_isPolling) return;

    _isPolling = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      loadNotifications(forceRefresh: true);
    });

    AppLogger.info(
      'Polling des notifications démarré (intervalle: ${interval.inSeconds}s)',
      tag: 'NOTIFICATION_CONTROLLER',
    );
  }

  /// Arrêter le polling
  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    AppLogger.info(
      'Polling des notifications arrêté',
      tag: 'NOTIFICATION_CONTROLLER',
    );
  }

  /// Filtrer par type
  void filterByType(String? type) {
    selectedType.value = type?.isEmpty == true ? null : type;
    loadNotifications(forceRefresh: true, page: 1);
  }

  /// Filtrer par type d'entité
  void filterByEntityType(String? entityType) {
    selectedEntityType.value = entityType?.isEmpty == true ? null : entityType;
    loadNotifications(forceRefresh: true, page: 1);
  }

  /// Toggle filtre non lues seulement
  void toggleUnreadOnly() {
    unreadOnly.value = !unreadOnly.value;
    loadNotifications(forceRefresh: true, page: 1);
  }

  /// Charger la page suivante
  Future<void> loadNextPage() async {
    if (hasNextPage.value && !isLoading.value) {
      await loadNotifications(page: currentPage.value + 1);
    }
  }

  /// Gérer le tap sur une notification
  void handleNotificationTap(AppNotification notification) {
    // Marquer comme lue
    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    // Naviguer vers l'entité
    _navigateToEntity(notification);
  }

  /// Naviguer vers l'entité concernée
  void _navigateToEntity(AppNotification notification) {
    try {
      final entityId = notification.entityId;
      final entityType = notification.entityType;

      // Mapping des routes selon le guide
      String? route;
      switch (entityType) {
        case 'expense':
          route = '/expenses/$entityId';
          break;
        case 'leave_request':
          route = '/leave-requests/$entityId';
          break;
        case 'attendance':
          route = '/attendances/$entityId';
          break;
        case 'contract':
          route = '/contracts/$entityId';
          break;
        case 'payment':
          route = '/payments/$entityId';
          break;
        case 'client':
          route = '/clients/$entityId';
          break;
        case 'devis':
          route = '/devis/$entityId';
          break;
        case 'bordereau':
          route = '/bordereaux/$entityId';
          break;
        case 'bon_commande':
          route = '/bons-de-commande/$entityId';
          break;
        case 'invoice':
          route = '/invoices/$entityId';
          break;
        case 'salary':
          route = '/salaries/$entityId';
          break;
        case 'tax':
          route = '/taxes/$entityId';
          break;
        case 'supplier':
          route = '/fournisseurs/$entityId';
          break;
        case 'intervention':
          route = '/interventions/$entityId';
          break;
        case 'recruitment':
          route = '/recruitment-requests/$entityId';
          break;
        case 'stock':
          route = '/stocks/$entityId';
          break;
        case 'reporting':
          route = '/user-reportings/$entityId';
          break;
        default:
          Get.snackbar(
            'Information',
            'Type d\'entité non reconnu: $entityType',
            snackPosition: SnackPosition.BOTTOM,
          );
          return;
      }

      Get.toNamed(route);
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la navigation: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
      Get.snackbar(
        'Erreur',
        'Impossible de naviguer vers l\'entité',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
