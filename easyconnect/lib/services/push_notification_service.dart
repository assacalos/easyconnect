import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../utils/app_config.dart';
import '../services/session_service.dart';
import '../utils/logger.dart';

/// Service de gestion des notifications push Firebase Cloud Messaging
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  // Callback pour gérer les notifications reçues
  Function(Map<String, dynamic>)? onNotificationReceived;

  // Callback pour gérer les clics sur les notifications
  Function(Map<String, dynamic>)? onNotificationTapped;

  bool _isInitialized = false;

  /// Initialiser le service de notifications push
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info(
        'Service de notifications push déjà initialisé',
        tag: 'PUSH_NOTIFICATION',
      );
      return;
    }

    try {
      // Demander la permission pour les notifications
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
            provisional: false,
          );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        AppLogger.info(
          'L\'utilisateur a accordé la permission',
          tag: 'PUSH_NOTIFICATION',
        );
      } else if (settings.authorizationStatus ==
          AuthorizationStatus.provisional) {
        AppLogger.info(
          'L\'utilisateur a accordé une permission provisoire',
          tag: 'PUSH_NOTIFICATION',
        );
      } else {
        AppLogger.warning(
          'L\'utilisateur a refusé ou n\'a pas encore accordé la permission',
          tag: 'PUSH_NOTIFICATION',
        );
        _isInitialized = true;
        return;
      }

      // Initialiser les notifications locales
      await _initializeLocalNotifications();

      // Obtenir le token FCM
      await _getFCMToken();

      // Configurer les handlers pour les notifications
      _setupNotificationHandlers();

      // Écouter les changements de token
      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _registerTokenToBackend(newToken);
      });

      _isInitialized = true;
      AppLogger.info(
        'Service de notifications push initialisé avec succès',
        tag: 'PUSH_NOTIFICATION',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'initialisation du service de notifications push: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialiser les notifications locales
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          try {
            final data = jsonDecode(response.payload!);
            onNotificationTapped?.call(data);
          } catch (e) {
            AppLogger.error(
              'Erreur lors du décodage du payload: $e',
              tag: 'PUSH_NOTIFICATION',
            );
          }
        }
      },
    );

    // Créer un canal de notification pour Android
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notifications importantes',
      description: 'Ce canal est utilisé pour les notifications importantes',
      importance: Importance.high,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  /// Obtenir le token FCM
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        AppLogger.info(
          'Token FCM obtenu: ${_fcmToken!.substring(0, 20)}...',
          tag: 'PUSH_NOTIFICATION',
        );
        // Enregistrer le token seulement si l'utilisateur est authentifié
        if (SessionService.isAuthenticated()) {
          await _registerTokenToBackend(_fcmToken!);
        }
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention du token FCM: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
  }

  /// Enregistrer le token auprès du backend
  Future<void> _registerTokenToBackend(String fcmToken) async {
    if (!SessionService.isAuthenticated()) {
      AppLogger.warning(
        'Utilisateur non authentifié, token non enregistré',
        tag: 'PUSH_NOTIFICATION',
      );
      return;
    }

    try {
      final deviceType = _getDeviceType();
      final deviceId = await _getDeviceId();
      final appVersion = await _getAppVersion();

      final authToken = SessionService.getToken();
      if (authToken == null) {
        AppLogger.warning(
          'Token d\'authentification manquant',
          tag: 'PUSH_NOTIFICATION',
        );
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/device-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'device_type': deviceType,
          'device_id': deviceId,
          'app_version': appVersion,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        AppLogger.info(
          'Token enregistré avec succès sur le backend',
          tag: 'PUSH_NOTIFICATION',
        );
      } else {
        AppLogger.warning(
          'Erreur lors de l\'enregistrement du token: ${response.statusCode}',
          tag: 'PUSH_NOTIFICATION',
        );
        AppLogger.debug('Réponse: ${response.body}', tag: 'PUSH_NOTIFICATION');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur lors de l\'enregistrement du token: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Configurer les handlers pour les notifications
  void _setupNotificationHandlers() {
    // Notification reçue quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification reçue au premier plan: ${message.messageId}',
        tag: 'PUSH_NOTIFICATION',
      );
      _showLocalNotification(message);

      // Appeler le callback si défini
      if (onNotificationReceived != null) {
        onNotificationReceived!(message.data);
      }
    });

    // Notification reçue quand l'app est en arrière-plan et que l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info(
        'Notification ouverte depuis l\'arrière-plan: ${message.messageId}',
        tag: 'PUSH_NOTIFICATION',
      );
      _handleNotificationTap(message.data);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        AppLogger.info(
          'App ouverte depuis une notification: ${message.messageId}',
          tag: 'PUSH_NOTIFICATION',
        );
        _handleNotificationTap(message.data);
      }
    });
  }

  /// Afficher une notification locale
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null) {
      await _localNotifications.show(
        message.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notifications importantes',
            channelDescription:
                'Ce canal est utilisé pour les notifications importantes',
            importance: Importance.high,
            priority: Priority.high,
            playSound: true,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  /// Gérer le clic sur une notification
  void _handleNotificationTap(Map<String, dynamic> data) {
    if (onNotificationTapped != null) {
      onNotificationTapped!(data);
    }
  }

  /// Obtenir le type d'appareil
  String _getDeviceType() {
    if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    }
    return 'web';
  }

  /// Obtenir l'ID unique de l'appareil
  Future<String> _getDeviceId() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'unknown';
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention de l\'ID de l\'appareil: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
    return 'unknown';
  }

  /// Obtenir la version de l'application
  Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      AppLogger.error(
        'Erreur lors de l\'obtention de la version: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
      return AppConfig.appVersion;
    }
  }

  /// Enregistrer le token après connexion
  Future<void> registerTokenAfterLogin() async {
    if (_fcmToken == null) {
      await _getFCMToken();
    }
    if (_fcmToken != null) {
      await _registerTokenToBackend(_fcmToken!);
    }
  }

  /// Supprimer le token du backend (lors de la déconnexion)
  Future<void> unregisterToken() async {
    if (_fcmToken == null) {
      return;
    }

    try {
      final token = SessionService.getToken();
      if (token == null) {
        return;
      }

      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/device-tokens'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        AppLogger.info(
          'Token supprimé avec succès du backend',
          tag: 'PUSH_NOTIFICATION',
        );
      }
    } catch (e) {
      AppLogger.error(
        'Erreur lors de la suppression du token: $e',
        tag: 'PUSH_NOTIFICATION',
        error: e,
      );
    }
  }

  /// Obtenir le token FCM actuel
  String? get fcmToken => _fcmToken;

  /// Nettoyer les ressources
  void dispose() {
    _tokenSubscription?.cancel();
  }
}
