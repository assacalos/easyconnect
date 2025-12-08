import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/Models/notification_model.dart';

/// Page de liste des notifications
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NotificationController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          // Filtre non lues seulement
          IconButton(
            icon: Icon(
              controller.unreadOnly.value
                  ? Icons.filter_list
                  : Icons.filter_list_off,
            ),
            tooltip: 'Filtrer les non lues',
            onPressed: () => controller.toggleUnreadOnly(),
          ),
          // Marquer toutes comme lues
          if (controller.unreadCount.value > 0)
            TextButton(
              onPressed: () async {
                await controller.markAllAsRead();
                Get.snackbar(
                  'Succès',
                  'Toutes les notifications ont été marquées comme lues',
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              },
              child: const Text(
                'Tout marquer comme lu',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.notifications.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  controller.unreadOnly.value
                      ? 'Aucune notification non lue'
                      : 'Aucune notification',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadNotifications(forceRefresh: true),
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: controller.notifications.length,
            itemBuilder: (context, index) {
              final notification = controller.notifications[index];
              return NotificationItemWidget(notification: notification);
            },
          ),
        );
      }),
    );
  }
}

/// Widget pour afficher un élément de notification
class NotificationItemWidget extends StatelessWidget {
  final AppNotification notification;

  const NotificationItemWidget({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();
    final color = _getColorFromHex(notification.colorHex);
    final icon = _getIconFromName(notification.iconName);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: notification.isRead ? 1 : 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight:
                notification.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(notification.message),
            if (notification.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.red.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: ${notification.rejectionReason}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(notification.createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing:
            notification.isRead
                ? null
                : const Icon(Icons.circle, color: Colors.blue, size: 8),
        onTap: () => controller.handleNotificationTap(notification),
        onLongPress: () => _showDeleteDialog(context, controller),
      ),
    );
  }

  Color _getColorFromHex(String hex) {
    return Color(int.parse(hex.replaceAll('#', '0xFF')));
  }

  IconData _getIconFromName(String name) {
    switch (name) {
      case 'check_circle':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      case 'warning':
        return Icons.warning;
      case 'task':
        return Icons.task;
      default:
        return Icons.info;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Il y a ${difference.inMinutes} min';
      }
      return 'Il y a ${difference.inHours} h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  void _showDeleteDialog(
    BuildContext context,
    NotificationController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Supprimer la notification'),
            content: const Text(
              'Êtes-vous sûr de vouloir supprimer cette notification ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () {
                  controller.deleteNotification(notification.id);
                  Get.back();
                },
                child: const Text(
                  'Supprimer',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

/// Widget badge pour afficher le compteur de notifications non lues
class NotificationBadge extends StatelessWidget {
  final Widget child;

  const NotificationBadge({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NotificationController>();

    return Obx(() {
      final count = controller.unreadCount.value;
      if (count == 0) return child;

      return Badge(label: Text('$count'), child: child);
    });
  }
}
