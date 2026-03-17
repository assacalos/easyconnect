import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/services/notification_api_service.dart';
import 'package:easyconnect/services/notification_navigation_service.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/utils/logger.dart';

/// Contrôleur pour gérer les notifications avec polling
class NotificationController {
  static final NotificationController _instance = NotificationController._();
  static NotificationController get to => _instance;
  factory NotificationController() => _instance;
  NotificationController._();

  final NotificationApiService _apiService = NotificationApiService();
  final NotificationServiceEnhanced _notificationService =
      NotificationServiceEnhanced();

  final List<AppNotification> notifications = [];
  int unreadCount = 0;
  bool isLoading = false;
  bool isLoadingMore = false;
  bool unreadOnly = false;
  String? selectedType;
  String? selectedEntityType;
  int currentPage = 1;
  int totalPages = 1;
  int totalItems = 0;
  bool hasNextPage = false;
  bool hasPreviousPage = false;
  int perPage = 20;
  final ScrollController scrollController = ScrollController();

  Timer? _pollingTimer;
  bool _isPolling = false;
  final Set<String> _seenNotificationIds = <String>{};
  bool _isFirstLoad = true;

  void init() {
    _notificationService.initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation du service de notifications: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    });
    loadNotifications();
    startPolling();
  }

  Future<void> _updateAppIconBadge() async {
    try {
      final supported = await FlutterAppBadger.isAppBadgeSupported();
      if (!supported) return;

      if (!SessionService.isAppInBackground()) {
        await FlutterAppBadger.removeBadge();
        return;
      }

      if (unreadCount <= 0) {
        await FlutterAppBadger.removeBadge();
      } else {
        final displayCount = unreadCount > 99 ? 99 : unreadCount;
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

  void dispose() {
    scrollController.dispose();
    stopPolling();
  }

  bool _isLoadingNotificationsInProgress = false;

  Future<void> loadNotifications({
    bool forceRefresh = false,
    int page = 1,
  }) async {
    if (_isLoadingNotificationsInProgress) return;
    _isLoadingNotificationsInProgress = true;

    if (page == 1) {
      isLoading = true;
      final cached = NotificationApiService.getCachedNotifications();
      if (cached.isNotEmpty && !forceRefresh) {
        notifications.clear();
        notifications.addAll(cached);
        isLoading = false;
        currentPage = 1;
      } else {
        notifications.clear();
      }
    } else {
      isLoadingMore = true;
    }
    currentPage = page;

    try {
      final loadedNotifications = await _apiService.getNotifications(
        unreadOnly: unreadOnly,
        type: selectedType,
        entityType: selectedEntityType,
        page: page,
        perPage: perPage,
      );

      if (page == 1) {
        if (!_isFirstLoad && forceRefresh) {
          _detectAndShowNewNotifications(loadedNotifications);
        }
        notifications.clear();
        notifications.addAll(loadedNotifications);
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
          notifications.clear();
          notifications.addAll(fallback);
        }
      }
    } finally {
      isLoading = false;
      isLoadingMore = false;
      _isLoadingNotificationsInProgress = false;
    }
  }

  void loadMore() {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      loadNextPage();
    }
  }

  Future<void> refreshUnreadCount() async {
    try {
      final count = await _apiService.getUnreadCount();
      unreadCount = count;
      await _updateAppIconBadge();
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération du compteur: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

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

  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllAsRead();
      if (success) {
        for (var i = 0; i < notifications.length; i++) {
          if (!notifications[i].isRead) {
            notifications[i] = notifications[i].copyWith(isRead: true);
          }
        }
        unreadCount = 0;
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de toutes comme lues: $e',
        tag: 'NOTIFICATION_CONTROLLER',
      );
    }
  }

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

  void stopPolling() {
    _isPolling = false;
    _pollingTimer?.cancel();
    _pollingTimer = null;

    AppLogger.info(
      'Polling des notifications arrêté',
      tag: 'NOTIFICATION_CONTROLLER',
    );
  }

  void filterByType(String? type) {
    selectedType = type?.isEmpty == true ? null : type;
    loadNotifications(forceRefresh: true, page: 1);
  }

  void filterByEntityType(String? entityType) {
    selectedEntityType = entityType?.isEmpty == true ? null : entityType;
    loadNotifications(forceRefresh: true, page: 1);
  }

  void toggleUnreadOnly() {
    unreadOnly = !unreadOnly;
    loadNotifications(forceRefresh: true, page: 1);
  }

  Future<void> loadNextPage() async {
    if (hasNextPage && !isLoading && !isLoadingMore) {
      await loadNotifications(page: currentPage + 1);
    }
  }

  void handleNotificationTap(AppNotification notification) {
    if (!notification.isRead) {
      markAsRead(notification.id);
    }
    NotificationNavigationService().handleNavigationFromNotification(notification);
  }

  void _detectAndShowNewNotifications(
    List<AppNotification> loadedNotifications,
  ) {
    try {
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

      for (final notification in newNotifications) {
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

        _notificationService
            .showNotification(
              notification,
              soundType: soundType,
              addToList: false,
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
