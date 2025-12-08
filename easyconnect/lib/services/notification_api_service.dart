import 'package:http/http.dart' as http;
import 'package:easyconnect/Models/notification_model.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/utils/app_config.dart';
import 'package:easyconnect/utils/auth_error_handler.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/utils/retry_helper.dart';

/// Service API pour récupérer les notifications depuis le backend
class NotificationApiService {
  static final NotificationApiService _instance =
      NotificationApiService._internal();
  factory NotificationApiService() => _instance;
  NotificationApiService._internal();

  /// Récupérer les notifications avec filtres
  Future<List<AppNotification>> getNotifications({
    bool unreadOnly = false,
    String? type,
    String? entityType,
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      final params = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      if (unreadOnly) params['unread_only'] = 'true';
      if (type != null) params['type'] = type;
      if (entityType != null) params['entity_type'] = entityType;

      final queryString = Uri(queryParameters: params).query;
      final url = '${AppConfig.baseUrl}/notifications?$queryString';

      AppLogger.httpRequest('GET', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        if (data['success'] == true) {
          final notificationsData = data['data'] as List<dynamic>;
          return notificationsData
              .map((json) => AppNotification.fromJson(json))
              .toList();
        }
      }

      return [];
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération des notifications: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return [];
    }
  }

  /// Marquer une notification comme lue
  Future<bool> markAsRead(String notificationId) async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/$notificationId/read';

      AppLogger.httpRequest('PUT', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.put(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de la notification comme lue: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }

  /// Marquer toutes les notifications comme lues
  Future<bool> markAllAsRead() async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/read-all';

      AppLogger.httpRequest('PUT', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.put(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors du marquage de toutes les notifications comme lues: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }

  /// Obtenir le nombre de notifications non lues
  Future<int> getUnreadCount() async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/unread';

      AppLogger.httpRequest('GET', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.get(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        if (data['success'] == true) {
          return data['count'] ?? 0;
        }
      }

      return 0;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la récupération du nombre de notifications non lues: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return 0;
    }
  }

  /// Supprimer une notification
  Future<bool> deleteNotification(String notificationId) async {
    try {
      final url = '${AppConfig.baseUrl}/notifications/$notificationId';

      AppLogger.httpRequest('DELETE', url, tag: 'NOTIFICATION_API_SERVICE');

      final response = await RetryHelper.retryNetwork(
        operation:
            () => http.delete(Uri.parse(url), headers: ApiService.headers()),
        maxRetries: AppConfig.defaultMaxRetries,
      );

      AppLogger.httpResponse(
        response.statusCode,
        url,
        tag: 'NOTIFICATION_API_SERVICE',
      );
      await AuthErrorHandler.handleHttpResponse(response);

      if (response.statusCode == 200) {
        final data = ApiService.parseResponse(response);
        return data['success'] == true;
      }

      return false;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la suppression de la notification: $e',
        tag: 'NOTIFICATION_API_SERVICE',
      );
      return false;
    }
  }
}
