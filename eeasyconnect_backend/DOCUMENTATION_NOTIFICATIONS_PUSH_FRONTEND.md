# Documentation : Intégration des Notifications Push - Frontend Flutter

## Vue d'ensemble

Ce document explique comment intégrer les notifications push dans votre application Flutter pour recevoir des notifications lorsque des entités sont soumises, validées, rejetées ou lors d'autres actions nécessitant une notification.

## Prérequis

1. **Firebase Cloud Messaging (FCM)** configuré dans votre projet Flutter
2. Package `firebase_messaging` installé
3. Configuration Firebase pour Android et iOS

## Installation des dépendances

Ajoutez les packages suivants dans votre `pubspec.yaml` :

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_messaging: ^14.7.9
  flutter_local_notifications: ^16.3.0
```

Puis exécutez :
```bash
flutter pub get
```

## Configuration

### 1. Configuration Android

#### `android/app/build.gradle`
Assurez-vous que la version minimale de SDK est au moins 21 :
```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

#### `AndroidManifest.xml`
Ajoutez les permissions nécessaires dans `android/app/src/main/AndroidManifest.xml` :
```xml
<manifest>
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    
    <application>
        <!-- ... autres configurations ... -->
        
        <!-- Service pour les notifications en arrière-plan -->
        <service
            android:name="com.google.firebase.messaging.FirebaseMessagingService"
            android:exported="false">
            <intent-filter>
                <action android:name="com.google.firebase.MESSAGING_EVENT" />
            </intent-filter>
        </service>
    </application>
</manifest>
```

### 2. Configuration iOS

#### `ios/Podfile`
Assurez-vous que la version iOS minimale est au moins 12.0 :
```ruby
platform :ios, '12.0'
```

#### `Info.plist`
Ajoutez les permissions dans `ios/Runner/Info.plist` :
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

## Implémentation

### 1. Service de gestion des notifications push

Créez un fichier `lib/services/push_notification_service.dart` :

```dart
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart'; // Votre configuration API

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  StreamSubscription<String>? _tokenSubscription;

  // Callback pour gérer les notifications reçues
  Function(Map<String, dynamic>)? onNotificationReceived;
  
  // Callback pour gérer les clics sur les notifications
  Function(Map<String, dynamic>)? onNotificationTapped;

  /// Initialiser le service de notifications push
  Future<void> initialize() async {
    // Demander la permission pour les notifications
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('L\'utilisateur a accordé la permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      print('L\'utilisateur a accordé une permission provisoire');
    } else {
      print('L\'utilisateur a refusé ou n\'a pas encore accordé la permission');
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
          final data = jsonDecode(response.payload!);
          onNotificationTapped?.call(data);
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
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Obtenir le token FCM
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      if (_fcmToken != null) {
        print('Token FCM obtenu: ${_fcmToken.substring(0, 20)}...');
        await _registerTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      print('Erreur lors de l\'obtention du token FCM: $e');
    }
  }

  /// Enregistrer le token auprès du backend
  Future<void> _registerTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/device-tokens'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await ApiConfig.getToken()}', // Votre méthode pour obtenir le token d'authentification
        },
        body: jsonEncode({
          'token': token,
          'device_type': _getDeviceType(),
          'device_id': await _getDeviceId(),
          'app_version': await _getAppVersion(),
        }),
      );

      if (response.statusCode == 201) {
        print('Token enregistré avec succès sur le backend');
      } else {
        print('Erreur lors de l\'enregistrement du token: ${response.statusCode}');
        print('Réponse: ${response.body}');
      }
    } catch (e) {
      print('Erreur lors de l\'enregistrement du token: $e');
    }
  }

  /// Configurer les handlers pour les notifications
  void _setupNotificationHandlers() {
    // Notification reçue quand l'app est au premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Notification reçue au premier plan: ${message.messageId}');
      _showLocalNotification(message);
      
      // Appeler le callback si défini
      if (onNotificationReceived != null) {
        onNotificationReceived!(message.data);
      }
    });

    // Notification reçue quand l'app est en arrière-plan et que l'utilisateur clique dessus
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification ouverte depuis l\'arrière-plan: ${message.messageId}');
      _handleNotificationTap(message.data);
    });

    // Vérifier si l'app a été ouverte depuis une notification
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App ouverte depuis une notification: ${message.messageId}');
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
            channelDescription: 'Ce canal est utilisé pour les notifications importantes',
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
    // Utilisez le package device_info_plus pour obtenir l'ID unique
    // Exemple avec device_info_plus:
    // final deviceInfo = DeviceInfoPlugin();
    // if (Platform.isAndroid) {
    //   final androidInfo = await deviceInfo.androidInfo;
    //   return androidInfo.id;
    // } else if (Platform.isIOS) {
    //   final iosInfo = await deviceInfo.iosInfo;
    //   return iosInfo.identifierForVendor ?? '';
    // }
    return 'unknown';
  }

  /// Obtenir la version de l'application
  Future<String> _getAppVersion() async {
    // Utilisez le package package_info_plus pour obtenir la version
    // Exemple:
    // final packageInfo = await PackageInfo.fromPlatform();
    // return packageInfo.version;
    return '1.0.0';
  }

  /// Supprimer le token du backend (lors de la déconnexion)
  Future<void> unregisterToken() async {
    if (_fcmToken != null) {
      try {
        final response = await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/api/device-tokens'),
          headers: {
            'Authorization': 'Bearer ${await ApiConfig.getToken()}',
          },
        );

        if (response.statusCode == 200) {
          print('Token supprimé avec succès du backend');
        }
      } catch (e) {
        print('Erreur lors de la suppression du token: $e');
      }
    }
  }

  /// Nettoyer les ressources
  void dispose() {
    _tokenSubscription?.cancel();
  }
}
```

