import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/services/notification_api_service.dart';
import 'package:easyconnect/services/notification_navigation_service.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/logger.dart';

/// Contrôleur pour gérer les notifications avec polling
class NotificationController extends GetxController {
  final NotificationApiService _apiService = NotificationApiService();
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced();

  // Liste des notifications
  final RxList<AppNotification> notifications = <AppNotification>[].obs;

  // Compteur de notifications non lues
  final RxInt unreadCount = 0.obs;

  // État de chargement
  final RxBool isLoading = false.obs;
  final RxBool isLoadingMore = false.obs;

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
  final ScrollController scrollController = ScrollController();

  // Timer pour le polling
  Timer? _pollingTimer;
  bool _isPolling = false;

  // Set pour stocker les IDs des notifications déjà vues (pour détecter les nouvelles)
  final Set<String> _seenNotificationIds = <String>{};

  // Flag pour savoir si c'est le premier chargement
  bool _isFirstLoad = true;

  @override
  void onInit() {
    super.onInit();
    // Synchroniser le badge de l'icône de l'app avec le nombre de non lues
    ever(unreadCount, (_) => _updateAppIconBadge());
    // Initialiser le service de notifications locales
    _notificationService.initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation du service de notifications: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    });
    loadNotifications();
    startPolling();
  }

  /// Met à jour le badge sur l'icône de l'application (menu du téléphone).
  /// Affiche le nombre de non lues uniquement quand l'app est en arrière-plan ;
  /// dès qu'on rentre dans l'app, le badge est retiré.
  Future<void> _updateAppIconBadge() async {
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      if (!supported) return;

      // Dès qu'on est au premier plan : pas de badge sur l'icône
      if (!SessionService.isAppInBackground()) {
        await FlutterAppBadger.removeBadge();
        return;
      }

      final count = unreadCount.value;
      if (count <= 0) {
        await FlutterAppBadger.removeBadge();
      } else {
        final displayCount = count > 99 ? 99 : count;
        await FlutterAppBadger.updateBadgeCount(displayCount);
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la mise à jour du badge icône: $e',
        tag: 'NOTIFICATION_CONTROLLER',
        error: e,
      );
    }
  }

  @override
  void onClose() {
    scrollController.dispose();
    stopPolling();
    super.onClose();
  }

  bool _isLoadingNotificationsInProgress = false;

  /// Charge les notifications : Hive d'abord (affichage immédiat), puis API dans la même méthode.
  Future<void> loadNotifications({
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingNotificationsInProgress) return;
    _isLoadingNotificationsInProgress = true;

    if (page == 1) {
      isLoading.value = true;
      final cached = NotificationApiService.getCachedNotifications();
      if (cached.isNotEmpty && !forceRefresh) {
        notifications.assignAll(cached);
        isLoading.value = false;
        currentPage.value = 1;
      } else {
        notifications.value = [];
      }
    } else {
      isLoadingMore.value = true;
    }
    currentPage.value = page;

    try {
      final loadedNotifications = await _apiService.getNotifications(
        unreadOnly: unreadOnly.value,
        type: selectedType.value,
        entityType: selectedEntityType.value,
        page: page,
        perPage: perPage.value,
      );

      if (page == 1) {
        if (!_isFirstLoad && forceRefresh) {
          _detectAndShowNewNotifications(loadedNotifications);
        }
        notifications.assignAll(loadedNotifications);
        _seenNotificationIds.addAll(loadedNotifications.map((n) => n.id));
        _isFirstLoad = false;
      } else {
        notifications.addAll(loadedNotifications);
        _seenNotificationIds.addAll(loadedNotifications.map((n) => n.id));
      }

      await refreshUnreadCount();
    } catch (e) {
      AppLogger.error('Erreur chargement notifications: $e', tag: 'NOTIFICATION_CONTROLLER');
      if (notifications.isEmpty) {
        final fallback = NotificationApiService.getCachedNotifications();
        if (fallback.isNotEmpty) {
          notifications.assignAll(fallback);
        }
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
      _isLoadingNotificationsInProgress = false;
    }
  }

  /// Chargement de la page suivante au scroll.
  void loadMore() {
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      loadNextPage();
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
    if (hasNextPage.value && !isLoading.value && !isLoadingMore.value) {
      await loadNotifications(page: currentPage.value + 1);
    }
  }

  /// Gérer le tap sur une notification : marquer comme lue puis rediriger vers l'élément cible
  void handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    NotificationNavigationService().handleNavigationFromNotification(notification);
  }

  /// Détecter les nouvelles notifications et déclencher des notifications locales
  void _detectAndShowNewNotifications(
    List<AppNotification> loadedNotifications,
  ) {
    try {
      // Trouver les notifications qui sont nouvelles (pas encore vues)
      final newNotifications =
          loadedNotifications.where((notification) {
            final isNew = !_seenNotificationIds.contains(notification.id);
            final isUnread = !notification.isRead;

            AppLogger.debug(
              'Vérification notification ID=${notification.id}: isNew=$isNew, isUnread=$isUnread',
              tag: 'NOTIFICATION_CONTROLLER',
            );

            return isNew && isUnread;
          }).toList();

      AppLogger.info(
        'Nouvelles notifications détectées: ${newNotifications.length}',
        tag: 'NOTIFICATION_CONTROLLER',
      );

      // Pour chaque nouvelle notification, déclencher une notification locale
      for (final notification in newNotifications) {
        // Déterminer le type de son selon le type de notification
        String soundType = 'info';
        if (notification.type == 'success') {
          soundType = 'success';
        } else if (notification.type == 'error') {
          soundType = 'error';
        } else if (notification.type == 'warning') {
          soundType = 'error';
        } else if (notification.type == 'task') {
          soundType = 'submit';
        }

        AppLogger.info(
          'Affichage notification locale: ID=${notification.id}, Title=${notification.title}, SoundType=$soundType',
          tag: 'NOTIFICATION_CONTROLLER',
        );

        // Afficher la notification locale avec son (sans ajouter à la liste car déjà gérée par le controller)
        _notificationService
            .showNotification(
              notification,
              soundType: soundType,
              addToList:
                  false, // Ne pas ajouter à la liste car le controller gère déjà sa propre liste
            )
            .then((_) {
              AppLogger.info(
                'Notification locale affichée avec succès: ID=${notification.id}',
                tag: 'NOTIFICATION_CONTROLLER',
              );
            })
            .catchError((e, stackTrace) {
              AppLogger.error(
                'Erreur lors de l\'affichage de la notification locale: $e\nStack: $stackTrace',
                tag: 'NOTIFICATION_CONTROLLER',
              );
            });
      }

      if (newNotifications.isNotEmpty) {
        AppLogger.info(
          '${newNotifications.length} nouvelle(s) notification(s) détectée(s) et affichée(s)',
          tag: 'NOTIFICATION_CONTROLLER',
        );
      } else {
        AppLogger.debug(
          'Aucune nouvelle notification à afficher',
          tag: 'NOTIFICATION_CONTROLLER',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la détection des nouvelles notifications: $e\nStack: $stackTrace',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }
}
