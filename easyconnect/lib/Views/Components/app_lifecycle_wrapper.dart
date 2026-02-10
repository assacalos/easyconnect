import 'package:flutter/material.dart';
import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';
import 'package:easyconnect/Controllers/notification_controller.dart';
import 'package:easyconnect/services/session_service.dart';
import 'package:easyconnect/services/push_notification_service.dart';

/// Widget qui écoute le cycle de vie de l'application
/// et gère le rafraîchissement des données au retour au premier plan
class AppLifecycleWrapper extends StatefulWidget {
  final Widget child;

  const AppLifecycleWrapper({super.key, required this.child});

  @override
  State<AppLifecycleWrapper> createState() => _AppLifecycleWrapperState();
}

class _AppLifecycleWrapperState extends State<AppLifecycleWrapper>
    with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Mettre à jour l'état dans SessionService pour le suivi d'activité
    SessionService.updateAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'application passe en arrière-plan : mettre à jour le badge sur l'icône
      _wasInBackground = true;
      if (Get.isRegistered<NotificationController>()) {
        try {
          Get.find<NotificationController>().refreshUnreadCount();
        } catch (_) {}
      }
    } else if (state == AppLifecycleState.resumed) {
      // Dès qu'on rentre dans l'app : retirer le badge (nombre) sur l'icône
      try {
        FlutterAppBadger.removeBadge();
      } catch (_) {}
      // Effacer les notifications passées de la barre
      PushNotificationService().cancelAllNotifications();
      if (_wasInBackground) {
        _wasInBackground = false;
        _handleAppResumed();
      }
    }
  }

  /// Gère le retour de l'application au premier plan
  void _handleAppResumed() async {
    // Mettre à jour l'activité utilisateur
    SessionService.updateLastActivity();

    // Vérifier que l'utilisateur est toujours connecté
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();

      // Vérifier si l'utilisateur a toujours un token valide
      final token = await SessionService.getToken();
      final user = authController.userAuth.value;

      if (token == null || user == null) {
        // L'utilisateur n'a plus de session valide, déconnecter silencieusement
        authController.logout(silent: true);
        return;
      }

      // ⚠️ VALIDATION D'EXPIRATION SUPPRIMÉE : Les tokens n'expirent jamais côté frontend
      // Si le backend invalide un token, il retournera une erreur 401 gérée par AuthErrorHandler

      // OPTIMISATION : Vérifier si les données utilisateur sont toujours valides
      // (rôle changé, compte désactivé, etc.)
      try {
        await authController.refreshUserData();
      } catch (e) {
        // Si erreur 401, AuthErrorHandler déconnectera automatiquement
        // Sinon, ignorer l'erreur (problème réseau temporaire)
      }

      // Rafraîchir le compteur de notifications non lues pour mettre à jour
      // le badge sur l'icône de l'app (menu du téléphone)
      if (Get.isRegistered<NotificationController>()) {
        try {
          await Get.find<NotificationController>().refreshUnreadCount();
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
