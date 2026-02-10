import 'dart:async';
import 'dart:convert';
import 'package:pusher_client/pusher_client.dart';
import 'package:laravel_echo/laravel_echo.dart';
import 'package:get/get.dart';
import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/utils/app_config.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance {
    _instance ??= WebSocketService._internal();
    return _instance!;
  }

  WebSocketService._internal();

  Echo? echo;
  PusherClient? pusher;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 5;

  bool get isConnected => _isConnected;

  Future<void> initialize() async {
    if (_isConnected) return;

    try {
      final token = await SessionService.getToken();
      final userId = SessionService.getUserId();

      if (token == null || userId == null) return;

      AppLogger.info('🔌 Connexion Pusher pour user $userId', tag: 'WEBSOCKET');

      // --- CONFIGURATION CORRIGÉE POUR PUSHER CHANNELS ---
      PusherOptions options = PusherOptions(
        cluster:
            'eu', // Assure-toi que c'est 'eu' ou 'mt1' comme sur ton dashboard Pusher
        encrypted: true,
        auth: PusherAuth(
          '${AppConfig.baseUrl}/api/broadcasting/auth',
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      pusher = PusherClient(
        AppConfig.websocketKey, // Ta PUSHER_APP_KEY du .env
        options,
        enableLogging: true,
      );

      echo = Echo(broadcaster: EchoBroadcasterType.Pusher, client: pusher);

      _setupConnectionListeners();
      await pusher!.connect();
    } catch (e) {
      AppLogger.error('❌ Erreur WebSocket: $e', tag: 'WEBSOCKET');
      _scheduleReconnect();
    }
  }

  void _setupConnectionListeners() {
    if (pusher == null) return;

    pusher!.onConnectionStateChange((state) {
      AppLogger.info('État: ${state?.currentState}', tag: 'WEBSOCKET');
      if (state?.currentState == 'connected') {
        _isConnected = true;
        _reconnectAttempts = 0;
        _cancelReconnectTimer();
        _subscribeToChannels();
      } else if (state?.currentState == 'disconnected') {
        _isConnected = false;
        _scheduleReconnect();
      }
    });

    pusher!.onConnectionError((error) {
      AppLogger.error('❌ Erreur: ${error?.message}', tag: 'WEBSOCKET');
      _isConnected = false;
      _scheduleReconnect();
    });
  }

  void _subscribeToChannels() {
    final userId = SessionService.getUserId();
    if (userId == null || echo == null) return;

    // --- AJOUT DES POINTS (.) DEVANT LES ÉVÉNEMENTS ---

    // Canal Privé Utilisateur
    echo!.private('user.$userId').listen('.NotificationReceived', (e) {
      AppLogger.info('📬 Notification Perso reçue: $e', tag: 'WEBSOCKET');
      _handleNotificationReceived(e);
    });

    // Canaux de Rôles (Exemple Patron)
    final userRole = SessionService.getUserRole();
    if (userRole == 3) {
      // PATRON
      echo!.private('patron-approvals').listen('.NotificationReceived', (e) {
        AppLogger.info('📬 Notification Patron reçue', tag: 'WEBSOCKET');
        _handleNotificationReceived(e);
      });
    }

    // Ajoute les autres rôles (RH, Tech) ici avec le même format '.NotificationReceived'
  }

  void _handleNotificationReceived(dynamic data) {
    try {
      AppLogger.info(
        '📬 Notification reçue via Pusher (app ouverte): $data',
        tag: 'WEBSOCKET',
      );

      // Extraire les données au format FCM v1 (compatible avec le nouveau NotificationService Laravel)
      Map<String, dynamic> rawData = {};

      if (data is Map) {
        // Format direct depuis Laravel
        rawData = Map<String, dynamic>.from(data);
      } else if (data is String) {
        // Format JSON string
        try {
          rawData = Map<String, dynamic>.from(jsonDecode(data) as Map);
        } catch (e) {
          AppLogger.error('Erreur parsing JSON Pusher: $e', tag: 'WEBSOCKET');
          return;
        }
      } else {
        AppLogger.warning(
          'Format de données Pusher non reconnu: ${data.runtimeType}',
          tag: 'WEBSOCKET',
        );
        return;
      }

      // Utiliser la même méthode d'extraction que PushNotificationService
      // pour garantir la cohérence du format FCM v1
      final pushService = PushNotificationService();
      final notificationData = pushService.extractNotificationData(rawData);

      AppLogger.info(
        'Données Pusher normalisées (FCM v1) - Type: ${notificationData['type']}, EntityId: ${notificationData['entity_id']}, ActionRoute: ${notificationData['action_route']}',
        tag: 'WEBSOCKET',
      );

      // Mettre à jour le controller de notifications pour rafraîchir la liste
      // Quand l'app est ouverte, Pusher est plus rapide que FCM
      // On rafraîchit immédiatement la liste des notifications
      if (Get.isRegistered<NotificationController>()) {
        Get.find<NotificationController>().loadNotifications(
          forceRefresh: true,
        );
        AppLogger.info(
          '✅ UI Rafraîchie via Pusher (app ouverte)',
          tag: 'WEBSOCKET',
        );
      }

      // Note: Quand l'app est ouverte, on ne déclenche pas de notification locale
      // car l'utilisateur est déjà sur l'app. Le rafraîchissement de la liste suffit.
      // La navigation se fait uniquement quand l'utilisateur clique sur une notification.
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors du traitement de la notification Pusher: $e',
        tag: 'WEBSOCKET',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // ... (Garder le reste des méthodes reconnect, disconnect, etc. elles sont correctes)

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _cancelReconnectTimer();
    final delay = Duration(seconds: 2 * (_reconnectAttempts + 1));
    _reconnectAttempts++;
    _reconnectTimer = Timer(delay, () => initialize());
  }

  void _cancelReconnectTimer() => _reconnectTimer?.cancel();

  void disconnect() {
    _cancelReconnectTimer();
    pusher?.disconnect();
    echo = null;
    _isConnected = false;
  }
}
