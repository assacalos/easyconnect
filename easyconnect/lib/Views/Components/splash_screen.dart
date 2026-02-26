import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/models/user_model.dart';
import 'package:easyconnect/routes/app_routes.dart';
import 'package:easyconnect/services/api_service.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/push_notification_service.dart';
import 'package:easyconnect/services/websocket_service.dart';
import 'package:easyconnect/utils/logger.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;

    try {
      final loggedIn = await SessionService.isLoggedIn();
      AppLogger.info(
        'Splash: SessionService.isLoggedIn = $loggedIn',
        tag: 'SPLASH',
      );

      final authController = Get.find<AuthController>();
      var userRole = authController.userAuth.value?.role ?? SessionService.getUserRole();

      // Redirection instantanée si token + rôle en cache (connexion permanente)
      if (loggedIn && userRole != null) {
        final initialRoute = AppRoutes.getInitialRoute(userRole);
        Get.offAllNamed(initialRoute);
        _runBackgroundInit(authController);
        return;
      }

      // Pas de token → écran d'accueil
      if (!loggedIn) {
        Get.offAllNamed('/welcome');
        return;
      }

      // Token présent mais pas de rôle en cache : tenter de récupérer l'utilisateur (sans déconnecter en cas d'échec)
      try {
        final result = await ApiService.getUser().timeout(
          const Duration(seconds: 5),
          onTimeout: () => <String, dynamic>{'success': false},
        );
        if (result['success'] == true && result['data'] != null) {
          final userData = Map<String, dynamic>.from(result['data'] as Map);
          await SessionService.saveUser(userData);
          authController.userAuth.value = UserModel.fromJson(userData);
          userRole = authController.userAuth.value?.role ?? SessionService.getUserRole();
        }
      } catch (_) {}
      // Ne jamais faire clearSession() ici : timeout ou erreur réseau → accès avec données de cache
      userRole ??= SessionService.getUserRole();

      if (userRole != null) {
        Get.offAllNamed(AppRoutes.getInitialRoute(userRole));
        _runBackgroundInit(authController);
      } else {
        Get.offAllNamed('/welcome');
      }
    } catch (e) {
      AppLogger.warning('Splash: erreur redirection: $e', tag: 'SPLASH');
      Get.offAllNamed('/welcome');
    }
  }

  /// Tâches post-redirection : FCM, WebSocket (non bloquant). Pas de déconnexion ici : un 401 sera géré par l'Interceptor global.
  void _runBackgroundInit(AuthController authController) {
    Future(() async {
      try {
        final result = await ApiService.getUser().timeout(
          const Duration(seconds: 2),
          onTimeout: () => <String, dynamic>{'timeout': true},
        );
        if (result['timeout'] == true) return;
        if (result['success'] == true && result['data'] != null) {
          await SessionService.saveUser(Map<String, dynamic>.from(result['data'] as Map));
          authController.userAuth.value = UserModel.fromJson(result['data'] as Map<String, dynamic>);
        }
        // En cas de 401 : ne pas faire clearSession ici ; l'Interceptor global déconnectera au prochain appel API
      } catch (_) {}

      try {
        final pushService = PushNotificationService();
        await pushService.initialize();
        await pushService.registerTokenAfterLogin();
      } catch (_) {}

      try {
        await WebSocketService.instance.initialize();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Flutter ou de l'application
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.business,
                size: 60,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'EasyConnect',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Gestion d\'entreprise',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 50),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
