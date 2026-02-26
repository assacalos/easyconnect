import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';

/// Icône de notifications avec badge (compteur non lues).
/// Utilisée dans la barre du dashboard, la bottom bar et la page Profil (Patron).
/// Une seule implémentation pour éviter duplication et divergence.
class NotificationBadgeIcon extends StatelessWidget {
  const NotificationBadgeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      final controller = Get.find<NotificationController>();
      return Obx(() {
        final count = controller.unreadCount.value;
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
    } catch (_) {
      return const Icon(Icons.notifications);
    }
  }
}
