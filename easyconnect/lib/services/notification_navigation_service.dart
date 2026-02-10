import 'package:get/get.dart';
import '../utils/logger.dart';

/// Service centralisé pour gérer la navigation depuis les notifications
/// Supporte le nouveau format FCM v1 avec type, entity_id, action_route
class NotificationNavigationService {
  static final NotificationNavigationService _instance =
      NotificationNavigationService._internal();
  factory NotificationNavigationService() => _instance;
  NotificationNavigationService._internal();

  /// Gère la navigation depuis une notification
  /// Accepte les données au format FCM v1 : {type, entity_id, action_route}
  void handleNavigation(Map<String, dynamic> data) {
    try {
      AppLogger.info(
        'Navigation depuis notification - Données reçues: $data',
        tag: 'NOTIFICATION_NAV',
      );

      // Support du nouveau format FCM v1 : 'type' (prioritaire)
      // et de l'ancien format : 'entity_type' (pour compatibilité)
      final type = data['type'] as String? ?? data['entity_type'] as String?;
      final entityId = data['entity_id']?.toString();
      final actionRoute = data['action_route'] as String?;

      AppLogger.info(
        'Type: $type, EntityId: $entityId, ActionRoute: $actionRoute',
        tag: 'NOTIFICATION_NAV',
      );

      // Si une route d'action est fournie, l'utiliser en priorité
      // Format attendu: '/devis/12' ou '/clients/5' ou '/devis/:id'
      if (actionRoute != null && actionRoute.isNotEmpty) {
        AppLogger.info(
          'Navigation vers action_route: $actionRoute',
          tag: 'NOTIFICATION_NAV',
        );
        
        // Si action_route contient déjà l'ID, l'utiliser directement
        // Sinon, utiliser entityId pour remplacer :id
        String finalRoute = actionRoute;
        if (finalRoute.contains(':id') && entityId != null) {
          finalRoute = finalRoute.replaceAll(':id', entityId);
        } else if (!finalRoute.contains('/') || 
                   (finalRoute.split('/').length == 2 && entityId != null)) {
          // Route incomplète, ajouter l'entityId
          finalRoute = '$finalRoute/$entityId';
        }
        
        _navigateToRoute(finalRoute, entityId);
        return;
      }

      // Sinon, utiliser le type d'entité pour déterminer la route
      if (type != null && entityId != null) {
        final route = _getRouteFromType(type, entityId);
        if (route != null) {
          AppLogger.info(
            'Navigation vers route calculée: $route',
            tag: 'NOTIFICATION_NAV',
          );
          _navigateToRoute(route, entityId);
        } else {
          _navigateToNotifications();
        }
      } else {
        // Si aucune information de navigation, aller vers la page des notifications
        _navigateToNotifications();
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la navigation depuis la notification: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
        stackTrace: stackTrace,
      );
      // En cas d'erreur, rediriger vers la page des notifications
      _navigateToNotifications();
    }
  }

  /// Convertit un type d'entité en route
  String? _getRouteFromType(String type, String entityId) {
    switch (type.toLowerCase()) {
      case 'expense':
        return '/expenses/$entityId';
      case 'leave_request':
      case 'leave':
      case 'conge':
        return '/leaves/$entityId';
      case 'attendance':
        return '/attendance-validation';
      case 'contract':
        return '/contracts/$entityId';
      case 'payment':
        return '/payments/detail';
      case 'client':
        return '/clients/$entityId';
      case 'devis':
        return '/devis/$entityId';
      case 'bordereau':
        return '/bordereaux/$entityId';
      case 'bon_commande':
        return '/bon-commandes/$entityId';
      case 'invoice':
        return '/invoices';
      case 'salary':
        return '/salaries/$entityId';
      case 'tax':
        return '/taxes/$entityId';
      case 'supplier':
        return '/suppliers/$entityId';
      case 'intervention':
        return '/interventions/$entityId';
      case 'recruitment':
        return '/recruitment/$entityId';
      case 'reporting':
        return '/reporting';
      case 'task':
        return '/tasks/$entityId';
      default:
        return null;
    }
  }

  /// Navigue vers une route avec des arguments optionnels
  /// Supporte les routes dynamiques avec paramètres (ex: /devis/:id)
  void _navigateToRoute(String route, String? entityId) {
    try {
      AppLogger.info(
        'Navigation vers route: $route (entityId: $entityId)',
        tag: 'NOTIFICATION_NAV',
      );

      // Nettoyer la route (enlever les espaces, etc.)
      route = route.trim();
      
      // Si la route contient :id ou :entityId, remplacer par l'entityId
      if (entityId != null && entityId.isNotEmpty) {
        route = route.replaceAll(':id', entityId);
        route = route.replaceAll(':entityId', entityId);
      }

      // Routes spéciales qui nécessitent des arguments
      if (route == '/payments/detail' && entityId != null) {
        Get.toNamed(route, arguments: entityId);
        return;
      }

      // Routes avec paramètres dynamiques (ex: /devis/12)
      // GetX gère automatiquement les paramètres dans l'URL
      if (route.contains('/') && !route.endsWith('/')) {
        // Vérifier si la route correspond à un pattern avec paramètres
        final parts = route.split('/');
        if (parts.length >= 3) {
          // Route comme /devis/12 ou /clients/5
          final lastPart = parts.last;
          // Si c'est un nombre, c'est probablement un ID
          if (int.tryParse(lastPart) != null) {
            Get.toNamed(route);
            return;
          }
        }
      }

      // Navigation standard
      Get.toNamed(route);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de la navigation vers $route: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
        stackTrace: stackTrace,
      );
      _navigateToNotifications();
    }
  }

  /// Navigue vers la page des notifications
  void _navigateToNotifications() {
    AppLogger.info(
      'Redirection vers /notifications',
      tag: 'NOTIFICATION_NAV',
    );
    try {
      Get.toNamed('/notifications');
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la navigation vers /notifications: $e',
        tag: 'NOTIFICATION_NAV',
        error: e,
      );
    }
  }
}