### 2. Initialisation dans votre application

Dans votre `main.dart` ou dans votre widget d'authentification :

```dart
import 'package:flutter/material.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  // Initialiser le service de notifications push
  final pushService = PushNotificationService();
  await pushService.initialize();
  
  // Configurer les callbacks
  pushService.onNotificationReceived = (data) {
    // Mettre à jour l'état de l'application si nécessaire
    print('Notification reçue: $data');
  };
  
  pushService.onNotificationTapped = (data) {
    // Naviguer vers la page appropriée selon le type d'entité
    _handleNotificationNavigation(data);
  };
  
  runApp(MyApp());
}

void _handleNotificationNavigation(Map<String, dynamic> data) {
  final entityType = data['entity_type'];
  final entityId = data['entity_id'];
  final actionRoute = data['action_route'];
  
  // Utilisez votre système de navigation pour aller à la page appropriée
  // Exemple avec go_router ou Navigator:
  // if (actionRoute != null) {
  //   navigatorKey.currentState?.pushNamed(actionRoute);
  // }
}
```

### 3. Enregistrer le token après connexion

Dans votre service d'authentification, après une connexion réussie :

```dart
Future<void> login(String email, String password) async {
  // ... votre logique de connexion ...
  
  // Une fois connecté, s'assurer que le token est enregistré
  final pushService = PushNotificationService();
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) {
    await pushService._registerTokenToBackend(token);
  }
}
```

### 4. Supprimer le token lors de la déconnexion

Dans votre service d'authentification, lors de la déconnexion :

```dart
Future<void> logout() async {
  // Supprimer le token du backend
  final pushService = PushNotificationService();
  await pushService.unregisterToken();
  
  // ... votre logique de déconnexion ...
}
```

## Structure des données de notification

Lorsqu'une notification est reçue, elle contient les données suivantes :

```dart
{
  'title': 'Soumission Dépense',
  'body': 'Dépense #123 a été soumise pour validation',
  'entity_type': 'expense',
  'entity_id': 123,
  'action_route': '/expenses/123',
  'type': 'info', // info, success, warning, error
  'priorite': 'normale', // basse, normale, haute, urgente
}
```

## Gestion de la navigation

Exemple de gestion de la navigation basée sur le type d'entité :

```dart
void handleNotificationTap(Map<String, dynamic> data) {
  final entityType = data['entity_type'];
  final entityId = data['entity_id'];
  final actionRoute = data['action_route'];
  
  switch (entityType) {
    case 'expense':
      Navigator.pushNamed(context, '/expenses/$entityId');
      break;
    case 'leave_request':
      Navigator.pushNamed(context, '/leave-requests/$entityId');
      break;
    case 'reporting':
      Navigator.pushNamed(context, '/reportings/$entityId');
      break;
    default:
      if (actionRoute != null) {
        Navigator.pushNamed(context, actionRoute);
      }
  }
}
```

## Endpoints API disponibles

### Enregistrer un token d'appareil
```
POST /api/device-tokens
Headers: Authorization: Bearer {token}
Body: {
  "token": "fcm_token_here",
  "device_type": "android|ios|web",
  "device_id": "unique_device_id",
  "app_version": "1.0.0"
}
```

### Lister les tokens de l'utilisateur
```
GET /api/device-tokens
Headers: Authorization: Bearer {token}
```

### Supprimer un token spécifique
```
DELETE /api/device-tokens/{id}
Headers: Authorization: Bearer {token}
```

### Supprimer tous les tokens de l'utilisateur
```
DELETE /api/device-tokens
Headers: Authorization: Bearer {token}
```

## Configuration backend

Assurez-vous d'ajouter la clé serveur FCM dans votre fichier `.env` :

```env
FCM_SERVER_KEY=votre_cle_serveur_fcm_ici
```

Vous pouvez obtenir cette clé depuis la console Firebase :
1. Allez dans Firebase Console
2. Sélectionnez votre projet
3. Paramètres du projet > Cloud Messaging
4. Copiez la "Clé serveur"

## Test

Pour tester les notifications push :

1. **Test depuis le backend** : Utilisez l'endpoint de création de notification pour envoyer une notification de test
2. **Test depuis Firebase Console** : Utilisez l'outil de test de notifications dans Firebase Console
3. **Vérifier les logs** : Surveillez les logs de l'application pour voir si les tokens sont bien enregistrés

## Dépannage

### Le token n'est pas enregistré
- Vérifiez que l'utilisateur est bien authentifié
- Vérifiez les logs du backend pour voir les erreurs
- Assurez-vous que la clé FCM_SERVER_KEY est bien configurée

### Les notifications ne sont pas reçues
- Vérifiez que les permissions sont accordées
- Vérifiez que le token est bien enregistré dans la base de données
- Vérifiez les logs Firebase pour voir si les notifications sont envoyées
- Testez avec Firebase Console pour isoler le problème

### Les notifications ne sonnent pas
- Vérifiez les paramètres de notification de l'appareil
- Vérifiez que le canal de notification Android est bien configuré
- Vérifiez que les permissions de son sont accordées

## Notes importantes

1. **Token unique par appareil** : Chaque appareil a un token unique qui doit être enregistré
2. **Mise à jour du token** : Le token peut changer, le service écoute automatiquement les changements
3. **Multi-appareils** : Un utilisateur peut avoir plusieurs tokens (un par appareil)
4. **Sécurité** : Ne partagez jamais votre clé serveur FCM publiquement

## Support

Pour toute question ou problème, consultez :
- La documentation Firebase Cloud Messaging
- Les logs de l'application et du backend
- La documentation de l'API backend

