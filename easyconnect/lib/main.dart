import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:easyconnect/routes/app_routes.dart';
import 'package:easyconnect/bindings/auth_binding.dart';
import 'package:easyconnect/Views/Components/app_lifecycle_wrapper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/notification_navigation_service.dart';
import 'package:easyconnect/services/storage_service.dart';

/// Handler pour les notifications en arrière-plan (doit être top-level)
/// Gère les notifications au format FCM v1 avec type, entity_id, action_route
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Cette fonction est appelée quand une notification est reçue en arrière-plan
  // Elle doit être top-level et ne peut pas être une méthode de classe

  // Initialiser Firebase si nécessaire
  await Firebase.initializeApp();

  AppLogger.info(
    'Notification reçue en arrière-plan: ${message.messageId}',
    tag: 'PUSH_NOTIFICATION_BACKGROUND',
  );

  // Logger les données FCM v1 pour debug
  AppLogger.info(
    'Données FCM v1 (background): ${message.data}',
    tag: 'PUSH_NOTIFICATION_BACKGROUND',
  );

  // Afficher la notification locale même en arrière-plan
  final FlutterLocalNotificationsPlugin localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialiser les notifications locales si nécessaire
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  // Créer le canal de notification Android
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'Notifications importantes',
    description: 'Ce canal est utilisé pour les notifications importantes',
    importance: Importance.high,
    playSound: true,
  );

  await localNotifications
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Afficher la notification
  final notification = message.notification;
  if (notification != null) {
    await localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          channelDescription:
              'Ce canal est utilisé pour les notifications importantes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      // Inclure toutes les données FCM v1 dans le payload pour la navigation
      payload: jsonEncode(message.data),
    );

    AppLogger.info(
      'Notification locale affichée en arrière-plan avec données FCM v1',
      tag: 'PUSH_NOTIFICATION_BACKGROUND',
    );
  } else if (message.data.isNotEmpty) {
    // Si pas de notification mais des données, créer une notification à partir des données
    final title = message.data['title'] ?? 'Nouvelle notification';
    final body =
        message.data['body'] ??
        message.data['message'] ??
        'Vous avez une nouvelle notification';

    await localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'Notifications importantes',
          channelDescription:
              'Ce canal est utilisé pour les notifications importantes',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode(message.data),
    );

    AppLogger.info(
      'Notification locale créée à partir des données (background)',
      tag: 'PUSH_NOTIFICATION_BACKGROUND',
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('=== DÉMARRAGE DE L\'APPLICATION ===', tag: 'MAIN');

  // Initialiser les données de formatage des dates pour la locale française
  await initializeDateFormatting('fr_FR');

  // GetStorage : session (token, user), préférences. Hive : cache listes (clients, devis, etc.). Pas de conflit.
  await GetStorage.init();

  try {
    await HiveStorageService.init();
    AppLogger.info('HiveStorageService initialisé', tag: 'MAIN');
  } catch (e) {
    AppLogger.error('Erreur init Hive: $e', tag: 'MAIN');
  }

  // Initialiser le service de session (critique pour le premier écran / splash)
  try {
    await SessionService.initialize();
    AppLogger.info('SessionService initialisé avec succès', tag: 'MAIN');
  } catch (e) {
    AppLogger.error(
      'Erreur lors de l\'initialisation de SessionService: $e',
      tag: 'MAIN',
    );
  }

  // Lancer l'app sans attendre Firebase/push (premier écran plus rapide)
  runApp(const MyApp());

  // Initialisations non bloquantes (pas critiques pour le premier écran)
  Future(() async {
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialisé avec succès', tag: 'MAIN');
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final pushService = PushNotificationService();
      pushService.onNotificationTapped = (Map<String, dynamic> data) {
        NotificationNavigationService().handleNavigation(data);
      };
      pushService.onNotificationReceived = (Map<String, dynamic> data) {
        try {
          if (Get.isRegistered<NotificationController>()) {
            Get.find<NotificationController>().loadNotifications(forceRefresh: true);
          }
        } catch (e, stackTrace) {
          AppLogger.error(
            'Erreur lors de la mise à jour du controller: $e',
            tag: 'PUSH_NOTIFICATION',
            error: e,
            stackTrace: stackTrace,
          );
        }
      };

      await pushService.initialize();

      final initialMessage =
          await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        AppLogger.info(
          'App ouverte depuis une notification: ${initialMessage.messageId}',
          tag: 'PUSH_NOTIFICATION',
        );
        final notificationData = pushService.extractNotificationData(
          initialMessage.data,
        );
        Future.delayed(const Duration(milliseconds: 500), () {
          NotificationNavigationService().handleNavigation(notificationData);
        });
      }
      AppLogger.info(
        'Service de notifications push initialisé avec succès',
        tag: 'MAIN',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Erreur init Firebase/push: $e',
        tag: 'MAIN',
        error: e,
        stackTrace: stackTrace,
      );
    }

    NotificationServiceEnhanced().initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation des notifications: $e',
        tag: 'MAIN',
      );
    });
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'EasyConnect',
      debugShowCheckedModeBanner: false,
      // Optimisations de performance
      builder: (context, child) {
        return AppLifecycleWrapper(
          child: MediaQuery(
            // Désactiver l'accessibilité pour améliorer les performances
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(1.0)),
            child: child!,
          ),
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/splash',
      getPages: AppRoutes.routes,
      initialBinding:
          AuthBinding(), // Utilisation du binding d'authentification
      defaultTransition: Transition.fadeIn,
    );
  }
}
