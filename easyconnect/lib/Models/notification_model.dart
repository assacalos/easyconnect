class AppNotification {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? actionRoute;
  final Map<String, dynamic>? actionData;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.type,
    this.actionRoute,
    this.actionData,
    this.isRead = false,
  });
}

enum NotificationType { info, success, warning, error, task }
