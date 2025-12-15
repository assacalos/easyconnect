import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/routes/app_routes.dart';
import 'package:easyconnect/bindings/auth_binding.dart';
import 'package:easyconnect/Views/Components/app_lifecycle_wrapper.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:easyconnect/utils/logger.dart';
import 'package:easyconnect/services/notification_service_enhanced.dart';
import 'package:easyconnect/services/push_notification_service.dart';

/// Handler pour les notifications en arrière-plan (doit être top-level)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Cette fonction est appelée quand une notification est reçue en arrière-plan
  // Elle doit être top-level et ne peut pas être une méthode de classe
  AppLogger.info(
    'Notification reçue en arrière-plan: ${message.messageId}',
    tag: 'PUSH_NOTIFICATION_BACKGROUND',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('=== DÉMARRAGE DE L\'APPLICATION ===', tag: 'MAIN');
  // Assurer l'initialisation du stockage avant de lancer l'app
  await GetStorage.init();

  // Initialiser Firebase
  try {
    await Firebase.initializeApp();
    AppLogger.info('Firebase initialisé avec succès', tag: 'MAIN');

    // Configurer le handler pour les notifications en arrière-plan
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Initialiser le service de notifications push (non-bloquant)
    PushNotificationService().initialize().catchError((e) {
      AppLogger.error(
        'Erreur lors de l\'initialisation des notifications push: $e',
        tag: 'MAIN',
      );
    });
  } catch (e, stackTrace) {
    AppLogger.error(
      'Erreur lors de l\'initialisation de Firebase: $e',
      tag: 'MAIN',
      error: e,
      stackTrace: stackTrace,
    );
  }

  // Initialiser le service de notifications locales (non-bloquant)
  NotificationServiceEnhanced().initialize().catchError((e) {
    AppLogger.error(
      'Erreur lors de l\'initialisation des notifications: $e',
      tag: 'MAIN',
    );
  });

  runApp(const MyApp());
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
