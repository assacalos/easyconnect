import 'package:get/get.dart';
import 'package:easyconnect/Models/notification_model.dart';

class NotificationService extends GetxService {
  static NotificationService get to => Get.find();

  final notifications = <AppNotification>[].obs;
  final unreadCount = 0.obs;

  void startNotificationListener() {
    // Initialiser l'écoute des notifications
    // Cette méthode sera appelée au démarrage de l'app
  }

  void addNotification(AppNotification notification) {
    notifications.insert(0, notification);
    _showNotificationSnackbar(notification);
    _updateUnreadCount();
  }

  void markAsRead(String notificationId) {
    final index = notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      notifications[index] = notifications[index].copyWith(isRead: true);
      _updateUnreadCount();
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  void _showNotificationSnackbar(AppNotification notification) {
    Get.snackbar(
      notification.title,
      notification.message,
      duration: const Duration(seconds: 4),
      isDismissible: true,
    );
  }
}
