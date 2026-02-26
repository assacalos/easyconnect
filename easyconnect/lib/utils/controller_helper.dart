import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Helper pour accéder aux contrôleurs GetX de façon sécurisée.
/// Évite les crashs en cas de route mal configurée et donne des messages clairs.
class ControllerHelper {
  ControllerHelper._();

  /// Retourne le contrôleur s'il est enregistré, sinon null.
  /// Utile pour afficher un message ou un fallback au lieu de crasher.
  static T? findOrNull<T>() {
    try {
      if (Get.isRegistered<T>()) {
        return Get.find<T>();
      }
    } catch (_) {}
    return null;
  }

  /// Retourne le contrôleur ou lance une exception explicite.
  /// À utiliser quand le contrôleur est requis (page liste/detail).
  static T require<T>() {
    if (!Get.isRegistered<T>()) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: StateError(
          'Contrôleur $T non enregistré. Vérifiez que la route utilise le bon binding.',
        ),
        library: 'controller_helper',
        context: ErrorDescription('Get.require<$T>()'),
      ));
      throw StateError(
        'Contrôleur $T non enregistré. Vérifiez que la route utilise le bon binding.',
      );
    }
    return Get.find<T>();
  }
}
