import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:easyconnect/Controllers/auth_controller.dart';

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

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // L'application passe en arrière-plan
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      // L'application revient au premier plan
      _wasInBackground = false;
      _handleAppResumed();
    }
  }

  /// Gère le retour de l'application au premier plan
  void _handleAppResumed() {
    // Vérifier que l'utilisateur est toujours connecté
    if (Get.isRegistered<AuthController>()) {
      final authController = Get.find<AuthController>();

      // Vérifier si l'utilisateur a toujours un token valide
      final token = authController.storage.read('token');
      final user = authController.userAuth.value;

      if (token == null || user == null) {
        // L'utilisateur n'a plus de session valide, déconnecter
        authController.logout();
        return;
      }

      // L'utilisateur est toujours connecté, on peut continuer
      // Les contrôleurs individuels géreront le rechargement de leurs données
      // si nécessaire via leurs méthodes onInit ou onReady
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
