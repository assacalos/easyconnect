import 'package:easyconnect/Controllers/host_controller.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomBarItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool showBadge; // Indique si on doit afficher un badge (pour les notifications)

  BottomBarItem({
    required this.icon,
    required this.label,
    this.onTap,
    this.showBadge = false,
  });
}

class BottomBarWidget extends StatelessWidget {
  final List<BottomBarItem> items;
  final HostController hostController = Get.find();

  BottomBarWidget({required this.items, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => BottomNavigationBar(
        currentIndex: hostController.currentIndex.value,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blueGrey.shade800,
        unselectedItemColor: Colors.grey,
        items:
            items
                .map(
                  (item) {
                    // Si c'est l'item de notifications et qu'on doit afficher un badge
                    if (item.showBadge && item.icon == Icons.notifications) {
                      return BottomNavigationBarItem(
                        icon: _buildNotificationIconWithBadge(),
                        label: item.label,
                      );
                    }
                    
                    return BottomNavigationBarItem(
                      icon: Icon(item.icon),
                      label: item.label,
                    );
                  },
                )
                .toList(),
        onTap: (index) {
          hostController.currentIndex.value = index;
          if (items[index].onTap != null) {
            items[index].onTap!();
          }
        },
      ),
    );
  }

  /// Construire l'icône de notifications avec badge
  Widget _buildNotificationIconWithBadge() {
    try {
      final notificationController = Get.find<NotificationController>();
      return Obx(() {
        final count = notificationController.unreadCount.value;
        if (count > 0) {
          return Badge(
            label: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: const Icon(Icons.notifications),
          );
        }
        return const Icon(Icons.notifications);
      });
    } catch (e) {
      // Si le controller n'est pas disponible, retourner l'icône sans badge
      return const Icon(Icons.notifications);
    }
  }
}
